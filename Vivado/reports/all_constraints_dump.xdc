
# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_zynq_ultra_ps_e_0/Mercury_XU5_zynq_ultra_ps_e_0_ooc.xdc
# ==========================================================
#
#
#


# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_zynq_ultra_ps_e_0/Mercury_XU5_zynq_ultra_ps_e_0_ooc.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_zynq_ultra_ps_e_0/Mercury_XU5_zynq_ultra_ps_e_0.xdc
# ==========================================================
##############################PS XDC#########################################
############################################################################
##
##  Xilinx, Inc. 2006            www.xilinx.com
############################################################################
##  File name :       psu_constraints.xdc
##
##  Details :     Constraints file
##                    FPGA family:       zynq
##                    FPGA:              PROD-2
##                    Device Size:       xczu5ev
##                    Package:           sfvc784
##                    Speedgrade:        -2
##
##
############################################################################
############################################################################
############################################################################
# Clock constraints                                                        #
############################################################################
create_clock -name clk_pl_0 -period "10" [get_pins "PS8_i/PLCLK[0]"]
create_clock -name clk_pl_1 -period "20" [get_pins "PS8_i/PLCLK[1]"]
create_clock -name mdio1_mdc_clock -period "480" [get_pins "PS8_i/EMIOENET1MDIOMDC"]



set_property DONT_TOUCH true [get_cells "PS8_i"]


# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_zynq_ultra_ps_e_0/Mercury_XU5_zynq_ultra_ps_e_0.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_system_management_wiz_0/Mercury_XU5_system_management_wiz_0_board.xdc
# ==========================================================
#--------------------Physical Constraints-----------------



# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_system_management_wiz_0/Mercury_XU5_system_management_wiz_0_board.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_system_management_wiz_0/Mercury_XU5_system_management_wiz_0_ooc.xdc
# ==========================================================
# file: Mercury_XU5_system_management_wiz_0_ooc.xdc
# (c) Copyright 2013 - 2023 AMD, Inc. All rights reserved.
# 
# This file contains confidential and proprietary information
# of AMD, Inc. and is protected under U.S. and
# international copyright and other intellectual property
# laws.
# 
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# AMD, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) AMD shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or AMD had been advised of the
# possibility of the same.
# 
# CRITICAL APPLICATIONS
# AMD products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of AMD products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
# 
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.

#################
#DEFAULT CLOCK CONSTRAINTS

############################################################
# Clock Period Constraints                                 #
############################################################
create_clock -name s_axi_aclk -period 10.0 [get_ports s_axi_aclk]



# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_system_management_wiz_0/Mercury_XU5_system_management_wiz_0_ooc.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_system_management_wiz_0/Mercury_XU5_system_management_wiz_0.xdc
# ==========================================================
# file: Mercury_XU5_system_management_wiz_0.xdc
# (c) Copyright 2013 - 2023 AMD, Inc. All rights reserved.
# 
# This file contains confidential and proprietary information
# of AMD, Inc. and is protected under U.S. and
# international copyright and other intellectual property
# laws.
# 
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# AMD, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) AMD shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or AMD had been advised of the
# possibility of the same.
# 
# CRITICAL APPLICATIONS
# AMD products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of AMD products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
# 
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.


# Input clock periods. These duplicate the values entered for the
#  input clocks. You can use these to time your system
#----------------------------------------------------------------
#create_clock -name s_axi_aclk -period 10.0 [get_ports s_axi_aclk]

set_property LOC SYSMONE4_X0Y0 [get_cells -hier {*inst_sysmon} -filter {NAME =~ *inst_sysmon}]
set_property DONT_TOUCH true [get_cells -hierarchical -filter {NAME =~*/inst_sysmon*}]




# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_system_management_wiz_0/Mercury_XU5_system_management_wiz_0.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_led_0/Mercury_XU5_led_0_board.xdc
# ==========================================================
#--------------------Physical Constraints-----------------



# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_led_0/Mercury_XU5_led_0_board.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_led_0/Mercury_XU5_led_0_ooc.xdc
# ==========================================================

################################################################################
# (c) Copyright 2012 - 2013, 2023 Advanced Micro Devices, Inc. All rights reserved.
# 
# This file contains confidential and proprietary information
# of Advanced Micro Devices, Inc. and is protected under U.S. and
# international copyright and other intellectual property
# laws.
# 
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# AMD, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) AMD shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or AMD had been advised of the
# possibility of the same.
# 
# CRITICAL APPLICATIONS
# AMD products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of AMD products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
# 
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.

################################################################################

# This XDC is used only for OOC mode of synthesis, implementation
# User should update the correct clock period before proceeding further
# This constraints file contains default clock frequencies to be used during 
# out-of-context flows such as OOC Synthesis and Hierarchical Designs. 
# For best results the frequencies should be modified# to match the target 
# frequencies. 


 create_clock -name s_axi_clk -period 10 [get_ports s_axi_aclk]
## set_property HD.CLK_SRC BUFGCTRL_X0Y0 [get_ports s_axi_aclk]

################################################################################


# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_led_0/Mercury_XU5_led_0_ooc.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/ip_1/par/Mercury_XU5_ddr4_0_phy_ooc.xdc
# ==========================================================
# This constraints file is not used in normal top-down synthesis (the default flow of Vivado)


# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/ip_1/par/Mercury_XU5_ddr4_0_phy_ooc.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/bd_0/ip/ip_0/bd_8825_microblaze_I_0.xdc
# ==========================================================
set_false_path -through [get_ports "Reset"]
create_waiver -internal -scoped -user microblaze -tags 12436 -type CDC -id CDC-26 -description "Invalid LUTRAM collision warning" \
  -to [get_pins -quiet "LOCKSTEP_Out_reg\[*\]/R"]
create_waiver -internal -scoped -user microblaze -tags 12436 -type CDC -id CDC-26 -description "Invalid LUTRAM collision warning" \
  -to [get_pins -quiet "MicroBlaze_Core_I/*Interrupt_DFF/Single_Synchronize.use_sync_reset.sync_reg/D"]

# Waivers for FPU and hardware multiplier
create_waiver -internal -scoped -user microblaze -tags 12436 -type DRC -id DPIP-1 -description "Non-pipelined by design" \
  -objects [get_cells -hierarchical *DSP48E1_I1] \
  -objects [get_pins -quiet -filter {REF_PIN_NAME=~A[*]} -of [get_cells -hierarchical *DSP48E1_I1]]
create_waiver -internal -scoped -user microblaze -tags 12436 -type DRC -id DPIP-1 -description "Non-pipelined by design" \
  -objects [get_cells -hierarchical *DSP48E1_I1] \
  -objects [get_pins -quiet -filter {REF_PIN_NAME=~B[*]} -of [get_cells -hierarchical *DSP48E1_I1]]
create_waiver -internal -scoped -user microblaze -tags 12436 -type DRC -id DPIP-2 -description "Non-pipelined by design" \
  -objects [get_cells -hierarchical *DSP48E1_I1] \
  -objects [get_pins -quiet -filter {REF_PIN_NAME=~A[*]} -of [get_cells -hierarchical *DSP48E1_I1]]
create_waiver -internal -scoped -user microblaze -tags 12436 -type DRC -id DPIP-2 -description "Non-pipelined by design" \
  -objects [get_cells -hierarchical *DSP48E1_I1] \
  -objects [get_pins -quiet -filter {REF_PIN_NAME=~B[*]} -of [get_cells -hierarchical *DSP48E1_I1]]
create_waiver -internal -scoped -user microblaze -tags 12436 -type DRC -id DPOP-1 -description "Non-pipelined by design" \
  -objects [get_cells -hierarchical *DSP48E1_I1] \
  -objects [get_pins -quiet -filter {REF_PIN_NAME=~P*} -of [get_cells -hierarchical *DSP48E1_I1]]
create_waiver -internal -scoped -user microblaze -tags 12436 -type DRC -id DPOP-2 -description "Non-pipelined by design" \
  -objects [get_cells -hierarchical *DSP48E1_I1] \
  -objects [get_pins -quiet -filter {REF_PIN_NAME=~P*} -of [get_cells -hierarchical *DSP48E1_I1]]
create_waiver -internal -scoped -user microblaze -tags 12436 -type DRC -id DPOP-3 -description "Non-pipelined by design" \
  -objects [get_cells -hierarchical *DSP48E1_I1] \
  -objects [get_pins -quiet -filter {REF_PIN_NAME=~P*} -of [get_cells -hierarchical *DSP48E1_I1]]
create_waiver -internal -scoped -user microblaze -tags 12436 -type DRC -id DPOP-3 -description "Non-pipelined by design" \
  -objects [get_cells -hierarchical *DSP48E1_I1] \
  -objects [get_pins -quiet -filter {REF_PIN_NAME=~PATTERN*} -of [get_cells -hierarchical *DSP48E1_I1]]
create_waiver -internal -scoped -user microblaze -tags 12436 -type DRC -id DPOP-3 -description "Non-pipelined by design" \
  -objects [get_cells -hierarchical *DSP48E1_I1] \
  -objects [get_pins -quiet -filter {REF_PIN_NAME=~*OUT*} -of [get_cells -hierarchical *DSP48E1_I1]]
create_waiver -internal -scoped -user microblaze -tags 12436 -type DRC -id DPOP-4 -description "Non-pipelined by design" \
  -objects [get_cells -hierarchical *DSP48E1_I1] \
  -objects [get_pins -quiet -filter {REF_PIN_NAME=~P[*]} -of [get_cells -hierarchical *DSP48E1_I1]]
create_waiver -internal -scoped -user microblaze -tags 12436 -type DRC -id DPOP-4 -description "Non-pipelined by design" \
  -objects [get_cells -hierarchical *DSP48E1_I1] \
  -objects [get_pins -quiet -filter {REF_PIN_NAME=~PATTERN*} -of [get_cells -hierarchical *DSP48E1_I1]]
create_waiver -internal -scoped -user microblaze -tags 12436 -type DRC -id DPOP-4 -description "Non-pipelined by design" \
  -objects [get_cells -hierarchical *DSP48E1_I1] \
  -objects [get_pins -quiet -filter {REF_PIN_NAME=~*OUT*} -of [get_cells -hierarchical *DSP48E1_I1]]


# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/bd_0/ip/ip_0/bd_8825_microblaze_I_0.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/bd_0/ip/ip_0/bd_8825_microblaze_I_0_ooc_debug.xdc
# ==========================================================

# This constraints file contains default clock frequencies to be used during 
# out-of-context flows such as OOC Synthesis and Hierarchical Designs. For 
# best results the frequencies should be modified to match the target 
# frequencies. This constraints file is not used in normal top-down 
# synthesis (the default flow of Vivado)



# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/bd_0/ip/ip_0/bd_8825_microblaze_I_0_ooc_debug.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/bd_0/ip/ip_1/bd_8825_rst_0_0_board.xdc
# ==========================================================
#--------------------Physical Constraints-----------------



# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/bd_0/ip/ip_1/bd_8825_rst_0_0_board.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/bd_0/ip/ip_2/bd_8825_ilmb_0.xdc
# ==========================================================
set_false_path -through [get_ports "SYS_Rst"]


# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/bd_0/ip/ip_2/bd_8825_ilmb_0.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/bd_0/ip/ip_3/bd_8825_dlmb_0.xdc
# ==========================================================
set_false_path -through [get_ports "SYS_Rst"]


# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/bd_0/ip/ip_3/bd_8825_dlmb_0.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/bd_0/ip/ip_6/bd_8825_lmb_bram_I_0_ooc.xdc
# ==========================================================
################################################################################
#
# (c) Copyright 2002 - 2013 Advanced Micro Devices, Inc. All rights reserved.
# 
# This file contains confidential and proprietary information
# of Advanced Micro Devices, Inc. and is protected under U.S. and
# international copyright and other intellectual property
# laws.
# 
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# AMD, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) AMD shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or AMD had been advised of the
# possibility of the same.
# 
# CRITICAL APPLICATIONS
# AMD products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of AMD products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
# 
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.
#
################################################################################

# Core Period Constraint. This constraint can be modified, and is
# valid as long as it is met after place and route.
create_clock -name "TS_CLKA" -period 20.0 [ get_ports clka ]
  
create_clock -name "TS_CLKB" -period 20.0 [ get_ports clkb ]
################################################################################


# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/bd_0/ip/ip_6/bd_8825_lmb_bram_I_0_ooc.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/bd_0/ip/ip_9/bd_8825_second_lmb_bram_I_0_ooc.xdc
# ==========================================================
################################################################################
#
# (c) Copyright 2002 - 2013 Advanced Micro Devices, Inc. All rights reserved.
# 
# This file contains confidential and proprietary information
# of Advanced Micro Devices, Inc. and is protected under U.S. and
# international copyright and other intellectual property
# laws.
# 
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# AMD, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) AMD shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or AMD had been advised of the
# possibility of the same.
# 
# CRITICAL APPLICATIONS
# AMD products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of AMD products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
# 
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.
#
################################################################################

# Core Period Constraint. This constraint can be modified, and is
# valid as long as it is met after place and route.
create_clock -name "TS_CLKA" -period 20.0 [ get_ports clka ]
  
create_clock -name "TS_CLKB" -period 20.0 [ get_ports clkb ]
################################################################################


# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/bd_0/ip/ip_9/bd_8825_second_lmb_bram_I_0_ooc.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/bd_0/ip/ip_10/bd_8825_iomodule_0_0_board.xdc
# ==========================================================
#--------------------Physical Constraints-----------------



# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/bd_0/ip/ip_10/bd_8825_iomodule_0_0_board.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/bd_0/bd_8825_ooc.xdc
# ==========================================================
################################################################################

# This XDC is used only for OOC mode of synthesis, implementation
# This constraints file contains default clock frequencies to be used during
# out-of-context flows such as OOC Synthesis and Hierarchical Designs.
# This constraints file is not used in normal top-down synthesis (default flow
# of Vivado)
################################################################################
create_clock -name Clk -period 10 [get_ports Clk]

################################################################################

# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/bd_0/bd_8825_ooc.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/ip_0/Mercury_XU5_ddr4_0_microblaze_mcs_board.xdc
# ==========================================================
#--------------------Physical Constraints-----------------



# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/ip_0/Mercury_XU5_ddr4_0_microblaze_mcs_board.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/ip_0/Mercury_XU5_ddr4_0_microblaze_mcs_ooc.xdc
# ==========================================================
# file: Mercury_XU5_ddr4_0_microblaze_mcs_ooc.xdc

# This constraints file contains default clock frequencies to be used during 
# out-of-context flows such as OOC Synthesis and Hierarchical Designs.
# This constraints file is not used in normal top-down synthesis (the default
# flow of Vivado).

create_clock -name Clk -period 10.000 [get_ports Clk]
# set_property HD.CLK_SRC BUFGCTRL_X0Y0 [get_ports Clk]


# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/ip_0/Mercury_XU5_ddr4_0_microblaze_mcs_ooc.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/Mercury_XU5_ddr4_0_board.xdc
# ==========================================================
#--------------------Physical Constraints-----------------



# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/Mercury_XU5_ddr4_0_board.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/par/Mercury_XU5_ddr4_0.xdc
# ==========================================================
## please copy over all contents of the XDC when it is merged with othe XDC files ##

## Clock constraint for input system clock which drives MMCM for the design

## The frequency of the input clock is as per GUI selected input clock period

create_clock -period 9.996 [get_ports c0_sys_clk_p]


## Below pin LOC constraints are for system clock and system reset and

## memory related pins

set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_bg[0]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_ba[0]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_adr[14]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_adr[13]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_cke[0]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_dq[6]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_dq[4]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_dq[2]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_cs_n[0]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_ba[1]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_adr[12]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_adr[11]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_dq[7]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_dq[5]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_dq[3]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_dm_dbi_n[0]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_adr[16]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_adr[15]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_adr[10]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_adr[9]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_dqs_t[0]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_odt[0]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_dqs_t[1]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_dq[10]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_adr[6]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_dqs_c[0]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_dq[1]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_dq[0]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_dq[14]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_dqs_c[1]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_dq[11]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_adr[7]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_adr[2]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_dq[15]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_dq[8]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_dm_dbi_n[1]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_ck_c[0]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_ck_t[0]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_adr[3]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_adr[0]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_dq[13]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_dq[12]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_dq[9]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_act_n" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_adr[8]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_adr[5]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_adr[4]" ]
set_property OUTPUT_IMPEDANCE RDRV_40_40 [ get_ports "c0_ddr4_adr[1]" ]




set_property IOSTANDARD SSTL12_DCI [ get_ports "c0_ddr4_bg[0]" ]
set_property IOSTANDARD SSTL12_DCI [ get_ports "c0_ddr4_ba[0]" ]
set_property IOSTANDARD SSTL12_DCI [ get_ports "c0_ddr4_adr[14]" ]
set_property IOSTANDARD SSTL12_DCI [ get_ports "c0_ddr4_adr[13]" ]
set_property IOSTANDARD SSTL12_DCI [ get_ports "c0_ddr4_cke[0]" ]
set_property IOSTANDARD POD12_DCI [ get_ports "c0_ddr4_dq[6]" ]
set_property IOSTANDARD POD12_DCI [ get_ports "c0_ddr4_dq[4]" ]
set_property IOSTANDARD POD12_DCI [ get_ports "c0_ddr4_dq[2]" ]
set_property IOSTANDARD SSTL12_DCI [ get_ports "c0_ddr4_cs_n[0]" ]
set_property IOSTANDARD SSTL12_DCI [ get_ports "c0_ddr4_ba[1]" ]
set_property IOSTANDARD SSTL12_DCI [ get_ports "c0_ddr4_adr[12]" ]
set_property IOSTANDARD SSTL12_DCI [ get_ports "c0_ddr4_adr[11]" ]
set_property IOSTANDARD POD12_DCI [ get_ports "c0_ddr4_dq[7]" ]
set_property IOSTANDARD POD12_DCI [ get_ports "c0_ddr4_dq[5]" ]
set_property IOSTANDARD POD12_DCI [ get_ports "c0_ddr4_dq[3]" ]
set_property IOSTANDARD POD12_DCI [ get_ports "c0_ddr4_dm_dbi_n[0]" ]
set_property IOSTANDARD SSTL12_DCI [ get_ports "c0_ddr4_adr[16]" ]
set_property IOSTANDARD SSTL12_DCI [ get_ports "c0_ddr4_adr[15]" ]
set_property IOSTANDARD SSTL12_DCI [ get_ports "c0_ddr4_adr[10]" ]
set_property IOSTANDARD SSTL12_DCI [ get_ports "c0_ddr4_adr[9]" ]
set_property IOSTANDARD DIFF_POD12_DCI [ get_ports "c0_ddr4_dqs_t[0]" ]
set_property IOSTANDARD SSTL12_DCI [ get_ports "c0_ddr4_odt[0]" ]
set_property IOSTANDARD DIFF_POD12_DCI [ get_ports "c0_ddr4_dqs_t[1]" ]
set_property IOSTANDARD POD12_DCI [ get_ports "c0_ddr4_dq[10]" ]
set_property IOSTANDARD LVCMOS12 [ get_ports "c0_ddr4_reset_n" ]
set_property DRIVE 8 [ get_ports "c0_ddr4_reset_n" ]

set_property IOSTANDARD SSTL12_DCI [ get_ports "c0_ddr4_adr[6]" ]
set_property IOSTANDARD DIFF_POD12_DCI [ get_ports "c0_ddr4_dqs_c[0]" ]
set_property IOSTANDARD POD12_DCI [ get_ports "c0_ddr4_dq[1]" ]
set_property IOSTANDARD POD12_DCI [ get_ports "c0_ddr4_dq[0]" ]
set_property IOSTANDARD POD12_DCI [ get_ports "c0_ddr4_dq[14]" ]
set_property IOSTANDARD DIFF_POD12_DCI [ get_ports "c0_ddr4_dqs_c[1]" ]
set_property IOSTANDARD POD12_DCI [ get_ports "c0_ddr4_dq[11]" ]
set_property IOSTANDARD SSTL12_DCI [ get_ports "c0_ddr4_adr[7]" ]
set_property IOSTANDARD DIFF_SSTL12 [ get_ports "c0_sys_clk_n" ]
set_property IOSTANDARD DIFF_SSTL12 [ get_ports "c0_sys_clk_p" ]
set_property IOSTANDARD SSTL12_DCI [ get_ports "c0_ddr4_adr[2]" ]
set_property IOSTANDARD POD12_DCI [ get_ports "c0_ddr4_dq[15]" ]
set_property IOSTANDARD POD12_DCI [ get_ports "c0_ddr4_dq[8]" ]
set_property IOSTANDARD POD12_DCI [ get_ports "c0_ddr4_dm_dbi_n[1]" ]
set_property IOSTANDARD DIFF_SSTL12_DCI [ get_ports "c0_ddr4_ck_c[0]" ]
set_property IOSTANDARD DIFF_SSTL12_DCI [ get_ports "c0_ddr4_ck_t[0]" ]
set_property IOSTANDARD SSTL12_DCI [ get_ports "c0_ddr4_adr[3]" ]
set_property IOSTANDARD SSTL12_DCI [ get_ports "c0_ddr4_adr[0]" ]
set_property IOSTANDARD POD12_DCI [ get_ports "c0_ddr4_dq[13]" ]
set_property IOSTANDARD POD12_DCI [ get_ports "c0_ddr4_dq[12]" ]
set_property IOSTANDARD POD12_DCI [ get_ports "c0_ddr4_dq[9]" ]
set_property IOSTANDARD SSTL12_DCI [ get_ports "c0_ddr4_act_n" ]
set_property IOSTANDARD SSTL12_DCI [ get_ports "c0_ddr4_adr[8]" ]
set_property IOSTANDARD SSTL12_DCI [ get_ports "c0_ddr4_adr[5]" ]
set_property IOSTANDARD SSTL12_DCI [ get_ports "c0_ddr4_adr[4]" ]
set_property IOSTANDARD SSTL12_DCI [ get_ports "c0_ddr4_adr[1]" ]


## These signals once asserted, stays asserted for multiple clock cycles.

## False path constraint is added to improve the HOLD timing.

