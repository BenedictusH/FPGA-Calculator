## slide switches
set_property PACKAGE_PIN W2 [get_ports {sw12}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw12}]

set_property PACKAGE_PIN R3 [get_ports {sw11}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw11}]

set_property PACKAGE_PIN T2 [get_ports {sw10}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw10}]

set_property PACKAGE_PIN T3 [get_ports {sw9}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw9}]

set_property PACKAGE_PIN V2 [get_ports {sw8}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw8}]

set_property PACKAGE_PIN W13 [get_ports {sw7}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw7}]

set_property PACKAGE_PIN W14 [get_ports {sw6}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw6}]

set_property PACKAGE_PIN V15 [get_ports {sw5}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw5}]

set_property PACKAGE_PIN W15 [get_ports {sw4}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw4}]

set_property PACKAGE_PIN W17 [get_ports {sw3}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw3}]

set_property PACKAGE_PIN W16 [get_ports {sw2}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw2}]

set_property PACKAGE_PIN V16 [get_ports {sw1}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw1}]

set_property PACKAGE_PIN V17 [get_ports {sw0}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw0}]

set_property PACKAGE_PIN R2 [get_ports {run}]
set_property IOSTANDARD LVCMOS33 [get_ports {run}]

## Buttons
set_property PACKAGE_PIN T18 [get_ports {RST_in}]
set_property IOSTANDARD LVCMOS33 [get_ports {RST_in}]

set_property PACKAGE_PIN U18 [get_ports {but1}]
set_property IOSTANDARD LVCMOS33 [get_ports {but1}]

set_property PACKAGE_PIN W19 [get_ports {but2}]
set_property IOSTANDARD LVCMOS33 [get_ports {but2}]

set_property PACKAGE_PIN T17 [get_ports {but0}]
set_property IOSTANDARD LVCMOS33 [get_ports {but0}]

## CLOCK
set_property PACKAGE_PIN W5 [get_ports {CLK_in}]
set_property IOSTANDARD LVCMOS33 [get_ports {CLK_in}]

## outputs

#seven-segment LED display
set_property PACKAGE_PIN W7 [get_ports {led_code[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_code[7]}]

set_property PACKAGE_PIN W6 [get_ports {led_code[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_code[6]}]

set_property PACKAGE_PIN U8 [get_ports {led_code[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_code[5]}]

set_property PACKAGE_PIN V8 [get_ports {led_code[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_code[4]}]

set_property PACKAGE_PIN U5 [get_ports {led_code[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_code[3]}]

set_property PACKAGE_PIN V5 [get_ports {led_code[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_code[2]}]

set_property PACKAGE_PIN U7 [get_ports {led_code[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_code[1]}]

set_property PACKAGE_PIN V7 [get_ports {led_code[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_code[0]}]

set_property PACKAGE_PIN U2 [get_ports {led_active[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_active[0]}]

set_property PACKAGE_PIN U4 [get_ports {led_active[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_active[1]}]

set_property PACKAGE_PIN V4 [get_ports {led_active[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_active[2]}]

set_property PACKAGE_PIN W4 [get_ports {led_active[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_active[3]}]

## sign led
set_property PACKAGE_PIN E19 [get_ports {sign_led}]
set_property IOSTANDARD LVCMOS33 [get_ports {sign_led}]

## but led
set_property PACKAGE_PIN U15 [get_ports {state_led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {state_led[2]}]

set_property PACKAGE_PIN W18 [get_ports {state_led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {state_led[1]}]

set_property PACKAGE_PIN V19 [get_ports {state_led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {state_led[0]}]

## stage LED-s
set_property PACKAGE_PIN L1 [get_ports {stage_led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {stage_led[3]}]

set_property PACKAGE_PIN P1 [get_ports {stage_led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {stage_led[2]}]

set_property PACKAGE_PIN N3 [get_ports {stage_led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {stage_led[1]}]

set_property PACKAGE_PIN P3 [get_ports {stage_led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {stage_led[0]}]

set_property PACKAGE_PIN U16 [get_ports {error}]
set_property IOSTANDARD LVCMOS33 [get_ports {error}]