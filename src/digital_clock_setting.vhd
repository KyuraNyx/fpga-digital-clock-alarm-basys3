----------------------------------------------------------------------------------
-- Project: Digital Clock & Musical Alarm on FPGA Digilent Basys 3
-- Module: digital_clock_setting
-- Target Device: Xilinx Artix-7 (xc7a35tcpg236-1)
-- Tool: Vivado Design Suite
-- Description:
--   - 24-hour real-time digital clock with hours, minutes, and binary seconds
--   - User-configurable alarm with visual LED indicator and audio melody
--   - 4-Digit multiplexed 7-segment display with digit blinking in setting mode
--   - Piezo buzzer PWM tone generator playing "Twinkle Twinkle Little Star" melody
--   - Software debounced / edge-detected push button navigation
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity digital_clock_setting is
    Port (
        clock_100Mhz   : in  std_logic;                      -- 100 MHz onboard oscillator (W5)
        reset          : in  std_logic;                      -- Global synchronous reset switch (R2)
        btnC           : in  std_logic;                      -- Center Button (U18): Toggle HH / MM field
        btnL           : in  std_logic;                      -- Left Button (W19): Select tens digit
        btnR           : in  std_logic;                      -- Right Button (T17): Select units digit
        btnU           : in  std_logic;                      -- Up Button (T18): Increment value
        btnD           : in  std_logic;                      -- Down Button (U17): Decrement value
        sw_clock       : in  std_logic;                      -- Switch V16: Clock Setting Mode
        sw_alarm       : in  std_logic;                      -- Switch V17: Alarm Setting Mode
        Anode_Activate : out std_logic_vector(3 downto 0);   -- 7-Segment common anodes (active low)
        LED_out        : out std_logic_vector(6 downto 0);   -- 7-Segment cathodes A-G (active low)
        led_sec        : out std_logic_vector(5 downto 0);   -- Binary seconds indicator (LD0..LD5)
        led_alarm_on   : out std_logic;                      -- Alarm active indicator LED (LD15 / L1)
        buzzer         : out std_logic                       -- Passive buzzer output to Pmod JA4 (active low)
    );
end digital_clock_setting;

architecture Behavioral of digital_clock_setting is

    -- =================================================================
    -- Clock Division & Multiplexing Signals
    -- =================================================================
    signal refresh_counter        : unsigned(19 downto 0) := (others => '0');
    signal LED_activating_counter : std_logic_vector(1 downto 0);
    signal LED_BCD                : std_logic_vector(3 downto 0);
    signal one_second_counter     : unsigned(27 downto 0) := (others => '0');
    signal one_second_enable      : std_logic := '0';

    -- =================================================================
    -- Time & Alarm Registers
    -- =================================================================
    signal seconds       : integer range 0 to 59 := 0;
    signal minutes       : integer range 0 to 59 := 0;
    signal hours         : integer range 0 to 23 := 0;
    signal alarm_minutes : integer range 0 to 59 := 0;
    signal alarm_hours   : integer range 0 to 23 := 0;

    -- =================================================================
    -- Edge Detection for Push Buttons
    -- =================================================================
    signal btnC_prev, btnL_prev, btnR_prev, btnU_prev, btnD_prev : std_logic := '1';
    signal btnC_edge, btnL_edge, btnR_edge, btnU_edge, btnD_edge : std_logic := '0';

    -- =================================================================
    -- Interactive Setting Mode & Blink Generator
    -- =================================================================
    signal blink_counter  : unsigned(25 downto 0) := (others => '0');
    signal blink_enable   : std_logic := '0';
    signal selected_field : std_logic := '0';  -- 0 = Hours (HH), 1 = Minutes (MM)
    signal selected_digit : std_logic := '0';  -- 0 = Tens digit, 1 = Units digit

    -- =================================================================
    -- Buzzer Melody Synthesizer ("Twinkle Twinkle Little Star")
    -- =================================================================
    constant CLK_FREQ      : integer := 100_000_000;
    constant NOTE_DURATION : integer := CLK_FREQ / 2; -- 0.5 seconds per musical note
    type note_array is array (0 to 31) of integer;
    constant notes : note_array := (
        262, 262, 392, 392, 440, 440, 392, 0,  -- Twinkle, twinkle, little star
        349, 349, 330, 330, 294, 294, 262, 0,  -- How I wonder what you are
        392, 392, 349, 349, 330, 330, 294, 0,  -- Up above the world so high
        392, 392, 349, 349, 330, 330, 294, 0   -- Like a diamond in the sky
    );

    signal note_index    : integer range 0 to 31 := 0;
    signal note_counter  : unsigned(31 downto 0) := (others => '0');
    signal tone_counter  : unsigned(31 downto 0) := (others => '0');
    signal tone_out      : std_logic := '0';
    signal tone_limit    : integer := 0;
    signal alarm_playing : std_logic := '0';