set_false_path -hold -to [get_pins */*/*/*/*/*.u_xiphy_control/xiphy_control/RIU_ADDR*]
set_false_path -hold -to [get_pins */*/*/*/*/*.u_xiphy_control/xiphy_control/RIU_WR_DATA*]


set_property SLEW FAST  [get_ports {c0_ddr4_adr[*] c0_ddr4_act_n c0_ddr4_ba[*] c0_ddr4_bg[*] c0_ddr4_cke[*] c0_ddr4_ck_t[*] c0_ddr4_ck_c[*] c0_ddr4_odt[*] c0_ddr4_dq[*] c0_ddr4_dqs_t[*] c0_ddr4_dqs_c[*]}]
set_property IBUF_LOW_PWR FALSE  [get_ports {c0_ddr4_dq[*] c0_ddr4_dqs_t[*] c0_ddr4_dqs_c[*]}]
set_property ODT RTT_40  [get_ports {c0_ddr4_dq[*] c0_ddr4_dqs_t[*] c0_ddr4_dqs_c[*]}]
set_property EQUALIZATION EQ_LEVEL2 [get_ports {c0_ddr4_dq[*] c0_ddr4_dqs_t[*] c0_ddr4_dqs_c[*]}]
set_property PRE_EMPHASIS RDRV_240 [get_ports {c0_ddr4_dq[*] c0_ddr4_dqs_t[*] c0_ddr4_dqs_c[*]}]
set_property SLEW FAST  [get_ports {c0_ddr4_cs_n[*]}]
set_property DATA_RATE SDR  [get_ports {c0_ddr4_cs_n[*]}]
set_property SLEW FAST  [get_ports {c0_ddr4_dm_dbi_n[*]}]
set_property IBUF_LOW_PWR FALSE  [get_ports {c0_ddr4_dm_dbi_n[*]}]
set_property ODT RTT_40  [get_ports {c0_ddr4_dm_dbi_n[*]}]
set_property EQUALIZATION EQ_LEVEL2 [get_ports {c0_ddr4_dm_dbi_n[*]}]
set_property PRE_EMPHASIS RDRV_240 [get_ports {c0_ddr4_dm_dbi_n[*]}]
set_property DATA_RATE DDR [get_ports {c0_ddr4_dm_dbi_n[*]}]
set_property DATA_RATE SDR  [get_ports {c0_ddr4_adr[*] c0_ddr4_act_n c0_ddr4_ba[*] c0_ddr4_bg[*] c0_ddr4_cke[*] c0_ddr4_odt[*] }]
set_property DATA_RATE DDR  [get_ports {c0_ddr4_dq[*] c0_ddr4_dqs_t[*] c0_ddr4_dqs_c[*] c0_ddr4_ck_t[*] c0_ddr4_ck_c[*]}]
## Multi-cycle path constraints for Fabric - RIU clock domain crossing signals
set_max_delay 5.0 -datapath_only -from [get_pins */*/*/u_ddr_cal_addr_decode/io_ready_lvl_reg/C] -to [get_pins */u_io_ready_lvl_sync/SYNC[*].sync_reg_reg[0]/D]
set_max_delay 5.0 -datapath_only -from [get_pins */*/*/u_ddr_cal_addr_decode/io_read_data_reg[*]/C] -to [get_pins */u_io_read_data_sync/SYNC[*].sync_reg_reg[0]/D]
set_max_delay 3.0 -datapath_only -from [get_pins */*/*/phy_ready_riuclk_reg/C] -to [get_pins */u_phy2clb_phy_ready_sync/SYNC[*].sync_reg_reg[0]/D]
set_max_delay 3.0 -datapath_only -from [get_pins */*/*/bisc_complete_riuclk_reg/C] -to [get_pins */u_phy2clb_bisc_complete_sync/SYNC[*].sync_reg_reg[0]/D]
set_max_delay 3.0 -datapath_only -from [get_pins */*/io_addr_strobe_lvl_riuclk_reg/C] -to [get_pins */u_io_addr_strobe_lvl_sync/SYNC[*].sync_reg_reg[0]/D]
set_max_delay 3.0 -datapath_only -from [get_pins */*/io_write_strobe_riuclk_reg/C] -to [get_pins */u_io_write_strobe_sync/SYNC[*].sync_reg_reg[0]/D]
set_max_delay 3.0 -datapath_only -from [get_pins */*/io_address_riuclk_reg[*]/C] -to [get_pins */u_io_addr_sync/SYNC[*].sync_reg_reg[0]/D]
set_max_delay 3.0 -datapath_only -from [get_pins */*/io_write_data_riuclk_reg[*]/C] -to [get_pins */u_io_write_data_sync/SYNC[*].sync_reg_reg[0]/D]
set_max_delay 10.0 -datapath_only -from [get_pins */en_vtc_in_reg/C] -to [get_pins */u_en_vtc_sync/SYNC[*].sync_reg_reg[0]/D]
set_max_delay 10.0 -datapath_only -from [get_pins */*/riu2clb_valid_r1_riuclk_reg[*]/C] -to [get_pins */u_riu2clb_valid_sync/SYNC[*].sync_reg_reg[0]/D]
set_max_delay 10.0 -datapath_only -from [get_pins */*/*/phy2clb_fixdly_rdy_low_riuclk_int_reg[*]/C] -to [get_pins */u_phy2clb_fixdly_rdy_low/SYNC[*].sync_reg_reg[0]/D]
set_max_delay 10.0 -datapath_only -from [get_pins */*/*/phy2clb_fixdly_rdy_upp_riuclk_int_reg[*]/C] -to [get_pins */u_phy2clb_fixdly_rdy_upp/SYNC[*].sync_reg_reg[0]/D]
set_max_delay 10.0 -datapath_only -from [get_pins */*/*/phy2clb_phy_rdy_low_riuclk_int_reg[*]/C] -to [get_pins */u_phy2clb_phy_rdy_low/SYNC[*].sync_reg_reg[0]/D]
set_max_delay 10.0 -datapath_only -from [get_pins */*/*/phy2clb_phy_rdy_upp_riuclk_int_reg[*]/C] -to [get_pins */u_phy2clb_phy_rdy_upp/SYNC[*].sync_reg_reg[0]/D]
set_max_delay 10.0 -datapath_only -from [get_pins */rst_r1_reg/C] -to [get_pins */u_fab_rst_sync/SYNC[*].sync_reg_reg[0]/D]
set_max_delay 3.0 -datapath_only -from [get_pins  */*/*/clb2phy_t_b_addr_riuclk_reg/C] -to [get_pins  */*/*/clb2phy_t_b_addr_i_reg[0]/D]
set_max_delay 3.0 -datapath_only -from [get_pins  */*/*/*/slave_en_lvl_reg/C] -to [get_pins  */*/*/*/u_slave_en_sync/SYNC[*].sync_reg_reg[0]/D]
set_max_delay 3.0 -datapath_only -from [get_pins  */*/*/*/slave_we_r_reg/C] -to [get_pins  */*/*/*/u_slave_we_sync/SYNC[*].sync_reg_reg[0]/D]
set_max_delay 3.0 -datapath_only -from [get_pins  */*/*/*/slave_addr_r_reg[*]/C] -to [get_pins  */*/*/*/u_slave_addr_sync/SYNC[*].sync_reg_reg[0]/D]
set_max_delay 3.0 -datapath_only -from [get_pins  */*/*/*/slave_di_r_reg[*]/C] -to [get_pins  */*/*/*/u_slave_di_sync/SYNC[*].sync_reg_reg[0]/D]
set_max_delay 3.0 -datapath_only -from [get_pins  */*/*/*/slave_rdy_cptd_sclk_reg/C] -to [get_pins  */*/*/*/u_slave_rdy_cptd_sync/SYNC[*].sync_reg_reg[0]/D]
set_max_delay 12.0 -datapath_only -from [get_pins */*/*/*/slave_rdy_lvl_fclk_reg/C] -to [get_pins  */*/*/*/u_slave_rdy_sync/SYNC[*].sync_reg_reg[0]/D]
set_max_delay 12.0 -datapath_only -from [get_pins */*/*/*/slave_do_fclk_reg[*]/C] -to [get_pins  */*/*/*/u_slave_do_sync/SYNC[*].sync_reg_reg[0]/D]
set_false_path -through [get_pins u_ddr4_infrastructure/sys_rst]
set_false_path -from [get_pins  */input_rst_design_reg/C] -to [get_pins */rst_div_sync_r_reg[0]/D]
set_false_path -from [get_pins  */input_rst_design_reg/C] -to [get_pins */rst_riu_sync_r_reg[0]/D]
set_false_path -from [get_pins  */input_rst_design_reg/C] -to [get_pins */rst_mb_sync_r_reg[0]/D]
set_false_path -from [get_pins  */rst_async_riu_div_reg/C] -to [get_pins */rst_div_sync_r_reg[0]/D]
set_false_path -from [get_pins  */rst_async_mb_reg/C]      -to [get_pins */rst_mb_sync_r_reg[0]/D]
set_false_path -from [get_pins  */rst_async_riu_div_reg/C] -to [get_pins */rst_riu_sync_r_reg[0]/D]
create_waiver -internal -user DDR4 -tags "1010162" -scope -type METHODOLOGY -id CLKC-55 -description "Clocking Primitives will be Auto-Placed" -objects [get_cells -hierarchical "*gen_mmcme*.u_mmcme_adv_inst*" -filter {NAME =~ *inst/u_ddr4_infrastructure*}]
create_waiver -internal -user DDR4 -tags "1010162" -scope -type METHODOLOGY -id CLKC-56 -description "Clocking Primitives will be Auto-Placed" -objects [get_cells -hierarchical "*gen_mmcme*.u_mmcme_adv_inst*" -filter {NAME =~ *inst/u_ddr4_infrastructure*}]
create_waiver -internal -user DDR4 -tags "1010162" -scope -type METHODOLOGY -id CLKC-57 -description "Clocking Primitives will be Auto-Placed" -objects [get_cells -hierarchical "*plle_loop[*].gen_plle*.PLLE*_BASE_INST_OTHER*" -filter {NAME =~ *inst/u_ddr4_phy_pll*}]
create_waiver -internal -user DDR4 -tags "1010162" -scope -type METHODOLOGY -id CLKC-58 -description "Clocking Primitives will be Auto-Placed" -objects [get_cells -hierarchical "*plle_loop[*].gen_plle*.PLLE*_BASE_INST_OTHER*" -filter {NAME =~ *inst/u_ddr4_phy_pll*}]
create_waiver -internal -user DDR4 -tags "1010162" -scope -type METHODOLOGY -id CLKC-40 -description "MMCM is driven through a BUFGCE" -objects [get_cells -hierarchical "*gen_mmcme*.u_mmcme_adv_inst*" -filter {NAME =~ *inst/u_ddr4_infrastructure*}]
## These below commands are used to create Interface ports for controller.

