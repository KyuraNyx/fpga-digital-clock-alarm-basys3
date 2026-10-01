## =====================================================================
## Constraints file (.xdc) for Digilent Basys 3 FPGA Board
## Project: Digital Clock & Alarm System
## Target Device: Artix-7 xc7a35tcpg236-1
## =====================================================================

## ---------------------------------------------------------------------
## 100 MHz Clock Signal
## ---------------------------------------------------------------------
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports clock_100Mhz]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clock_100Mhz]

## ---------------------------------------------------------------------
## Slide Switches
## ---------------------------------------------------------------------
set_property -dict { PACKAGE_PIN V17  IOSTANDARD LVCMOS33 } [get_ports sw_alarm]
set_property -dict { PACKAGE_PIN V16  IOSTANDARD LVCMOS33 } [get_ports sw_clock]
set_property -dict { PACKAGE_PIN R2   IOSTANDARD LVCMOS33 } [get_ports reset]

## ---------------------------------------------------------------------
## Push Buttons
## ---------------------------------------------------------------------
set_property -dict { PACKAGE_PIN U18  IOSTANDARD LVCMOS33 } [get_ports btnC]
set_property -dict { PACKAGE_PIN T18  IOSTANDARD LVCMOS33 } [get_ports btnU]
set_property -dict { PACKAGE_PIN W19  IOSTANDARD LVCMOS33 } [get_ports btnL]
set_property -dict { PACKAGE_PIN T17  IOSTANDARD LVCMOS33 } [get_ports btnR]
set_property -dict { PACKAGE_PIN U17  IOSTANDARD LVCMOS33 } [get_ports btnD]

## ---------------------------------------------------------------------
## Onboard LEDs
## ---------------------------------------------------------------------
# 6-bit Binary Seconds (LD0 .. LD5)
set_property -dict { PACKAGE_PIN U16  IOSTANDARD LVCMOS33 } [get_ports {led_sec[0]}]
set_property -dict { PACKAGE_PIN E19  IOSTANDARD LVCMOS33 } [get_ports {led_sec[1]}]
set_property -dict { PACKAGE_PIN U19  IOSTANDARD LVCMOS33 } [get_ports {led_sec[2]}]
set_property -dict { PACKAGE_PIN V19  IOSTANDARD LVCMOS33 } [get_ports {led_sec[3]}]
set_property -dict { PACKAGE_PIN W18  IOSTANDARD LVCMOS33 } [get_ports {led_sec[4]}]
set_property -dict { PACKAGE_PIN U15  IOSTANDARD LVCMOS33 } [get_ports {led_sec[5]}]

# Alarm Active Indicator (LD15 / L1)
set_property -dict { PACKAGE_PIN L1   IOSTANDARD LVCMOS33 } [get_ports led_alarm_on]

## ---------------------------------------------------------------------
## 4-Digit Seven Segment Display (Active Low Cathodes & Anodes)
## ---------------------------------------------------------------------
# Cathodes (CA, CB, CC, CD, CE, CF, CG)
set_property -dict { PACKAGE_PIN W7   IOSTANDARD LVCMOS33 } [get_ports {LED_out[0]}]
set_property -dict { PACKAGE_PIN W6   IOSTANDARD LVCMOS33 } [get_ports {LED_out[1]}]
set_property -dict { PACKAGE_PIN U8   IOSTANDARD LVCMOS33 } [get_ports {LED_out[2]}]
set_property -dict { PACKAGE_PIN V8   IOSTANDARD LVCMOS33 } [get_ports {LED_out[3]}]
set_property -dict { PACKAGE_PIN U5   IOSTANDARD LVCMOS33 } [get_ports {LED_out[4]}]
set_property -dict { PACKAGE_PIN V5   IOSTANDARD LVCMOS33 } [get_ports {LED_out[5]}]
set_property -dict { PACKAGE_PIN U7   IOSTANDARD LVCMOS33 } [get_ports {LED_out[6]}]

# Anodes (AN0, AN1, AN2, AN3)
set_property -dict { PACKAGE_PIN U2   IOSTANDARD LVCMOS33 } [get_ports {Anode_Activate[0]}]
set_property -dict { PACKAGE_PIN U4   IOSTANDARD LVCMOS33 } [get_ports {Anode_Activate[1]}]
set_property -dict { PACKAGE_PIN V4   IOSTANDARD LVCMOS33 } [get_ports {Anode_Activate[2]}]
set_property -dict { PACKAGE_PIN W4   IOSTANDARD LVCMOS33 } [get_ports {Anode_Activate[3]}]

## ---------------------------------------------------------------------
## Pmod Header JA (Piezo Passive Buzzer on JA4)
## ---------------------------------------------------------------------
set_property -dict { PACKAGE_PIN G2   IOSTANDARD LVCMOS33 } [get_ports buzzer]; # Pmod JA4 (Sch name = JA4)

## ---------------------------------------------------------------------
## Bitstream Configuration Options
## ---------------------------------------------------------------------
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
