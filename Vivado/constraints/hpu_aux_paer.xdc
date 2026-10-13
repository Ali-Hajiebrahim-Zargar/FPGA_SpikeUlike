# HPU Core Auxiliary RX PAER interface
# Target: Enclustra Mercury XU5, ME-XU5-5EV-2I-D12E
# Electrical standard: 1.8 V LVCMOS
# PAER address width: 9 bits
# Handshake polarity is configured inside HPU Core (default active-low).

# Auxiliary PAER event address inputs
set_property -dict {PACKAGE_PIN B1 IOSTANDARD LVCMOS18} [get_ports {HPU_AUX_PAER_ADDR[0]}]
set_property -dict {PACKAGE_PIN C1 IOSTANDARD LVCMOS18} [get_ports {HPU_AUX_PAER_ADDR[1]}]
set_property -dict {PACKAGE_PIN A1 IOSTANDARD LVCMOS18} [get_ports {HPU_AUX_PAER_ADDR[2]}]
set_property -dict {PACKAGE_PIN A2 IOSTANDARD LVCMOS18} [get_ports {HPU_AUX_PAER_ADDR[3]}]
set_property -dict {PACKAGE_PIN A4 IOSTANDARD LVCMOS18} [get_ports {HPU_AUX_PAER_ADDR[4]}]
set_property -dict {PACKAGE_PIN B4 IOSTANDARD LVCMOS18} [get_ports {HPU_AUX_PAER_ADDR[5]}]
set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS18} [get_ports {HPU_AUX_PAER_ADDR[6]}]
set_property -dict {PACKAGE_PIN A9 IOSTANDARD LVCMOS18} [get_ports {HPU_AUX_PAER_ADDR[7]}]
set_property -dict {PACKAGE_PIN D9 IOSTANDARD LVCMOS18} [get_ports {HPU_AUX_PAER_ADDR[8]}]

# Auxiliary PAER request input and acknowledge output
set_property -dict {PACKAGE_PIN E9 IOSTANDARD LVCMOS18} [get_ports {HPU_AUX_PAER_REQ}]
set_property -dict {PACKAGE_PIN F7 IOSTANDARD LVCMOS18 DRIVE 8 SLEW SLOW} [get_ports {HPU_AUX_PAER_ACK}]