create_interface -quiet interface_Mercury_XU5_ddr4_0
set_property interface interface_Mercury_XU5_ddr4_0 [get_ports [list {c0_ddr4_bg[0]} {c0_ddr4_ba[0]} {c0_ddr4_adr[14]} {c0_ddr4_adr[13]} {c0_ddr4_cke[0]} {c0_ddr4_dq[6]} {c0_ddr4_dq[4]} {c0_ddr4_dq[2]} {c0_ddr4_cs_n[0]} {c0_ddr4_ba[1]} {c0_ddr4_adr[12]} {c0_ddr4_adr[11]} {c0_ddr4_dq[7]} {c0_ddr4_dq[5]} {c0_ddr4_dq[3]} {c0_ddr4_dm_dbi_n[0]} {c0_ddr4_adr[16]} {c0_ddr4_adr[15]} {c0_ddr4_adr[10]} {c0_ddr4_adr[9]} {c0_ddr4_dqs_t[0]} {c0_ddr4_odt[0]} {c0_ddr4_dqs_t[1]} {c0_ddr4_dq[10]} c0_ddr4_reset_n {c0_ddr4_adr[6]} {c0_ddr4_dqs_c[0]} {c0_ddr4_dq[1]} {c0_ddr4_dq[0]} {c0_ddr4_dq[14]} {c0_ddr4_dqs_c[1]} {c0_ddr4_dq[11]} {c0_ddr4_adr[7]} c0_sys_clk_n c0_sys_clk_p {c0_ddr4_adr[2]} {c0_ddr4_dq[15]} {c0_ddr4_dq[8]} {c0_ddr4_dm_dbi_n[1]} {c0_ddr4_ck_c[0]} {c0_ddr4_ck_t[0]} {c0_ddr4_adr[3]} {c0_ddr4_adr[0]} {c0_ddr4_dq[13]} {c0_ddr4_dq[12]} {c0_ddr4_dq[9]} c0_ddr4_act_n {c0_ddr4_adr[8]} {c0_ddr4_adr[5]} {c0_ddr4_adr[4]} {c0_ddr4_adr[1]}]]


# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_0/par/Mercury_XU5_ddr4_0.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_clk_wiz_gmii2rgmii_0/Mercury_XU5_clk_wiz_gmii2rgmii_0_board.xdc
# ==========================================================
#--------------------Physical Constraints-----------------



# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_clk_wiz_gmii2rgmii_0/Mercury_XU5_clk_wiz_gmii2rgmii_0_board.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_clk_wiz_gmii2rgmii_0/Mercury_XU5_clk_wiz_gmii2rgmii_0.xdc
# ==========================================================

# file: Mercury_XU5_clk_wiz_gmii2rgmii_0.xdc
# (c) Copyright 2017-2018, 2023 Advanced Micro Devices, Inc. All rights reserved.
#
# This file contains confidential and proprietary information
# of AMD and is protected under U.S. and international copyright
# and other intellectual property laws.
#
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# AMD, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) AMD shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or AMD had been advised of the
# possibility of the same.
#
# CRITICAL APPLICATIONS
# AMD products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of AMD products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
#
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.

# Input clock periods. These duplicate the values entered for the
# input clocks. You can use these to time your system. If required
# commented constraints can be used in the top level xdc 
#----------------------------------------------------------------
#create_clock -period 20.000 [get_ports clk_in1]
#set_input_jitter [get_clocks -of_objects [get_ports clk_in1]] 0.2


set_property PHASESHIFT_MODE LATENCY [get_cells -hierarchical *adv*]


# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_clk_wiz_gmii2rgmii_0/Mercury_XU5_clk_wiz_gmii2rgmii_0.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_clk_wiz_gmii2rgmii_0/Mercury_XU5_clk_wiz_gmii2rgmii_0_late.xdc
# ==========================================================

# file: Mercury_XU5_clk_wiz_gmii2rgmii_0_late.xdc
# (c) Copyright 2017-2018, 2023 Advanced Micro Devices, Inc. All rights reserved.
#
# This file contains confidential and proprietary information
# of AMD and is protected under U.S. and international copyright
# and other intellectual property laws.
#
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# AMD, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) AMD shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or AMD had been advised of the
# possibility of the same.
#
# CRITICAL APPLICATIONS
# AMD products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of AMD products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
#
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.






# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_clk_wiz_gmii2rgmii_0/Mercury_XU5_clk_wiz_gmii2rgmii_0_late.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_clk_wiz_gmii2rgmii_0/Mercury_XU5_clk_wiz_gmii2rgmii_0_ooc.xdc
# ==========================================================

# file: Mercury_XU5_clk_wiz_gmii2rgmii_0_ooc.xdc
# (c) Copyright 2017-2018, 2023 Advanced Micro Devices, Inc. All rights reserved.
#
# This file contains confidential and proprietary information
# of AMD and is protected under U.S. and international copyright
# and other intellectual property laws.
#
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# AMD, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) AMD shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or AMD had been advised of the
# possibility of the same.
#
# CRITICAL APPLICATIONS
# AMD products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of AMD products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
#
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.

#################
#DEFAULT CLOCK CONSTRAINTS

############################################################
# Clock Period Constraints                                 #
############################################################
create_clock -period 20.000 [get_ports clk_in1]
#set_property HD.CLK_SRC BUFGCTRL_X0Y0 [get_ports clk_in1]



# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_clk_wiz_gmii2rgmii_0/Mercury_XU5_clk_wiz_gmii2rgmii_0_ooc.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ps_sys_rst_0/Mercury_XU5_ps_sys_rst_0_board.xdc
# ==========================================================
#--------------------Physical Constraints-----------------



# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ps_sys_rst_0/Mercury_XU5_ps_sys_rst_0_board.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ps_sys_rst_0/Mercury_XU5_ps_sys_rst_0_ooc.xdc
# ==========================================================
# (c) Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
# (c) Copyright 2022-2026 Advanced Micro Devices, Inc. All rights reserved.
# 
# This file contains confidential and proprietary information
# of AMD and is protected under U.S. and international copyright
# and other intellectual property laws.
# 
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# AMD, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) AMD shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or AMD had been advised of the
# possibility of the same.
# 
# CRITICAL APPLICATIONS
# AMD products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of AMD products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
# 
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.
# 
# DO NOT MODIFY THIS FILE.
# #########################################################
#
# This XDC is used only in OOC mode for synthesis, implementation
#
# #########################################################


create_clock -period 10 -name slowest_sync_clk [get_ports slowest_sync_clk]




# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ps_sys_rst_0/Mercury_XU5_ps_sys_rst_0_ooc.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_sys_rst_0/Mercury_XU5_ddr4_sys_rst_0_board.xdc
# ==========================================================
#--------------------Physical Constraints-----------------



# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_sys_rst_0/Mercury_XU5_ddr4_sys_rst_0_board.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_sys_rst_0/Mercury_XU5_ddr4_sys_rst_0_ooc.xdc
# ==========================================================
# (c) Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
# (c) Copyright 2022-2026 Advanced Micro Devices, Inc. All rights reserved.
# 
# This file contains confidential and proprietary information
# of AMD and is protected under U.S. and international copyright
# and other intellectual property laws.
# 
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# AMD, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) AMD shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or AMD had been advised of the
# possibility of the same.
# 
# CRITICAL APPLICATIONS
# AMD products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of AMD products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
# 
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.
# 
# DO NOT MODIFY THIS FILE.
# #########################################################
#
# This XDC is used only in OOC mode for synthesis, implementation
#
# #########################################################


create_clock -period 3.333 -name slowest_sync_clk [get_ports slowest_sync_clk]




# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ddr4_sys_rst_0/Mercury_XU5_ddr4_sys_rst_0_ooc.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_smartconnect_00_0/ooc.xdc
# ==========================================================
# aclk {FREQ_HZ 100000000 CLK_DOMAIN Mercury_XU5_zynq_ultra_ps_e_0_pl_clk0 PHASE 0.0}
# Clock Domain: Mercury_XU5_zynq_ultra_ps_e_0_pl_clk0
create_clock -name aclk -period 10.000 [get_ports aclk]
# Generated clocks


# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_smartconnect_00_0/ooc.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_smartconnect_00_0/smartconnect.xdc
# ==========================================================
# -----------------------SMC Waivers--------------------


# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_smartconnect_00_0/smartconnect.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_axi_dma_cmd_0/Mercury_XU5_axi_dma_cmd_0.xdc
# ==========================================================
# file: Mercury_XU5_axi_dma_cmd_0.xdc
# (c) Copyright 2009 - 2023 Advanced Micro Devices, Inc. All rights reserved.
# 
# This file contains confidential and proprietary information
# of Advanced Micro Devices, Inc. and is protected under U.S. and
# international copyright and other intellectual property
# laws.
# 
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# AMD, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) AMD shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or AMD had been advised of the
# possibility of the same.
# 
# CRITICAL APPLICATIONS
# AMD products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of AMD products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
# 
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.

## INFO: Level CDC Crossing in AXI DMA






# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_axi_dma_cmd_0/Mercury_XU5_axi_dma_cmd_0.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_axi_dma_cmd_0/Mercury_XU5_axi_dma_cmd_0_clocks.xdc
# ==========================================================
# file: Mercury_XU5_axi_dma_cmd_0.xdc
# (c) Copyright 2009 - 2023 Advanced Micro Devices, Inc. All rights reserved.
# 
# This file contains confidential and proprietary information
# of Advanced Micro Devices, Inc. and is protected under U.S. and
# international copyright and other intellectual property
# laws.
# 
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# AMD, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) AMD shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or AMD had been advised of the
# possibility of the same.
# 
# CRITICAL APPLICATIONS
# AMD products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of AMD products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
# 
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.


# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_axi_dma_cmd_0/Mercury_XU5_axi_dma_cmd_0_clocks.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_axi_dma_cmd_0/Mercury_XU5_axi_dma_cmd_0_ooc.xdc
# ==========================================================
# (c) Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
# (c) Copyright 2022-2026 Advanced Micro Devices, Inc. All rights reserved.
# 
# This file contains confidential and proprietary information
# of AMD and is protected under U.S. and international copyright
# and other intellectual property laws.
# 
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# AMD, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) AMD shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or AMD had been advised of the
# possibility of the same.
# 
# CRITICAL APPLICATIONS
# AMD products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of AMD products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
# 
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.
# 
# DO NOT MODIFY THIS FILE.
# #########################################################
#
# This XDC is used only in OOC mode for synthesis, implementation
#
# #########################################################


create_clock -period 10 -name m_axi_mm2s_aclk [get_ports m_axi_mm2s_aclk]

create_clock -period 10 -name s_axi_lite_aclk [get_ports s_axi_lite_aclk]




# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_axi_dma_cmd_0/Mercury_XU5_axi_dma_cmd_0_ooc.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_axis_dwidth_cmd_0/Mercury_XU5_axis_dwidth_cmd_0_ooc.xdc
# ==========================================================
# (c) Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
# (c) Copyright 2022-2026 Advanced Micro Devices, Inc. All rights reserved.
# 
# This file contains confidential and proprietary information
# of AMD and is protected under U.S. and international copyright
# and other intellectual property laws.
# 
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# AMD, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) AMD shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or AMD had been advised of the
# possibility of the same.
# 
# CRITICAL APPLICATIONS
# AMD products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of AMD products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
# 
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.
# 
# DO NOT MODIFY THIS FILE.
# #########################################################
#
# This XDC is used only in OOC mode for synthesis, implementation
#
# #########################################################


create_clock -period 10 -name aclk [get_ports aclk]




# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_axis_dwidth_cmd_0/Mercury_XU5_axis_dwidth_cmd_0_ooc.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_axis_fifo_cmd_0/Mercury_XU5_axis_fifo_cmd_0_ooc.xdc
# ==========================================================
# (c) Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
# (c) Copyright 2022-2026 Advanced Micro Devices, Inc. All rights reserved.
# 
# This file contains confidential and proprietary information
# of AMD and is protected under U.S. and international copyright
# and other intellectual property laws.
# 
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# AMD, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) AMD shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or AMD had been advised of the
# possibility of the same.
# 
# CRITICAL APPLICATIONS
# AMD products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of AMD products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
# 
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.
# 
# DO NOT MODIFY THIS FILE.
# #########################################################
#
# This XDC is used only in OOC mode for synthesis, implementation
#
# #########################################################


