## This file is a general .xdc for the Basys3 rev B board
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

## Clock signal
set_property PACKAGE_PIN W5 [get_ports CLK]
set_property IOSTANDARD LVCMOS33 [get_ports CLK]
create_clock -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports CLK]

# LEDS
set_property PACKAGE_PIN U16 [get_ports {LEDS[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LEDS[0]}]
set_property PACKAGE_PIN E19 [get_ports {LEDS[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LEDS[1]}]
set_property PACKAGE_PIN U19 [get_ports {LEDS[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LEDS[2]}]
set_property PACKAGE_PIN V19 [get_ports {LEDS[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LEDS[3]}]
set_property PACKAGE_PIN W18 [get_ports {LEDS[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LEDS[4]}]
set_property PACKAGE_PIN U15 [get_ports {LEDS[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LEDS[5]}]
set_property PACKAGE_PIN U14 [get_ports {LEDS[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LEDS[6]}]
set_property PACKAGE_PIN V14 [get_ports {LEDS[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LEDS[7]}]
set_property PACKAGE_PIN V13 [get_ports {LEDS[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LEDS[8]}]
set_property PACKAGE_PIN V3 [get_ports {LEDS[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LEDS[9]}]
set_property PACKAGE_PIN W3 [get_ports {LEDS[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LEDS[10]}]
set_property PACKAGE_PIN U3 [get_ports {LEDS[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LEDS[11]}]
set_property PACKAGE_PIN P3 [get_ports {LEDS[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LEDS[12]}]
set_property PACKAGE_PIN N3 [get_ports {LEDS[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LEDS[13]}]
set_property PACKAGE_PIN P1 [get_ports {LEDS[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LEDS[14]}]
set_property PACKAGE_PIN L1 [get_ports {LEDS[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LEDS[15]}]

set_property PACKAGE_PIN U18 [get_ports RST]
set_property IOSTANDARD LVCMOS33 [get_ports RST]
