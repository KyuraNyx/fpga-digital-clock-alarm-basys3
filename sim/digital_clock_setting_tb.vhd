----------------------------------------------------------------------------------
-- Testbench: digital_clock_setting_tb
-- Target: Verification of digital_clock_setting in Vivado / GHDL / ModelSim
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity digital_clock_setting_tb is
end digital_clock_setting_tb;

architecture Behavioral of digital_clock_setting_tb is

    -- Component Declaration
    component digital_clock_setting
        Port (
            clock_100Mhz   : in  std_logic;
            reset          : in  std_logic;
            btnC, btnL, btnR, btnU, btnD : in std_logic;
            sw_clock, sw_alarm : in std_logic;
            Anode_Activate : out std_logic_vector(3 downto 0);
            LED_out        : out std_logic_vector(6 downto 0);
            led_sec        : out std_logic_vector(5 downto 0);
            led_alarm_on   : out std_logic;
            buzzer         : out std_logic
        );
    end component;

    -- Inputs
    signal clock_100Mhz : std_logic := '0';
    signal reset        : std_logic := '0';
    signal btnC         : std_logic := '1';
    signal btnL         : std_logic := '1';
    signal btnR         : std_logic := '1';
    signal btnU         : std_logic := '1';
    signal btnD         : std_logic := '1';
    signal sw_clock     : std_logic := '0';
    signal sw_alarm     : std_logic := '0';

    -- Outputs
    signal Anode_Activate : std_logic_vector(3 downto 0);
    signal LED_out        : std_logic_vector(6 downto 0);
    signal led_sec        : std_logic_vector(5 downto 0);
    signal led_alarm_on   : std_logic;
    signal buzzer         : std_logic;

    -- Clock period definitions (100 MHz = 10 ns period)
    constant clk_period : time := 10 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: digital_clock_setting
        Port Map (
            clock_100Mhz   => clock_100Mhz,
            reset          => reset,
            btnC           => btnC,
            btnL           => btnL,
            btnR           => btnR,
            btnU           => btnU,
            btnD           => btnD,
            sw_clock       => sw_clock,
            sw_alarm       => sw_alarm,
            Anode_Activate => Anode_Activate,
            LED_out        => LED_out,
            led_sec        => led_sec,
            led_alarm_on   => led_alarm_on,
            buzzer         => buzzer
        );

    -- Clock process definitions (100 MHz oscillator)
    clk_process : process
    begin
        clock_100Mhz <= '0';
        wait for clk_period/2;
        clock_100Mhz <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- 1. Apply Global Reset
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;

        -- 2. Verify Normal Display Multiplexing
        wait for 1 us;

        -- 3. Enter Clock Setting Mode
        sw_clock <= '1';
        wait for 200 ns;

        -- Press Button UP (btnU pulse: 1 -> 0 -> 1)
        btnU <= '0';
        wait for 50 ns;
        btnU <= '1';
        wait for 200 ns;

        -- Toggle to Minutes field (btnC pulse)
        btnC <= '0';
        wait for 50 ns;
        btnC <= '1';
        wait for 200 ns;

        -- Increment minutes
        btnU <= '0';
        wait for 50 ns;
        btnU <= '1';
        wait for 200 ns;

        -- Exit Clock Setting Mode
        sw_clock <= '0';
        wait for 500 ns;

        -- 4. Enter Alarm Setting Mode
        sw_alarm <= '1';
        wait for 200 ns;

        -- Increment alarm hours
        btnU <= '0';
        wait for 50 ns;
        btnU <= '1';
        wait for 200 ns;

        -- Exit Alarm Setting Mode
        sw_alarm <= '0';
        wait for 1 us;

        -- Finish simulation
        wait;
    end process;

end Behavioral;