create_clock -period 10 -name s_axis_aclk [get_ports s_axis_aclk]




# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_axis_fifo_cmd_0/Mercury_XU5_axis_fifo_cmd_0_ooc.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_cmd_smartconnect_data_0/ooc.xdc
# ==========================================================
# aclk {FREQ_HZ 100000000 CLK_DOMAIN Mercury_XU5_zynq_ultra_ps_e_0_pl_clk0 PHASE 0.0}
# Clock Domain: Mercury_XU5_zynq_ultra_ps_e_0_pl_clk0
create_clock -name aclk -period 10.000 [get_ports aclk]
# Generated clocks


# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_cmd_smartconnect_data_0/ooc.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_cmd_smartconnect_data_0/smartconnect.xdc
# ==========================================================
# -----------------------SMC Waivers--------------------


# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_cmd_smartconnect_data_0/smartconnect.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_axi_dma_tm_0/Mercury_XU5_axi_dma_tm_0.xdc
# ==========================================================
# file: Mercury_XU5_axi_dma_tm_0.xdc
# (c) Copyright 2009 - 2023 Advanced Micro Devices, Inc. All rights reserved.
# 
# This file contains confidential and proprietary information
# of Advanced Micro Devices, Inc. and is protected under U.S. and
# international copyright and other intellectual property
# laws.
# 
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# AMD, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) AMD shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or AMD had been advised of the
# possibility of the same.
# 
# CRITICAL APPLICATIONS
# AMD products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of AMD products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
# 
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.

## INFO: Level CDC Crossing in AXI DMA






# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_axi_dma_tm_0/Mercury_XU5_axi_dma_tm_0.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_axi_dma_tm_0/Mercury_XU5_axi_dma_tm_0_clocks.xdc
# ==========================================================
# file: Mercury_XU5_axi_dma_tm_0.xdc
# (c) Copyright 2009 - 2023 Advanced Micro Devices, Inc. All rights reserved.
# 
# This file contains confidential and proprietary information
# of Advanced Micro Devices, Inc. and is protected under U.S. and
# international copyright and other intellectual property
# laws.
# 
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# AMD, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) AMD shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or AMD had been advised of the
# possibility of the same.
# 
# CRITICAL APPLICATIONS
# AMD products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of AMD products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
# 
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.


# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_axi_dma_tm_0/Mercury_XU5_axi_dma_tm_0_clocks.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_axi_dma_tm_0/Mercury_XU5_axi_dma_tm_0_ooc.xdc
# ==========================================================
# (c) Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
# (c) Copyright 2022-2026 Advanced Micro Devices, Inc. All rights reserved.
# 
# This file contains confidential and proprietary information
# of AMD and is protected under U.S. and international copyright
# and other intellectual property laws.
# 
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# AMD, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) AMD shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or AMD had been advised of the
# possibility of the same.
# 
# CRITICAL APPLICATIONS
# AMD products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of AMD products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
# 
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.
# 
# DO NOT MODIFY THIS FILE.
# #########################################################
#
# This XDC is used only in OOC mode for synthesis, implementation
#
# #########################################################


create_clock -period 10 -name m_axi_s2mm_aclk [get_ports m_axi_s2mm_aclk]

create_clock -period 10 -name s_axi_lite_aclk [get_ports s_axi_lite_aclk]




# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_axi_dma_tm_0/Mercury_XU5_axi_dma_tm_0_ooc.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ila_adc3_tm_debug_0/ila_v6_2/constraints/ila_impl.xdc
# ==========================================================
##
## Match Unit Configuration to Match Output false path
##

set_false_path -from [get_pins -filter {REF_PIN_NAME=~CLK*} -of_objects [get_cells -hierarchical -filter {NAME =~ "*allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/I_WHOLE_SLICE.G_SLICE_IDX[*].U_ALL_SRL_SLICE/u_srl*/S*"}]] -to [get_pins -filter {REF_PIN_NAME=~D*} -of_objects [get_cells -hierarchical -filter {NAME =~ "*allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/I_WHOLE_SLICE.G_SLICE_IDX[*].U_ALL_SRL_SLICE/I_IS_TERMINATION_SLICE_W_OUTPUT_REG.DOUT_O_reg*"}]]

##
## ILA Sample Counter Match Condition out False Paths
##
set_false_path -from [get_pins -filter {REF_PIN_NAME=~CLK*} -of_objects [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/u_scnt_cmp/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/I_WHOLE_SLICE.G_SLICE_IDX[*].U_ALL_SRL_SLICE/u_srl*/S*"}]] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/u_scnt_cmp_q*" && IS_SEQUENTIAL } ]

##
## ILA Window Counter Match Condition out False Paths
##
set_false_path -from [get_pins -filter {REF_PIN_NAME=~CLK*} -of_objects [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_lcmp/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/I_WHOLE_SLICE.G_SLICE_IDX[*].U_ALL_SRL_SLICE/u_srl*/S*"}]] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_lcmp_q*" && IS_SEQUENTIAL } ]
set_false_path -from [get_pins -filter {REF_PIN_NAME=~CLK*} -of_objects [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_hcmp/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/I_WHOLE_SLICE.G_SLICE_IDX[*].U_ALL_SRL_SLICE/u_srl*/S*"}]] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_hcmp_q*" && IS_SEQUENTIAL } ]


create_waiver -internal -scope -type CDC -id CDC-1 -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter {NAME =~ "*u_ila_cap_ctrl/U_CDONE/I_YESLUT6.U_SRL32_*"}]]  -to [get_pins -filter {REF_PIN_NAME=~D} -of_objects [get_cells -hierarchical -filter {NAME =~ "*u_ila_cap_ctrl/U_CDONE/I_YESLUT6.I_YES_OREG.O_reg_reg*"}]]  -tags "1037291" -user "xsdbm" -description {CDC is handled through handshake process} 
create_waiver -internal -scope -type CDC -id CDC-1 -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter {NAME =~ "*u_ila_cap_ctrl/U_NS1/I_YESLUT6.U_SRL32_*"}]]  -to [get_pins -filter {REF_PIN_NAME=~D} -of_objects [get_cells -hierarchical -filter {NAME =~ "*u_ila_cap_ctrl/U_NS1/I_YESLUT6.I_YES_OREG.O_reg_reg*"}]]  -tags "1037291" -user "xsdbm" -description {CDC is handled through handshake process} 
create_waiver -internal -scope -type CDC -id CDC-1 -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter {NAME =~ "*u_ila_cap_ctrl/U_NS0/I_YESLUT6.U_SRL32_*"}]]  -to [get_pins -filter {REF_PIN_NAME=~D} -of_objects [get_cells -hierarchical -filter {NAME =~ "*u_ila_cap_ctrl/U_NS0/I_YESLUT6.I_YES_OREG.O_reg_reg*"}]]  -tags "1037291" -user "xsdbm" -description {CDC is handled through handshake process} 
create_waiver -internal -scope -type CDC -id CDC-1 -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter {NAME =~ "*u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/U_WCE/I_YESLUT6.U_SRLC16E*"}]]  -to [get_pins -filter {REF_PIN_NAME=~CE} -of_objects [get_cells -hierarchical -filter {NAME =~ "*u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/iwcnt_reg[*]*"}]] -tags "1037291" -user "xsdbm" -description {CDC is handled through handshake process} 
create_waiver -internal -scope -type CDC -id CDC-1 -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter {NAME =~ "*u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/U_SCE/I_YESLUT6.U_SRLC16E*"}]]  -to [get_pins -filter {REF_PIN_NAME=~CE} -of_objects [get_cells -hierarchical -filter {NAME =~ "*u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/iscnt_reg[*]*"}]] -tags "1037291" -user "xsdbm" -description {CDC is handled through handshake process} 
create_waiver -internal -scope -type CDC -id CDC-1 -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter {NAME =~ "*u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/U_SCMPCE/I_YESLUT6.U_SRL32*"}]]  -to [get_pins -filter {REF_PIN_NAME=~CE} -of_objects [get_cells -hierarchical -filter {NAME =~ "*u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/u_scnt_cmp_q*"}]]  -tags "1037291" -user "xsdbm" -description {CDC is handled through handshake process}
create_waiver -internal -scope -type CDC -id CDC-1 -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter {NAME =~ "*u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/U_WHCMPCE/I_YESLUT6.U_SRL32*"}]]  -to [get_pins -filter {REF_PIN_NAME=~CE} -of_objects [get_cells -hierarchical -filter {NAME =~ "*u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_hcmp_q*"}]]  -tags "1037291" -user "xsdbm" -description {CDC is handled through handshake process}
create_waiver -internal -scope -type CDC -id CDC-1 -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter {NAME =~ "*u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/U_WLCMPCE/I_YESLUT6.U_SRL32*"}]]  -to [get_pins -filter {REF_PIN_NAME=~CE} -of_objects [get_cells -hierarchical -filter {NAME =~ "*u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_lcmp_q*"}]]  -tags "1037291" -user "xsdbm" -description {CDC is handled through handshake process}
create_waiver -internal -scope -type CDC -id CDC-10 -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter {NAME =~ "*allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/I_WHOLE_SLICE.G_SLICE_IDX[*].U_ALL_SRL_SLICE/u_srl*/S*"}]]  -to [get_pins -filter {REF_PIN_NAME=~D} -of_objects [get_cells -hierarchical -filter {NAME =~ "*allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/I_WHOLE_SLICE.G_SLICE_IDX[*].U_ALL_SRL_SLICE/I_IS_TERMINATION_SLICE_W_OUTPUT_REG.DOUT_O_reg*"}]]  -tags "1037291" -user "xsdbm" -description {CDC is handled through handshake process}
#create_waiver -internal -scope -type CDC -id CDC-10 -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter {NAME =~ "*u_trig/N_DDR_TC.N_DDR_TC_INST[*].U_TC/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/I_WHOLE_SLICE.G_SLICE_IDX[*].U_ALL_SRL_SLICE/u_srlD/S1*"}]]  -to [get_pins -filter {REF_PIN_NAME=~D} -of_objects [get_cells -hierarchical -filter {NAME =~ "*u_trig/N_DDR_TC.N_DDR_TC_INST[*].U_TC/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/I_WHOLE_SLICE.G_SLICE_IDX[*].U_ALL_SRL_SLICE/I_IS_TERMINATION_SLICE_W_OUTPUT_REG.DOUT_O_reg*"}]]  -tags "1037291" -user "xsdbm" -description {CDC is handled through handshake process}
create_waiver -internal -scope -type CDC -id CDC-10 -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter {NAME =~ "*u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/U_SCE/I_YESLUT6.U_SRLC16E*"}]]  -to [get_pins -filter {REF_PIN_NAME=~D} -of_objects [get_cells -hierarchical -filter {NAME =~ "*u_ila_cap_ctrl/u_cap_addrgen/icap_wr_en_reg*"}]]  -tags "1037291" -user "xsdbm" -description {CDC is handled through handshake process}

create_waiver -internal -type CDC -id {CDC-10} -user ila -tags "1191969" -description "CDC-10 waiver for DDR Calibration logic" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*CLK} -of_objects [get_cells -hierarchical -filter {NAME =~*u_trig/N_DDR_TC.N_DDR_TC_INST[*].U_TC/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/u_srl_drive}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*u_trig/N_DDR_TC.N_DDR_TC_INST[*].U_TC/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/I_IS_TERMINATION_SLICE_W_OUTPUT_REG.DOUT_O_reg}]]

