# Fixed board-port constraints for current Mercury_XU5_wrapper top-level ports
# Generated from routed checkpoint diagnostic STEP 18A

# Ethernet generated clocks / reset
set_property -dict {PACKAGE_PIN AA13 IOSTANDARD LVCMOS18} [get_ports ETH_CLK10]
set_property -dict {PACKAGE_PIN AB13 IOSTANDARD LVCMOS18} [get_ports ETH_CLK125]
set_property -dict {PACKAGE_PIN AC14 IOSTANDARD LVCMOS18} [get_ports ETH_CLK125_90]
set_property -dict {PACKAGE_PIN AC13 IOSTANDARD LVCMOS18} [get_ports ETH_CLK25]
set_property -dict {PACKAGE_PIN AD15 IOSTANDARD LVCMOS18} [get_ports ETH_resetn]

# MDIO

# GMII RX

# GMII TX

# IIC

# LEDs and reset
set_property -dict {PACKAGE_PIN D12 IOSTANDARD LVCMOS18} [get_ports {LED_N_PL[0]}]
set_property -dict {PACKAGE_PIN C12 IOSTANDARD LVCMOS18} [get_ports {LED_N_PL[1]}]
set_property -dict {PACKAGE_PIN AH13 IOSTANDARD LVCMOS18} [get_ports Rst_N]

# Optional slew for fast Ethernet TX-related outputs

set_property SLEW FAST [get_ports ETH_CLK10]
set_property SLEW FAST [get_ports ETH_CLK25]
set_property SLEW FAST [get_ports ETH_CLK125]
set_property SLEW FAST [get_ports ETH_CLK125_90]

####################################################################################
# Constraints from file : 'dac8568_pins.xdc'
####################################################################################

