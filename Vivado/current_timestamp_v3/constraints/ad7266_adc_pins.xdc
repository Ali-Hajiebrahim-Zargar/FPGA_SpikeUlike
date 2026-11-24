# ============================================================
# AD7266 ADC1..ADC4 physical pin constraints
# Interface voltage: 1.8 V
# ============================================================

# ADC1
set_property -dict {PACKAGE_PIN C6 IOSTANDARD LVCMOS18} [get_ports ADC1_CS]
set_property -dict {PACKAGE_PIN B6 IOSTANDARD LVCMOS18} [get_ports ADC1_SCLK]
set_property -dict {PACKAGE_PIN D7 IOSTANDARD LVCMOS18} [get_ports ADC1_DOUTA]
set_property -dict {PACKAGE_PIN D6 IOSTANDARD LVCMOS18} [get_ports ADC1_DOUTB]
set_property -dict {PACKAGE_PIN H1 IOSTANDARD LVCMOS18} [get_ports {ADC1_A[0]}]
set_property -dict {PACKAGE_PIN J1 IOSTANDARD LVCMOS18} [get_ports {ADC1_A[1]}]
set_property -dict {PACKAGE_PIN J4 IOSTANDARD LVCMOS18} [get_ports {ADC1_A[2]}]

# ADC2
set_property -dict {PACKAGE_PIN A7 IOSTANDARD LVCMOS18} [get_ports ADC2_CS]
set_property -dict {PACKAGE_PIN A6 IOSTANDARD LVCMOS18} [get_ports ADC2_SCLK]
set_property -dict {PACKAGE_PIN C9 IOSTANDARD LVCMOS18} [get_ports ADC2_DOUTA]
set_property -dict {PACKAGE_PIN B9 IOSTANDARD LVCMOS18} [get_ports ADC2_DOUTB]
set_property -dict {PACKAGE_PIN D5 IOSTANDARD LVCMOS18} [get_ports {ADC2_A[0]}]
set_property -dict {PACKAGE_PIN E5 IOSTANDARD LVCMOS18} [get_ports {ADC2_A[1]}]
set_property -dict {PACKAGE_PIN J2 IOSTANDARD LVCMOS18} [get_ports {ADC2_A[2]}]

# ADC3
set_property -dict {PACKAGE_PIN G8 IOSTANDARD LVCMOS18} [get_ports ADC3_CS]
set_property -dict {PACKAGE_PIN J7 IOSTANDARD LVCMOS18} [get_ports ADC3_SCLK]
set_property -dict {PACKAGE_PIN R6 IOSTANDARD LVCMOS18} [get_ports ADC3_DOUTA]
set_property -dict {PACKAGE_PIN T6 IOSTANDARD LVCMOS18} [get_ports ADC3_DOUTB]
set_property -dict {PACKAGE_PIN P6 IOSTANDARD LVCMOS18} [get_ports {ADC3_A[0]}]
set_property -dict {PACKAGE_PIN P7 IOSTANDARD LVCMOS18} [get_ports {ADC3_A[1]}]
set_property -dict {PACKAGE_PIN H7 IOSTANDARD LVCMOS18} [get_ports {ADC3_A[2]}]

# ADC4
set_property -dict {PACKAGE_PIN N6 IOSTANDARD LVCMOS18} [get_ports ADC4_CS]
set_property -dict {PACKAGE_PIN M6 IOSTANDARD LVCMOS18} [get_ports ADC4_SCLK]
set_property -dict {PACKAGE_PIN L5 IOSTANDARD LVCMOS18} [get_ports ADC4_DOUTA]
set_property -dict {PACKAGE_PIN N7 IOSTANDARD LVCMOS18} [get_ports ADC4_DOUTB]
set_property -dict {PACKAGE_PIN C2 IOSTANDARD LVCMOS18} [get_ports {ADC4_A[0]}]
set_property -dict {PACKAGE_PIN C3 IOSTANDARD LVCMOS18} [get_ports {ADC4_A[1]}]
set_property -dict {PACKAGE_PIN L3 IOSTANDARD LVCMOS18} [get_ports {ADC4_A[2]}]

set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]