#create_waiver -internal -type CDC -id {CDC-10} -user system_ila -tags "1196835" -description "CDC-10 waiver for DDR Calibration logic" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*CLK} -of_objects [get_cells -hierarchical -filter {NAME =~*u_trig/N_DDR_TC.N_DDR_TC_INST[*].U_TC/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/u_srl_drive}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*u_trig/N_DDR_TC.N_DDR_TC_INST[*].U_TC/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/I_WHOLE_SLICE.G_SLICE_IDX[*].U_ALL_SRL_SLICE/I_IS_TERMINATION_SLICE_W_OUTPUT_REG.DOUT_O_reg}]]


# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ila_adc3_tm_debug_0/ila_v6_2/constraints/ila_impl.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ila_adc3_tm_debug_0/ila_v6_2/constraints/ila.xdc
# ==========================================================
##
## ARM and HALT transfer false paths
##
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_reset_ctrl/asyncrounous_transfer*/din_reg_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_reset_ctrl/asyncrounous_transfer*/dout_reg0_reg*" && IS_SEQUENTIAL } ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_reset_ctrl/asyncrounous_transfer.arm_in_transfer_inst/dout_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_reset_ctrl/asyncrounous_transfer.arm_in_transfer_inst/temp_reg0_reg*" && IS_SEQUENTIAL } ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_reset_ctrl/asyncrounous_transfer.halt_in_transfer_inst/dout_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_reset_ctrl/asyncrounous_transfer.halt_in_transfer_inst/temp_reg0_reg*" && IS_SEQUENTIAL } ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_reset_ctrl/asyncrounous_transfer.halt_out_transfer_inst/dout_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_reset_ctrl/asyncrounous_transfer.halt_out_transfer_inst/temp_reg0_reg*" && IS_SEQUENTIAL } ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_reset_ctrl/asyncrounous_transfer.arm_out_transfer_inst/dout_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_reset_ctrl/asyncrounous_transfer.arm_out_transfer_inst/temp_reg0_reg*" && IS_SEQUENTIAL } ]

##
## ILA Register False Paths
##
#set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg*" && IS_SEQUENTIAL } ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/reg_1a/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/iscnt_reg*" && IS_SEQUENTIAL } ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/reg_1a/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/iwcnt_reg*" && IS_SEQUENTIAL } ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/reg_1a/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_hcmp_q*" && IS_SEQUENTIAL } ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/reg_1a/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_lcmp_q*" && IS_SEQUENTIAL } ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/reg_1a/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/u_scnt_cmp_q*" && IS_SEQUENTIAL } ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/reg_7/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_hcmp_q*" && IS_SEQUENTIAL } ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/reg_7/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_lcmp_q*" && IS_SEQUENTIAL } ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/reg_7/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/u_scnt_cmp_q*" && IS_SEQUENTIAL } ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/reg_1a/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_cap_ctrl/U_CDONE/I_YESLUT6.I_YES_OREG.O_reg*" && IS_SEQUENTIAL} ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/reg_1a/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_cap_ctrl/U_NS0/I_YESLUT6.I_YES_OREG.O_reg*" && IS_SEQUENTIAL} ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/reg_1a/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_cap_ctrl/U_NS1/I_YESLUT6.I_YES_OREG.O_reg*" && IS_SEQUENTIAL} ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/reg_1a/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/icap_wr_en_reg*" && IS_SEQUENTIAL} ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/reg_1a/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_cap_ctrl/itrigger_out_reg*" && IS_SEQUENTIAL} ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/reg_15/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/use_probe_debug_circuit_2_reg*" && IS_SEQUENTIAL} ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/reg_15/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/en_adv_trigger_2_reg*" && IS_SEQUENTIAL} ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/reg_1a/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/en_adv_trigger_2_reg*" && IS_SEQUENTIAL} ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/reg_1a/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/capture_qual_ctrl_2_reg*" && IS_SEQUENTIAL} ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/reg_stream_ffd/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/debug_data_in_sync1_reg*" && IS_SEQUENTIAL} ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/*.cfg_data_vec_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/cfg_data_vec_sync1_reg*" && IS_SEQUENTIAL} ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/s_dclk_flag_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_regs/s_dclk_flag_sync1_reg*" && IS_SEQUENTIAL} ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/ila_clk_flag_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_regs/ila_clk_flag_sync1_reg*" && IS_SEQUENTIAL} ]
#set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/s_dclk_flag_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_regs/next_state_ila_reg*" && IS_SEQUENTIAL} ]
#set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/s_dclk_flag_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_regs/ila_clk_flag_reg*" && IS_SEQUENTIAL} ]
#set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/ila_clk_flag_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_regs/s_dclk_flag_reg*" && IS_SEQUENTIAL} ]
#set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/ila_clk_flag_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_regs/clk_lost_reg*" && IS_SEQUENTIAL} ]
#set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/ila_clk_flag_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_regs/next_state_xsdb_reg*" && IS_SEQUENTIAL} ]
#set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/ila_clk_flag_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_regs/clk_lost_cnt_reg[*]*" && IS_SEQUENTIAL} ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_regs/reg_stream_ffd/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg*" && IS_SEQUENTIAL} ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_trig/U_TM/N_DDR_MODE.G_NMU[*].U_M/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/probeDelay1_reg*" && IS_SEQUENTIAL} ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/reg_15/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_trig/U_TM/N_DDR_MODE.G_NMU[*].U_M/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/probeDelay1_reg*" && IS_SEQUENTIAL} ]

##
## Match Unit Configuration to Match Output false path
##
set_false_path -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter {NAME =~ "*allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/u_srl_drive*"}]] -to [get_pins -filter {REF_PIN_NAME=~D} -of_objects [get_cells -hierarchical -filter {NAME =~ "*allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/I_WHOLE_SLICE.G_SLICE_IDX[*].U_ALL_SRL_SLICE/I_IS_TERMINATION_SLICE_W_OUTPUT_REG.DOUT_O_reg*" && IS_SEQUENTIAL}]]
#set_false_path -from [get_pins -hierarchical -filter {NAME =~ *allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/I_WHOLE_SLICE.G_SLICE_IDX[*].U_ALL_SRL_SLICE/u_srl*/S*/CLK}] -to [get_pins -hierarchical -filter {NAME =~ *allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/I_WHOLE_SLICE.G_SLICE_IDX[*].U_ALL_SRL_SLICE/I_IS_TERMINATION_SLICE_W_OUTPUT_REG.DOUT_O_reg/D}]

##
## ILA Capture Block False Paths
##

set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/*cfg_data_vec_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/*icap_addr_reg*" && IS_SEQUENTIAL } ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/captured_samples*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/reg*/I_EN_STAT_EQ1.U_STAT/xsdb_reg*" && IS_SEQUENTIAL } ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/CAP_DONE_O*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/reg*/I_EN_STAT_EQ1.U_STAT/xsdb_reg*" && IS_SEQUENTIAL } ]
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/CAP_TRIGGER_O*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/reg*/I_EN_STAT_EQ1.U_STAT/xsdb_reg*" && IS_SEQUENTIAL } ]

##
## ILA Capture State to XSDB register False Paths
##
set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/U_NS*/I_YESLUT6.I_YES_OREG.O_reg_reg*" && IS_SEQUENTIAL } ] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_regs/reg_*/I_EN_STAT_EQ1.U_STAT/xsdb_reg_reg[*]*" && IS_SEQUENTIAL } ]

##
## ILA Sample Counter Match Condition out False Paths
##
set_false_path -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/U_SCMPCE/I_YESLUT6.U_SRL32*"}]] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/u_scnt_cmp_q*" && IS_SEQUENTIAL } ]
set_false_path -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/u_scnt_cmp/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/u_srl_drive*"}]] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/u_scnt_cmp_q*" && IS_SEQUENTIAL } ]
#set_false_path -from [get_pins -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/u_scnt_cmp/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/I_WHOLE_SLICE.G_SLICE_IDX[*].U_ALL_SRL_SLICE/u_srl*/S*/CLK*"}] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/u_scnt_cmp_q*" && IS_SEQUENTIAL } ]
set_false_path -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/U_CMPRESET/I_YESLUT6.U_SRL32_*" }]] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/u_scnt_cmp_q*" && IS_SEQUENTIAL } ]

set_false_path -from [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_trig/N_DDR_TC.N_DDR_TC_INST[*].U_TC/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/u_srl_drive/CLK}] -to [get_pins -hierarchical -filter {NAME =~ *ila_core_inst/u_trig/N_DDR_TC.N_DDR_TC_INST[*].U_TC/yes_output_reg.dout_reg_reg/D}]


##
## ILA Window Counter Match Condition out False Paths
##
#set_false_path -from [get_pins -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_lcmp/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/I_WHOLE_SLICE.G_SLICE_IDX[*].U_ALL_SRL_SLICE/u_srl*/S*/CLK*"}] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_lcmp_q*" && IS_SEQUENTIAL } ]
#set_false_path -from [get_pins -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_hcmp/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/I_WHOLE_SLICE.G_SLICE_IDX[*].U_ALL_SRL_SLICE/u_srl*/S*/CLK*"}] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_hcmp_q*" && IS_SEQUENTIAL } ]
set_false_path -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_lcmp/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/u_srl_drive*"}]] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_lcmp_q*" && IS_SEQUENTIAL } ]
set_false_path -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_hcmp/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/u_srl_drive*"}]] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_hcmp_q*" && IS_SEQUENTIAL } ]
set_false_path -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/U_WHCMPCE/I_YESLUT6.U_SRL32*"}]] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_hcmp_q*" && IS_SEQUENTIAL } ]
set_false_path -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/U_WLCMPCE/I_YESLUT6.U_SRL32*"}]] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_lcmp_q*" && IS_SEQUENTIAL } ]
set_false_path -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/U_CMPRESET/I_YESLUT6.U_SRL32_*" }]] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_lcmp_q*" && IS_SEQUENTIAL } ]
set_false_path -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/U_CMPRESET/I_YESLUT6.U_SRL32_*" }]] -to [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/u_wcnt_hcmp_q*" && IS_SEQUENTIAL } ]
set_false_path -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/U_SCE/I_YESLUT6.U_SRLC16E*" }]] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/iscnt_reg*" && IS_SEQUENTIAL }]
set_false_path -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/U_SCE/I_YESLUT6.U_SRLC16E*" }]] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/icap_wr_en_reg*" && IS_SEQUENTIAL }]
set_false_path -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/U_SCRST/I_YESLUT6.U_SRL32_*" }]] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_sample_counter/iscnt_reg*" && IS_SEQUENTIAL }] 
set_false_path -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/U_WCE/I_YESLUT6.U_SRLC16E*" }]] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_cap_ctrl/u_cap_addrgen/u_cap_window_counter/iwcnt_reg*" && IS_SEQUENTIAL }]
set_false_path -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/U_CDONE/I_YESLUT6.U_SRL32_*" }]] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_cap_ctrl/U_CDONE/I_YESLUT6.I_YES_OREG.O_reg*" && IS_SEQUENTIAL} ]
set_false_path -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/U_NS0/I_YESLUT6.U_SRL32_*" }]] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_cap_ctrl/U_NS0/I_YESLUT6.I_YES_OREG.O_reg*" && IS_SEQUENTIAL} ]
set_false_path -from [get_pins -filter {REF_PIN_NAME=~CLK} -of_objects [get_cells -hierarchical -filter { NAME =~  "*ila_core_inst/u_ila_cap_ctrl/U_NS1/I_YESLUT6.U_SRL32_*" }]] -to [get_cells -hierarchical -filter { NAME =~ "*ila_core_inst/u_ila_cap_ctrl/U_NS1/I_YESLUT6.I_YES_OREG.O_reg*" && IS_SEQUENTIAL} ]




