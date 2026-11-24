# SPIKE programmer external pins
# Updated after disabling unused GEM1 and IIC1 EMIO interfaces
# Target I/O standard: LVCMOS18

set_property -dict {PACKAGE_PIN AA11 IOSTANDARD LVCMOS18} [get_ports SPIKE_CHIP_CLK]
set_property -dict {PACKAGE_PIN AD12 IOSTANDARD LVCMOS18} [get_ports SPIKE_CHIP_DATA]
set_property -dict {PACKAGE_PIN AC12 IOSTANDARD LVCMOS18} [get_ports SPIKE_CHIP_LATCH]
set_property -dict {PACKAGE_PIN Y9 IOSTANDARD LVCMOS18} [get_ports SPIKE_CHIP_ENABLE]
set_property -dict {PACKAGE_PIN L7 IOSTANDARD LVCMOS18} [get_ports SPIKE_CHIP_Q]
set_property -dict {PACKAGE_PIN P9 IOSTANDARD LVCMOS18} [get_ports SPIKE_SUCCESS_LED]