begin

    --------------------------------------------------------------------
    -- Display Refresh Counter (~1 kHz display multiplexing rate)
    --------------------------------------------------------------------
    process(clock_100Mhz, reset)
    begin
        if reset = '1' then
            refresh_counter <= (others => '0');
        elsif rising_edge(clock_100Mhz) then
            refresh_counter <= refresh_counter + 1;
        end if;
    end process;

    LED_activating_counter <= std_logic_vector(refresh_counter(19 downto 18));

    --------------------------------------------------------------------
    -- 1-Second Timebase Generator (100,000,000 cycles @ 100 MHz)
    --------------------------------------------------------------------
    process(clock_100Mhz, reset)
    begin
        if reset = '1' then
            one_second_counter <= (others => '0');
            one_second_enable  <= '0';
        elsif rising_edge(clock_100Mhz) then
            if one_second_counter = x"5F5E0FF" then  -- 99,999,999 in hex
                one_second_counter <= (others => '0');
                one_second_enable  <= '1';
            else
                one_second_counter <= one_second_counter + 1;
                one_second_enable  <= '0';
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Push Button Synchronizer and Edge Detector
    --------------------------------------------------------------------
    process(clock_100Mhz)
    begin
        if rising_edge(clock_100Mhz) then
            if (btnC = '0' and btnC_prev = '1') then
                btnC_edge <= '1';
            else
                btnC_edge <= '0';
            end if;

            if (btnL = '0' and btnL_prev = '1') then
                btnL_edge <= '1';
            else
                btnL_edge <= '0';
            end if;

            if (btnR = '0' and btnR_prev = '1') then
                btnR_edge <= '1';
            else
                btnR_edge <= '0';
            end if;

            if (btnU = '0' and btnU_prev = '1') then
                btnU_edge <= '1';
            else
                btnU_edge <= '0';
            end if;

            if (btnD = '0' and btnD_prev = '1') then
                btnD_edge <= '1';
            else
                btnD_edge <= '0';
            end if;

            btnC_prev <= btnC;
            btnL_prev <= btnL;
            btnR_prev <= btnR;
            btnU_prev <= btnU;
            btnD_prev <= btnD;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Blink Generator for Setting Modes (~2 Hz)
    --------------------------------------------------------------------
    process(clock_100Mhz)
    begin
        if rising_edge(clock_100Mhz) then
            if blink_counter = x"2FAF07F" then -- 49,999,999 cycles = 0.5s toggle
                blink_counter <= (others => '0');
                blink_enable  <= not blink_enable;
            else
                blink_counter <= blink_counter + 1;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Timekeeper & Setting FSM Logic
    --------------------------------------------------------------------
    process(clock_100Mhz, reset)
    begin
        if reset = '1' then
            hours          <= 0;
            minutes        <= 0;
            seconds        <= 0;
            alarm_hours    <= 0;
            alarm_minutes  <= 0;
            selected_field <= '0';
            selected_digit <= '0';

        elsif rising_edge(clock_100Mhz) then

            -- 1. NORMAL CLOCK RUNNING MODE (sw_clock = '0' and sw_alarm = '0')
            if (sw_clock = '0' and sw_alarm = '0') then
                if one_second_enable = '1' then
                    if seconds = 59 then
                        seconds <= 0;
                        if minutes = 59 then
                            minutes <= 0;
                            if hours = 23 then
                                hours <= 0;
                            else
                                hours <= hours + 1;
                            end if;
                        else
                            minutes <= minutes + 1;
                        end if;
                    else
                        seconds <= seconds + 1;
                    end if;
                end if;

            -- 2. CLOCK SETTING MODE (sw_clock = '1' and sw_alarm = '0')
            elsif (sw_clock = '1' and sw_alarm = '0') then
                if btnL_edge = '1' then
                    selected_digit <= '0'; -- Select Tens digit
                elsif btnR_edge = '1' then
                    selected_digit <= '1'; -- Select Units digit
                end if;

                if btnC_edge = '1' then
                    selected_field <= not selected_field; -- Toggle Hours <-> Minutes
                end if;

                if btnU_edge = '1' then
                    if selected_field = '0' then
                        if selected_digit = '0' then
                            hours <= (hours + 10) mod 24;
                        else
                            hours <= (hours + 1) mod 24;
                        end if;
                    else
                        if selected_digit = '0' then
                            minutes <= (minutes + 10) mod 60;
                        else
                            minutes <= (minutes + 1) mod 60;
                        end if;
                    end if;
                elsif btnD_edge = '1' then
                    if selected_field = '0' then
                        if selected_digit = '0' then
                            hours <= (hours + 14) mod 24; -- Equivalent to -10 mod 24
                        else
                            hours <= (hours + 23) mod 24; -- Equivalent to -1 mod 24
                        end if;
                    else
                        if selected_digit = '0' then
                            minutes <= (minutes + 50) mod 60; -- Equivalent to -10 mod 60
                        else
                            minutes <= (minutes + 59) mod 60; -- Equivalent to -1 mod 60
                        end if;
                    end if;
                end if;

            -- 3. ALARM SETTING MODE (sw_alarm = '1')
            elsif (sw_alarm = '1') then
                if btnL_edge = '1' then
                    selected_digit <= '0';
                elsif btnR_edge = '1' then
                    selected_digit <= '1';
                end if;

                if btnC_edge = '1' then
                    selected_field <= not selected_field;
                end if;

                if btnU_edge = '1' then
                    if selected_field = '0' then
                        if selected_digit = '0' then
                            alarm_hours <= (alarm_hours + 10) mod 24;
                        else
                            alarm_hours <= (alarm_hours + 1) mod 24;
                        end if;
                    else
                        if selected_digit = '0' then
                            alarm_minutes <= (alarm_minutes + 10) mod 60;
                        else
                            alarm_minutes <= (alarm_minutes + 1) mod 60;
                        end if;
                    end if;
                elsif btnD_edge = '1' then
                    if selected_field = '0' then
                        if selected_digit = '0' then
                            alarm_hours <= (alarm_hours + 14) mod 24;
                        else
                            alarm_hours <= (alarm_hours + 23) mod 24;
                        end if;
                    else
                        if selected_digit = '0' then
                            alarm_minutes <= (alarm_minutes + 50) mod 60;
                        else
                            alarm_minutes <= (alarm_minutes + 59) mod 60;
                        end if;
                    end if;
                end if;
            end if;

        end if;
    end process;

    --------------------------------------------------------------------
    -- 4-Digit Seven Segment Display Multiplexer
    --------------------------------------------------------------------
    process(LED_activating_counter, sw_clock, sw_alarm, selected_field, selected_digit,
            blink_enable, hours, minutes, alarm_hours, alarm_minutes)
    begin
        case LED_activating_counter is
            when "00" =>  -- Digit 1: Hours Tens
                Anode_Activate <= "0111";
                if ( (sw_clock = '1' and selected_field = '0' and selected_digit = '0' and blink_enable = '1') or
                     (sw_alarm = '1' and selected_field = '0' and selected_digit = '0' and blink_enable = '1') ) then
                    LED_BCD <= "1111";  -- Blank during blink pulse
                elsif sw_alarm = '1' then
                    LED_BCD <= std_logic_vector(to_unsigned(alarm_hours / 10, 4));
                else
                    LED_BCD <= std_logic_vector(to_unsigned(hours / 10, 4));
                end if;

            when "01" =>  -- Digit 2: Hours Units
                Anode_Activate <= "1011";
                if ( (sw_clock = '1' and selected_field = '0' and selected_digit = '1' and blink_enable = '1') or
                     (sw_alarm = '1' and selected_field = '0' and selected_digit = '1' and blink_enable = '1') ) then
                    LED_BCD <= "1111";
                elsif sw_alarm = '1' then
                    LED_BCD <= std_logic_vector(to_unsigned(alarm_hours mod 10, 4));
                else
                    LED_BCD <= std_logic_vector(to_unsigned(hours mod 10, 4));
                end if;

            when "10" =>  -- Digit 3: Minutes Tens
                Anode_Activate <= "1101";
                if ( (sw_clock = '1' and selected_field = '1' and selected_digit = '0' and blink_enable = '1') or
                     (sw_alarm = '1' and selected_field = '1' and selected_digit = '0' and blink_enable = '1') ) then
                    LED_BCD <= "1111";
                elsif sw_alarm = '1' then
                    LED_BCD <= std_logic_vector(to_unsigned(alarm_minutes / 10, 4));
                else
                    LED_BCD <= std_logic_vector(to_unsigned(minutes / 10, 4));
                end if;

            when "11" =>  -- Digit 4: Minutes Units
                Anode_Activate <= "1110";
                if ( (sw_clock = '1' and selected_field = '1' and selected_digit = '1' and blink_enable = '1') or
                     (sw_alarm = '1' and selected_field = '1' and selected_digit = '1' and blink_enable = '1') ) then
                    LED_BCD <= "1111";
                elsif sw_alarm = '1' then
                    LED_BCD <= std_logic_vector(to_unsigned(alarm_minutes mod 10, 4));
                else
                    LED_BCD <= std_logic_vector(to_unsigned(minutes mod 10, 4));
                end if;

            when others =>
                Anode_Activate <= "1111";
                LED_BCD        <= "1111";
        end case;
    end process;

    --------------------------------------------------------------------
    -- BCD to 7-Segment Cathode Decoder (Active Low: A,B,C,D,E,F,G)
    --------------------------------------------------------------------
    process(LED_BCD)
    begin
        case LED_BCD is
            when "0000" => LED_out <= "1000000"; -- '0'
            when "0001" => LED_out <= "1111001"; -- '1'
            when "0010" => LED_out <= "0100100"; -- '2'
            when "0011" => LED_out <= "0110000"; -- '3'
            when "0100" => LED_out <= "0011001"; -- '4'
            when "0101" => LED_out <= "0010010"; -- '5'
            when "0110" => LED_out <= "0000010"; -- '6'
            when "0111" => LED_out <= "1111000"; -- '7'
            when "1000" => LED_out <= "0000000"; -- '8'
            when "1001" => LED_out <= "0010000"; -- '9'
            when others => LED_out <= "1111111"; -- Blank
        end case;
    end process;

    --------------------------------------------------------------------
    -- Seconds LED Output, Alarm Trigger, and Melody Tone Synthesizer
    --------------------------------------------------------------------
    process(clock_100Mhz, reset)
    begin
        if reset = '1' then
            led_sec       <= (others => '0');
            led_alarm_on  <= '0';
            alarm_playing <= '0';
            note_index    <= 0;
            note_counter  <= (others => '0');
            tone_counter  <= (others => '0');
            tone_out      <= '0';
            buzzer        <= '1'; -- Inactive HIGH (Low-Trigger Buzzer)

        elsif rising_edge(clock_100Mhz) then

            -- 6-bit binary seconds on LEDs (LD0..LD5)
            led_sec <= std_logic_vector(to_unsigned(seconds, 6));

            -- Trigger Alarm Event when real-time matches target alarm time at 00 seconds
            if (hours = alarm_hours and minutes = alarm_minutes and seconds = 0) then
                alarm_playing <= '1';
            end if;

            -- Musical Melody Synthesizer playback
            if alarm_playing = '1' then
                led_alarm_on <= '1';

                -- Note duration timer (0.5s per note)
                if to_integer(note_counter) >= NOTE_DURATION then
                    note_counter <= (others => '0');

                    if note_index < 31 then
                        note_index <= note_index + 1;
                    else
                        alarm_playing <= '0'; -- Stop after melody completes
                    end if;

                    -- Compute frequency divider half-period for tone generator
                    if notes(note_index) > 0 then
                        tone_limit <= CLK_FREQ / (2 * notes(note_index));
                    else
                        tone_limit <= 0; -- Musical pause
                    end if;

                else
                    note_counter <= note_counter + 1;
                end if;

                -- Square-wave audio frequency generator
                if tone_limit > 0 then
                    if to_integer(tone_counter) >= tone_limit then
                        tone_counter <= (others => '0');
                        tone_out     <= not tone_out;
                    else
                        tone_counter <= tone_counter + 1;
                    end if;
                    buzzer <= not tone_out;
                else
                    buzzer   <= '1'; -- Silent pause
                    tone_out <= '0';
                end if;

            else
                -- Idle / Inactive State
                buzzer        <= '1'; -- Silent
                led_alarm_on  <= '0';
                tone_out      <= '0';
                note_index    <= 0;
                note_counter  <= (others => '0');
                tone_counter  <= (others => '0');
            end if;

        end if;
    end process;

end Behavioral;