##
## Waivers 
##
#create_waiver -internal -scope -type CDC -id CDC-1 -description {The cross clock communication is handled through hand shake process} -tags "1025927" -user "ila" -from [get_pins -filter {REF_PIN_NAME=~C} -of_objects [get_cells -hierarchical -filter { NAME =~ "*/ila_core_inst/u_ila_regs/ila_clk_flag_reg*"} ]] -to [get_pins -filter {REF_PIN_NAME=~D} -of_objects [get_cells -hierarchical -filter { NAME =~ "*/ila_core_inst/u_ila_regs/s_dclk_flag_reg*"} ]]
#create_waiver -internal -scope -type CDC -id CDC-1 -description {The cross clock communication is handled through hand shake process} -tags "1025927" -user "ila" -from [get_pins -filter {REF_PIN_NAME=~C} -of_objects [get_cells -hierarchical -filter { NAME =~ "*/ila_core_inst/u_ila_regs/ila_clk_flag_reg*"} ]] -to [get_pins -filter {REF_PIN_NAME=~D} -of_objects [get_cells -hierarchical -filter { NAME =~ "*/ila_core_inst/u_ila_regs/next_state_xsdb_reg*"} ]]
#create_waiver -internal -scope -type CDC -id CDC-1 -description {The cross clock communication is handled through hand shake process} -tags "1025927" -user "ila" -from [get_pins -filter {REF_PIN_NAME=~C} -of_objects [get_cells -hierarchical -filter { NAME =~ "*/ila_core_inst/u_ila_regs/ila_clk_flag_reg*"} ]] -to [get_pins -filter {REF_PIN_NAME=~D} -of_objects [get_cells -hierarchical -filter { NAME =~ "*/ila_core_inst/u_ila_regs/clk_lost_reg*"} ]]
#create_waiver -internal -scope -type CDC -id CDC-1 -description {The cross clock communication is handled through hand shake process} -tags "1025927" -user "ila" -from [get_pins -filter {REF_PIN_NAME=~C} -of_objects [get_cells -hierarchical -filter { NAME =~ "*/ila_core_inst/u_ila_regs/s_dclk_flag_reg*"} ]] -to [get_pins -filter {REF_PIN_NAME=~D} -of_objects [get_cells -hierarchical -filter { NAME =~ "*/ila_core_inst/u_ila_regs/next_state_ila_reg*"} ]]
#create_waiver -internal -scope -type CDC -id CDC-1 -description {The cross clock communication is handled through hand shake process} -tags "1025927" -user "ila" -from [get_pins -filter {REF_PIN_NAME=~C} -of_objects [get_cells -hierarchical -filter { NAME =~ "*/ila_core_inst/u_ila_regs/s_dclk_flag_reg*"} ]] -to [get_pins -filter {REF_PIN_NAME=~D} -of_objects [get_cells -hierarchical -filter { NAME =~ "*/ila_core_inst/u_ila_regs/ila_clk_flag_reg*"} ]]
#create_waiver -internal -scope -type CDC -id CDC-15 -description {The cross clock communication is handled through hand shake process} -tags "1025927" -user "ila" -from [get_pins -filter {REF_PIN_NAME=~C} -of_objects [get_cells -hierarchical -filter { NAME =~ "*/ila_core_inst/u_ila_regs/ila_clk_flag_reg*"} ]]  -to [get_pins -filter {REF_PIN_NAME=~R} -of_objects [get_cells -hierarchical -filter { NAME =~ "*/ila_core_inst/u_ila_regs/clk_lost_cnt_reg[*]*"} ]]


create_waiver -internal -type CDC -id {CDC-10} -user ila -tags "1191969" -description "CDC-10 waiver for DDR Calibration logic" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*CLK} -of_objects [get_cells -hierarchical -filter {NAME =~*u_trig/N_DDR_TC.N_DDR_TC_INST[*].U_TC/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/u_srl_drive}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*u_trig/N_DDR_TC.N_DDR_TC_INST[*].U_TC/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/I_IS_TERMINATION_SLICE_W_OUTPUT_REG.DOUT_O_reg}]]

#create_waiver -internal -type CDC -id {CDC-10} -user system_ila -tags "1196835" -description "CDC-10 waiver for DDR Calibration logic" \
                        -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*CLK} -of_objects [get_cells -hierarchical -filter {NAME =~*u_trig/N_DDR_TC.N_DDR_TC_INST[*].U_TC/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/u_srl_drive}]] \
						       -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*u_trig/N_DDR_TC.N_DDR_TC_INST[*].U_TC/allx_typeA_match_detection.ltlib_v1_0_3_allx_typeA_inst/DUT/I_WHOLE_SLICE.G_SLICE_IDX[*].U_ALL_SRL_SLICE/I_IS_TERMINATION_SLICE_W_OUTPUT_REG.DOUT_O_reg}]]


# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ila_adc3_tm_debug_0/ila_v6_2/constraints/ila.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ila_adc3_tm_debug_0/Mercury_XU5_ila_adc3_tm_debug_0_ooc.xdc
# ==========================================================
# (c) Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
# (c) Copyright 2022-2026 Advanced Micro Devices, Inc. All rights reserved.
# 
# This file contains confidential and proprietary information
# of AMD and is protected under U.S. and international copyright
# and other intellectual property laws.
# 
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# AMD, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) AMD shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or AMD had been advised of the
# possibility of the same.
# 
# CRITICAL APPLICATIONS
# AMD products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of AMD products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
# 
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.
# 
# DO NOT MODIFY THIS FILE.
# #########################################################
#
# This XDC is used only in OOC mode for synthesis, implementation
#
# #########################################################


create_clock -period 10 -name clk [get_ports clk]




# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/ip/Mercury_XU5_ila_adc3_tm_debug_0/Mercury_XU5_ila_adc3_tm_debug_0_ooc.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/Mercury_XU5_ooc.xdc
# ==========================================================
################################################################################

# This XDC is used only for OOC mode of synthesis, implementation
# This constraints file contains default clock frequencies to be used during
# out-of-context flows such as OOC Synthesis and Hierarchical Designs.
# This constraints file is not used in normal top-down synthesis (default flow
# of Vivado)
################################################################################
create_clock -name C0_SYS_CLK_clk_p -period 10 [get_ports C0_SYS_CLK_clk_p]
create_clock -name GMII_rx_clk -period 10 [get_ports GMII_rx_clk]
create_clock -name GMII_tx_clk -period 10 [get_ports GMII_tx_clk]

################################################################################

# ==========================================================
# END XDC FILE: c:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.gen/sources_1/bd/Mercury_XU5/Mercury_XU5_ooc.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: C:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/spike_programmer_pins.xdc
# ==========================================================
# SPIKE programmer external pins
# Generated for axis_spike_programmer_0

set_property PACKAGE_PIN AF13 [get_ports SPIKE_CHIP_CLK]
set_property IOSTANDARD LVCMOS18 [get_ports SPIKE_CHIP_CLK]

set_property PACKAGE_PIN AE15 [get_ports SPIKE_CHIP_DATA]
set_property IOSTANDARD LVCMOS18 [get_ports SPIKE_CHIP_DATA]

set_property PACKAGE_PIN W12 [get_ports SPIKE_CHIP_LATCH]
set_property IOSTANDARD LVCMOS18 [get_ports SPIKE_CHIP_LATCH]

set_property PACKAGE_PIN AE14 [get_ports SPIKE_CHIP_ENABLE]
set_property IOSTANDARD LVCMOS18 [get_ports SPIKE_CHIP_ENABLE]

set_property PACKAGE_PIN L7 [get_ports SPIKE_CHIP_Q]
set_property IOSTANDARD LVCMOS18 [get_ports SPIKE_CHIP_Q]

set_property PACKAGE_PIN P9 [get_ports SPIKE_SUCCESS_LED]
set_property IOSTANDARD LVCMOS18 [get_ports SPIKE_SUCCESS_LED]


# ==========================================================
# END XDC FILE: C:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/spike_programmer_pins.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: C:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/ddr4_pl_fixed_pins.xdc
# ==========================================================
# Fixed DDR4 PL pin mapping for Mercury XU5 PE1
# Maps old Mercury DDR4PL_* names to current MIG C0_DDR4_* top ports.

set_property PACKAGE_PIN AD5 [get_ports {C0_SYS_CLK_clk_p}]
set_property PACKAGE_PIN AD4 [get_ports {C0_SYS_CLK_clk_n}]
set_property PACKAGE_PIN AC4 [get_ports {C0_DDR4_adr[0]}]
set_property PACKAGE_PIN AC3 [get_ports {C0_DDR4_adr[1]}]
set_property PACKAGE_PIN AB4 [get_ports {C0_DDR4_adr[2]}]
set_property PACKAGE_PIN AB3 [get_ports {C0_DDR4_adr[3]}]
set_property PACKAGE_PIN AB2 [get_ports {C0_DDR4_adr[4]}]
set_property PACKAGE_PIN AC2 [get_ports {C0_DDR4_adr[5]}]
set_property PACKAGE_PIN AB1 [get_ports {C0_DDR4_adr[6]}]
set_property PACKAGE_PIN AC1 [get_ports {C0_DDR4_adr[7]}]
set_property PACKAGE_PIN AB5 [get_ports {C0_DDR4_adr[8]}]
set_property PACKAGE_PIN AG4 [get_ports {C0_DDR4_adr[9]}]
set_property PACKAGE_PIN AH4 [get_ports {C0_DDR4_adr[10]}]
set_property PACKAGE_PIN AG3 [get_ports {C0_DDR4_adr[11]}]
set_property PACKAGE_PIN AH3 [get_ports {C0_DDR4_adr[12]}]
set_property PACKAGE_PIN AE3 [get_ports {C0_DDR4_adr[13]}]
set_property PACKAGE_PIN AF3 [get_ports {C0_DDR4_adr[14]}]
set_property PACKAGE_PIN AE2 [get_ports {C0_DDR4_adr[15]}]
set_property PACKAGE_PIN AF2 [get_ports {C0_DDR4_adr[16]}]
set_property PACKAGE_PIN AH1 [get_ports {C0_DDR4_ba[0]}]
set_property PACKAGE_PIN AF1 [get_ports {C0_DDR4_ba[1]}]
set_property PACKAGE_PIN AG1 [get_ports {C0_DDR4_bg[0]}]
set_property PACKAGE_PIN AH2 [get_ports {C0_DDR4_act_n}]
set_property PACKAGE_PIN AH9 [get_ports {C0_DDR4_cs_n[0]}]
set_property PACKAGE_PIN AH6 [get_ports {C0_DDR4_cke[0]}]
set_property PACKAGE_PIN AE4 [get_ports {C0_DDR4_odt[0]}]
set_property PACKAGE_PIN G4  [get_ports {C0_DDR4_reset_n}]
set_property PACKAGE_PIN AD2 [get_ports {C0_DDR4_ck_t[0]}]
set_property PACKAGE_PIN AD1 [get_ports {C0_DDR4_ck_c[0]}]
set_property PACKAGE_PIN AB6 [get_ports {C0_DDR4_dq[0]}]
set_property PACKAGE_PIN AC6 [get_ports {C0_DDR4_dq[1]}]
set_property PACKAGE_PIN AE9 [get_ports {C0_DDR4_dq[2]}]
set_property PACKAGE_PIN AE8 [get_ports {C0_DDR4_dq[3]}]
set_property PACKAGE_PIN AB8 [get_ports {C0_DDR4_dq[4]}]
set_property PACKAGE_PIN AC8 [get_ports {C0_DDR4_dq[5]}]
set_property PACKAGE_PIN AB7 [get_ports {C0_DDR4_dq[6]}]
set_property PACKAGE_PIN AC7 [get_ports {C0_DDR4_dq[7]}]
set_property PACKAGE_PIN AE5 [get_ports {C0_DDR4_dq[8]}]
set_property PACKAGE_PIN AF5 [get_ports {C0_DDR4_dq[9]}]
set_property PACKAGE_PIN AF8 [get_ports {C0_DDR4_dq[10]}]
set_property PACKAGE_PIN AG8 [get_ports {C0_DDR4_dq[11]}]
set_property PACKAGE_PIN AH8 [get_ports {C0_DDR4_dq[12]}]
set_property PACKAGE_PIN AH7 [get_ports {C0_DDR4_dq[13]}]
set_property PACKAGE_PIN AF7 [get_ports {C0_DDR4_dq[14]}]
set_property PACKAGE_PIN AF6 [get_ports {C0_DDR4_dq[15]}]
set_property PACKAGE_PIN AC9 [get_ports {C0_DDR4_dm_n[0]}]
set_property PACKAGE_PIN AG9 [get_ports {C0_DDR4_dm_n[1]}]
set_property PACKAGE_PIN AD7 [get_ports {C0_DDR4_dqs_t[0]}]
set_property PACKAGE_PIN AE7 [get_ports {C0_DDR4_dqs_c[0]}]
set_property PACKAGE_PIN AG6 [get_ports {C0_DDR4_dqs_t[1]}]
set_property PACKAGE_PIN AG5 [get_ports {C0_DDR4_dqs_c[1]}]


# ==========================================================
# END XDC FILE: C:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/ddr4_pl_fixed_pins.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: C:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/board_fixed_current_ports.xdc
# ==========================================================
# Fixed board-port constraints for current Mercury_XU5_wrapper top-level ports
# Generated from routed checkpoint diagnostic STEP 18A

# Ethernet generated clocks / reset
set_property -dict {PACKAGE_PIN AA13 IOSTANDARD LVCMOS18} [get_ports {ETH_CLK10}]
set_property -dict {PACKAGE_PIN AB13 IOSTANDARD LVCMOS18} [get_ports {ETH_CLK125}]
set_property -dict {PACKAGE_PIN AC14 IOSTANDARD LVCMOS18} [get_ports {ETH_CLK125_90}]
set_property -dict {PACKAGE_PIN AC13 IOSTANDARD LVCMOS18} [get_ports {ETH_CLK25}]
set_property -dict {PACKAGE_PIN AD15 IOSTANDARD LVCMOS18} [get_ports {ETH_resetn}]

# MDIO
set_property -dict {PACKAGE_PIN AG13 IOSTANDARD LVCMOS18} [get_ports {MDIO_mdc}]
set_property -dict {PACKAGE_PIN AE12 IOSTANDARD LVCMOS18} [get_ports {MDIO_mdio_io}]

# GMII RX
set_property -dict {PACKAGE_PIN AA11 IOSTANDARD LVCMOS18} [get_ports {GMII_col}]
set_property -dict {PACKAGE_PIN AA10 IOSTANDARD LVCMOS18} [get_ports {GMII_crs}]
set_property -dict {PACKAGE_PIN AB11 IOSTANDARD LVCMOS18} [get_ports {GMII_rx_clk}]
set_property -dict {PACKAGE_PIN AC11 IOSTANDARD LVCMOS18} [get_ports {GMII_rx_dv}]
set_property -dict {PACKAGE_PIN AD11 IOSTANDARD LVCMOS18} [get_ports {GMII_rx_er}]
set_property -dict {PACKAGE_PIN AG14 IOSTANDARD LVCMOS18} [get_ports {GMII_rxd[0]}]
set_property -dict {PACKAGE_PIN AB10 IOSTANDARD LVCMOS18} [get_ports {GMII_rxd[1]}]
set_property -dict {PACKAGE_PIN AB9  IOSTANDARD LVCMOS18} [get_ports {GMII_rxd[2]}]
set_property -dict {PACKAGE_PIN Y9   IOSTANDARD LVCMOS18} [get_ports {GMII_rxd[3]}]
set_property -dict {PACKAGE_PIN AA8  IOSTANDARD LVCMOS18} [get_ports {GMII_rxd[4]}]
set_property -dict {PACKAGE_PIN W10  IOSTANDARD LVCMOS18} [get_ports {GMII_rxd[5]}]
set_property -dict {PACKAGE_PIN AH14 IOSTANDARD LVCMOS18} [get_ports {GMII_rxd[6]}]
set_property -dict {PACKAGE_PIN Y10  IOSTANDARD LVCMOS18} [get_ports {GMII_rxd[7]}]

# GMII TX
set_property -dict {PACKAGE_PIN AD10 IOSTANDARD LVCMOS18} [get_ports {GMII_tx_clk}]
set_property -dict {PACKAGE_PIN AD14 IOSTANDARD LVCMOS18} [get_ports {GMII_tx_en}]
set_property -dict {PACKAGE_PIN AE13 IOSTANDARD LVCMOS18} [get_ports {GMII_tx_er}]
set_property -dict {PACKAGE_PIN Y12  IOSTANDARD LVCMOS18} [get_ports {GMII_txd[0]}]
set_property -dict {PACKAGE_PIN AA12 IOSTANDARD LVCMOS18} [get_ports {GMII_txd[1]}]
set_property -dict {PACKAGE_PIN W11  IOSTANDARD LVCMOS18} [get_ports {GMII_txd[2]}]
set_property -dict {PACKAGE_PIN Y14  IOSTANDARD LVCMOS18} [get_ports {GMII_txd[3]}]
set_property -dict {PACKAGE_PIN Y13  IOSTANDARD LVCMOS18} [get_ports {GMII_txd[4]}]
set_property -dict {PACKAGE_PIN W14  IOSTANDARD LVCMOS18} [get_ports {GMII_txd[5]}]
set_property -dict {PACKAGE_PIN W13  IOSTANDARD LVCMOS18} [get_ports {GMII_txd[6]}]
set_property -dict {PACKAGE_PIN AB15 IOSTANDARD LVCMOS18} [get_ports {GMII_txd[7]}]

# IIC
set_property -dict {PACKAGE_PIN AC12 IOSTANDARD LVCMOS18} [get_ports {IIC_scl_io}]
set_property -dict {PACKAGE_PIN AD12 IOSTANDARD LVCMOS18} [get_ports {IIC_sda_io}]

# LEDs and reset
set_property -dict {PACKAGE_PIN D12  IOSTANDARD LVCMOS18} [get_ports {LED_N_PL[0]}]
set_property -dict {PACKAGE_PIN C12  IOSTANDARD LVCMOS18} [get_ports {LED_N_PL[1]}]
set_property -dict {PACKAGE_PIN AH13 IOSTANDARD LVCMOS18} [get_ports {Rst_N}]

# Optional slew for fast Ethernet TX-related outputs
set_property SLEW FAST [get_ports {GMII_txd[*]}]
set_property SLEW FAST [get_ports {GMII_tx_en}]
set_property SLEW FAST [get_ports {GMII_tx_er}]
set_property SLEW FAST [get_ports {ETH_CLK10}]
set_property SLEW FAST [get_ports {ETH_CLK25}]
set_property SLEW FAST [get_ports {ETH_CLK125}]
set_property SLEW FAST [get_ports {ETH_CLK125_90}]


# ==========================================================
# END XDC FILE: C:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/board_fixed_current_ports.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: C:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/dac8568_pins.xdc
# ==========================================================
# DAC8568 pin constraints
# Interface voltage: 1.8 V

set_property PACKAGE_PIN F5 [get_ports {DAC1_SYNC_N}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC1_SYNC_N}]

set_property PACKAGE_PIN G5 [get_ports {DAC1_SCLK}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC1_SCLK}]

set_property PACKAGE_PIN A3 [get_ports {DAC1_DIN}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC1_DIN}]

set_property PACKAGE_PIN B3 [get_ports {DAC1_LDAC_N}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC1_LDAC_N}]

set_property PACKAGE_PIN A5 [get_ports {DAC1_CLR_N}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC1_CLR_N}]

set_property PACKAGE_PIN B5 [get_ports {DAC2_SYNC_N}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC2_SYNC_N}]

set_property PACKAGE_PIN B8 [get_ports {DAC2_SCLK}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC2_SCLK}]

set_property PACKAGE_PIN C8 [get_ports {DAC2_DIN}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC2_DIN}]

set_property PACKAGE_PIN E8 [get_ports {DAC2_LDAC_N}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC2_LDAC_N}]

set_property PACKAGE_PIN F8 [get_ports {DAC2_CLR_N}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC2_CLR_N}]

set_property PACKAGE_PIN F6 [get_ports {DAC3_SYNC_N}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC3_SYNC_N}]

set_property PACKAGE_PIN G6 [get_ports {DAC3_SCLK}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC3_SCLK}]

set_property PACKAGE_PIN K1 [get_ports {DAC3_DIN}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC3_DIN}]

set_property PACKAGE_PIN L1 [get_ports {DAC3_LDAC_N}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC3_LDAC_N}]

set_property PACKAGE_PIN H3 [get_ports {DAC3_CLR_N}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC3_CLR_N}]

set_property PACKAGE_PIN H4 [get_ports {DAC4_SYNC_N}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC4_SYNC_N}]

set_property PACKAGE_PIN H8 [get_ports {DAC4_SCLK}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC4_SCLK}]

set_property PACKAGE_PIN H9 [get_ports {DAC4_DIN}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC4_DIN}]

set_property PACKAGE_PIN L8 [get_ports {DAC4_LDAC_N}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC4_LDAC_N}]

set_property PACKAGE_PIN M8 [get_ports {DAC4_CLR_N}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC4_CLR_N}]



# ==========================================================
# END XDC FILE: C:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/dac8568_pins.xdc
# ==========================================================

# ==========================================================
# BEGIN XDC FILE: C:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/bank66_lvcmos18_override.xdc
# ==========================================================
# Bank 66 I/O standards

set_property IOSTANDARD LVCMOS18 [get_ports {C0_DDR4_reset_n}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC1_SYNC_N}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC1_SCLK}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC1_DIN}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC1_LDAC_N}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC1_CLR_N}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC2_SYNC_N}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC2_SCLK}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC2_DIN}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC2_LDAC_N}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC2_CLR_N}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC3_SYNC_N}]
set_property IOSTANDARD LVCMOS18 [get_ports {DAC3_SCLK}]


# ==========================================================
# END XDC FILE: C:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/bank66_lvcmos18_override.xdc
# ==========================================================
