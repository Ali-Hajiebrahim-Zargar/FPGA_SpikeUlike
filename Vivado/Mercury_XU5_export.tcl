
################################################################
# This is a generated script based on design: Mercury_XU5
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2025.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   if { [string compare $scripts_vivado_version $current_vivado_version] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" " This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Sourcing the script failed since it was created with a future version of Vivado."}

   } else {
     catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   }

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source Mercury_XU5_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# AXIS_CMD_PACKET_ROUTER, AXIS_SPIKE_PROGRAMMER, FPGA_TIMESTAMP_TIMER_16, AXIS_TELEMETRY_DATA_MANAGER, AD7266_AXIS_DRIVER, AD7266_AXIS_DRIVER, AD7266_AXIS_DRIVER, AD7266_AXIS_DRIVER, axis_dac8568_waveform_driver, axis_dac8568_waveform_driver, axis_dac8568_waveform_driver, axis_dac8568_waveform_driver, AD7266_SPI_SINE_MODEL

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xczu5ev-sfvc784-2-i
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name Mercury_XU5

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:zynq_ultra_ps_e:3.5\
xilinx.com:ip:system_management_wiz:1.3\
xilinx.com:ip:axi_gpio:2.0\
xilinx.com:ip:ddr4:2.2\
xilinx.com:ip:clk_wiz:6.0\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:smartconnect:1.0\
xilinx.com:ip:axi_dma:7.1\
xilinx.com:ip:axis_dwidth_converter:1.1\
xilinx.com:ip:axis_data_fifo:2.0\
xilinx.com:ip:xlconcat:2.1\
xilinx.com:ip:xlconstant:1.1\
xilinx.com:ip:ila:6.2\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
AXIS_CMD_PACKET_ROUTER\
AXIS_SPIKE_PROGRAMMER\
FPGA_TIMESTAMP_TIMER_16\
AXIS_TELEMETRY_DATA_MANAGER\
AD7266_AXIS_DRIVER\
AD7266_AXIS_DRIVER\
AD7266_AXIS_DRIVER\
AD7266_AXIS_DRIVER\
axis_dac8568_waveform_driver\
axis_dac8568_waveform_driver\
axis_dac8568_waveform_driver\
axis_dac8568_waveform_driver\
AD7266_SPI_SINE_MODEL\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set IIC [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 IIC ]

  set C0_SYS_CLK [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 C0_SYS_CLK ]

  set C0_DDR4 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 C0_DDR4 ]

  set GMII [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gmii_rtl:1.0 GMII ]

  set MDIO [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:mdio_rtl:1.0 MDIO ]


  # Create ports
  set ETH_CLK125 [ create_bd_port -dir O -type clk ETH_CLK125 ]
  set ETH_CLK125_90 [ create_bd_port -dir O -type clk ETH_CLK125_90 ]
  set ETH_CLK25 [ create_bd_port -dir O -type clk ETH_CLK25 ]
  set ETH_CLK10 [ create_bd_port -dir O -type clk ETH_CLK10 ]
  set ETH_resetn [ create_bd_port -dir O ETH_resetn ]
  set Rst_N [ create_bd_port -dir O -type rst Rst_N ]
  set LED_N_PL [ create_bd_port -dir O -from 1 -to 0 LED_N_PL ]
  set SPIKE_CHIP_CLK [ create_bd_port -dir O SPIKE_CHIP_CLK ]
  set SPIKE_CHIP_DATA [ create_bd_port -dir O SPIKE_CHIP_DATA ]
  set SPIKE_CHIP_LATCH [ create_bd_port -dir O SPIKE_CHIP_LATCH ]
  set SPIKE_CHIP_ENABLE [ create_bd_port -dir O SPIKE_CHIP_ENABLE ]
  set SPIKE_SUCCESS_LED [ create_bd_port -dir O SPIKE_SUCCESS_LED ]
  set SPIKE_CHIP_Q [ create_bd_port -dir I SPIKE_CHIP_Q ]
  set DAC1_SYNC_N [ create_bd_port -dir O DAC1_SYNC_N ]
  set DAC1_SCLK [ create_bd_port -dir O DAC1_SCLK ]
  set DAC1_DIN [ create_bd_port -dir O DAC1_DIN ]
  set DAC1_LDAC_N [ create_bd_port -dir O DAC1_LDAC_N ]
  set DAC1_CLR_N [ create_bd_port -dir O DAC1_CLR_N ]
  set DAC2_SYNC_N [ create_bd_port -dir O DAC2_SYNC_N ]
  set DAC2_SCLK [ create_bd_port -dir O DAC2_SCLK ]
  set DAC2_DIN [ create_bd_port -dir O DAC2_DIN ]
  set DAC2_LDAC_N [ create_bd_port -dir O DAC2_LDAC_N ]
  set DAC2_CLR_N [ create_bd_port -dir O DAC2_CLR_N ]
  set DAC3_SYNC_N [ create_bd_port -dir O DAC3_SYNC_N ]
  set DAC3_SCLK [ create_bd_port -dir O DAC3_SCLK ]
  set DAC3_DIN [ create_bd_port -dir O DAC3_DIN ]
  set DAC3_LDAC_N [ create_bd_port -dir O DAC3_LDAC_N ]
  set DAC3_CLR_N [ create_bd_port -dir O DAC3_CLR_N ]
  set DAC4_SYNC_N [ create_bd_port -dir O DAC4_SYNC_N ]
  set DAC4_SCLK [ create_bd_port -dir O DAC4_SCLK ]
  set DAC4_DIN [ create_bd_port -dir O DAC4_DIN ]
  set DAC4_LDAC_N [ create_bd_port -dir O DAC4_LDAC_N ]
  set DAC4_CLR_N [ create_bd_port -dir O DAC4_CLR_N ]

  # Create instance: zynq_ultra_ps_e, and set properties
  set zynq_ultra_ps_e [ create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.5 zynq_ultra_ps_e ]
  set_property -dict [list \
    CONFIG.PSU_BANK_0_IO_STANDARD {LVCMOS18} \
    CONFIG.PSU_BANK_1_IO_STANDARD {LVCMOS18} \
    CONFIG.PSU_BANK_2_IO_STANDARD {LVCMOS18} \
    CONFIG.PSU_BANK_3_IO_STANDARD {LVCMOS18} \
    CONFIG.PSU_DDR_RAM_HIGHADDR {0xFFFFFFFF} \
    CONFIG.PSU_DDR_RAM_HIGHADDR_OFFSET {0x800000000} \
    CONFIG.PSU_DDR_RAM_LOWADDR_OFFSET {0x80000000} \
    CONFIG.PSU_MIO_12_POLARITY {Default} \
    CONFIG.PSU_MIO_12_PULLUPDOWN {disable} \
    CONFIG.PSU_MIO_13_PULLUPDOWN {disable} \
    CONFIG.PSU_MIO_14_PULLUPDOWN {disable} \
    CONFIG.PSU_MIO_15_PULLUPDOWN {disable} \
    CONFIG.PSU_MIO_16_PULLUPDOWN {disable} \
    CONFIG.PSU_MIO_17_PULLUPDOWN {disable} \
    CONFIG.PSU_MIO_18_PULLUPDOWN {disable} \
    CONFIG.PSU_MIO_19_PULLUPDOWN {disable} \
    CONFIG.PSU_MIO_20_PULLUPDOWN {disable} \
    CONFIG.PSU_MIO_21_PULLUPDOWN {disable} \
    CONFIG.PSU_MIO_23_POLARITY {Default} \
    CONFIG.PSU_MIO_24_POLARITY {Default} \
    CONFIG.PSU_MIO_25_POLARITY {Default} \
    CONFIG.PSU_MIO_40_POLARITY {Default} \
    CONFIG.PSU_MIO_41_POLARITY {Default} \
    CONFIG.PSU_MIO_42_POLARITY {Default} \
    CONFIG.PSU_MIO_43_POLARITY {Default} \
    CONFIG.PSU_MIO_44_POLARITY {Default} \
    CONFIG.PSU_MIO_7_POLARITY {Default} \
    CONFIG.PSU_MIO_8_POLARITY {Default} \
    CONFIG.PSU_MIO_9_POLARITY {Default} \
    CONFIG.PSU_MIO_TREE_PERIPHERALS {Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Feedback Clk#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#I2C 0#I2C 0#GPIO0 MIO#SD 0#SD 0#SD\
0#SD 0#SD 0#SD 0#SD 0#SD 0#SD 0#SD 0#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#Gem 0#Gem 0#Gem 0#Gem 0#Gem 0#Gem 0#Gem 0#Gem 0#Gem 0#Gem 0#Gem 0#Gem 0#UART 0#UART 0#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#SD\
1#SD 1#SD 1#SD 1#SD 1#SD 1#SD 1#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 1#USB 1#USB 1#USB 1#USB 1#USB 1#USB 1#USB 1#USB 1#USB 1#USB 1#USB 1#MDIO 0#MDIO 0} \
    CONFIG.PSU_MIO_TREE_SIGNALS {sclk_out#miso_mo1#mo2#mo3#mosi_mi0#n_ss_out#clk_for_lpbk#gpio0[7]#gpio0[8]#gpio0[9]#scl_out#sda_out#gpio0[12]#sdio0_data_out[0]#sdio0_data_out[1]#sdio0_data_out[2]#sdio0_data_out[3]#sdio0_data_out[4]#sdio0_data_out[5]#sdio0_data_out[6]#sdio0_data_out[7]#sdio0_cmd_out#sdio0_clk_out#gpio0[23]#gpio0[24]#gpio0[25]#rgmii_tx_clk#rgmii_txd[0]#rgmii_txd[1]#rgmii_txd[2]#rgmii_txd[3]#rgmii_tx_ctl#rgmii_rx_clk#rgmii_rxd[0]#rgmii_rxd[1]#rgmii_rxd[2]#rgmii_rxd[3]#rgmii_rx_ctl#rxd#txd#gpio1[40]#gpio1[41]#gpio1[42]#gpio1[43]#gpio1[44]#sdio1_cd_n#sdio1_data_out[0]#sdio1_data_out[1]#sdio1_data_out[2]#sdio1_data_out[3]#sdio1_cmd_out#sdio1_clk_out#ulpi_clk_in#ulpi_dir#ulpi_tx_data[2]#ulpi_nxt#ulpi_tx_data[0]#ulpi_tx_data[1]#ulpi_stp#ulpi_tx_data[3]#ulpi_tx_data[4]#ulpi_tx_data[5]#ulpi_tx_data[6]#ulpi_tx_data[7]#ulpi_clk_in#ulpi_dir#ulpi_tx_data[2]#ulpi_nxt#ulpi_tx_data[0]#ulpi_tx_data[1]#ulpi_stp#ulpi_tx_data[3]#ulpi_tx_data[4]#ulpi_tx_data[5]#ulpi_tx_data[6]#ulpi_tx_data[7]#gem0_mdc#gem0_mdio_out}\
\
    CONFIG.PSU_SD0_INTERNAL_BUS_WIDTH {8} \
    CONFIG.PSU_SD1_INTERNAL_BUS_WIDTH {4} \
    CONFIG.PSU_USB3__DUAL_CLOCK_ENABLE {1} \
    CONFIG.PSU__ACT_DDR_FREQ_MHZ {1200.000000} \
    CONFIG.PSU__AFI0_COHERENCY {0} \
    CONFIG.PSU__CRF_APB__ACPU_CTRL__ACT_FREQMHZ {1316.666626} \
    CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__ACT_FREQMHZ {250.000000} \
    CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__ACT_FREQMHZ {250.000000} \
    CONFIG.PSU__CRF_APB__DDR_CTRL__ACT_FREQMHZ {600.000000} \
    CONFIG.PSU__CRF_APB__DDR_CTRL__FREQMHZ {1200} \
    CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__ACT_FREQMHZ {600.000000} \
    CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__ACT_FREQMHZ {600.000000} \
    CONFIG.PSU__CRF_APB__GPU_REF_CTRL__ACT_FREQMHZ {600.000000} \
    CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__ACT_FREQMHZ {525.000000} \
    CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__ACT_FREQMHZ {499.999969} \
    CONFIG.PSU__CRL_APB__AMS_REF_CTRL__ACT_FREQMHZ {50.000000} \
    CONFIG.PSU__CRL_APB__CPU_R5_CTRL__ACT_FREQMHZ {499.999969} \
    CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__ACT_FREQMHZ {250.000000} \
    CONFIG.PSU__CRL_APB__DLL_REF_CTRL__ACT_FREQMHZ {1500.000000} \
    CONFIG.PSU__CRL_APB__GEM0_REF_CTRL__ACT_FREQMHZ {125.000000} \
    CONFIG.PSU__CRL_APB__GEM1_REF_CTRL__ACT_FREQMHZ {125.000000} \
    CONFIG.PSU__CRL_APB__GEM_TSU_REF_CTRL__ACT_FREQMHZ {250.000000} \
    CONFIG.PSU__CRL_APB__GEM_TSU_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__ACT_FREQMHZ {249.999985} \
    CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__ACT_FREQMHZ {499.999969} \
    CONFIG.PSU__CRL_APB__PCAP_CTRL__ACT_FREQMHZ {187.500000} \
    CONFIG.PSU__CRL_APB__PL0_REF_CTRL__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__PL0_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__PL1_REF_CTRL__ACT_FREQMHZ {50.000000} \
    CONFIG.PSU__CRL_APB__PL1_REF_CTRL__FREQMHZ {50} \
    CONFIG.PSU__CRL_APB__PL1_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__ACT_FREQMHZ {199.999985} \
    CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__FREQMHZ {200} \
    CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__SRCSEL {RPLL} \
    CONFIG.PSU__CRL_APB__SDIO0_REF_CTRL__ACT_FREQMHZ {199.999985} \
    CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__ACT_FREQMHZ {199.999985} \
    CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__ACT_FREQMHZ {33.333332} \
    CONFIG.PSU__CRL_APB__UART0_REF_CTRL__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__ACT_FREQMHZ {250.000000} \
    CONFIG.PSU__CRL_APB__USB1_BUS_REF_CTRL__ACT_FREQMHZ {250.000000} \
    CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__ACT_FREQMHZ {20.000000} \
    CONFIG.PSU__DDRC__BG_ADDR_COUNT {1} \
    CONFIG.PSU__DDRC__BUS_WIDTH {64 Bit} \
    CONFIG.PSU__DDRC__CL {17} \
    CONFIG.PSU__DDRC__CWL {12} \
    CONFIG.PSU__DDRC__DEVICE_CAPACITY {8192 MBits} \
    CONFIG.PSU__DDRC__DRAM_WIDTH {16 Bits} \
    CONFIG.PSU__DDRC__ECC {Enabled} \
    CONFIG.PSU__DDRC__PARITY_ENABLE {1} \
    CONFIG.PSU__DDRC__ROW_ADDR_COUNT {16} \
    CONFIG.PSU__DDRC__SPEED_BIN {DDR4_2400T} \
    CONFIG.PSU__DDRC__T_FAW {30.0} \
    CONFIG.PSU__DDRC__T_RAS_MIN {32.0} \
    CONFIG.PSU__DDRC__T_RC {46.16} \
    CONFIG.PSU__DDRC__T_RCD {17} \
    CONFIG.PSU__DDRC__T_RP {17} \
    CONFIG.PSU__DDR_HIGH_ADDRESS_GUI_ENABLE {1} \
    CONFIG.PSU__DDR__INTERFACE__FREQMHZ {600.000} \
    CONFIG.PSU__DLL__ISUSED {1} \
    CONFIG.PSU__ENET0__FIFO__ENABLE {0} \
    CONFIG.PSU__ENET0__GRP_MDIO__ENABLE {1} \
    CONFIG.PSU__ENET0__GRP_MDIO__IO {MIO 76 .. 77} \
    CONFIG.PSU__ENET0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__ENET0__PERIPHERAL__IO {MIO 26 .. 37} \
    CONFIG.PSU__ENET0__PTP__ENABLE {0} \
    CONFIG.PSU__ENET0__TSU__ENABLE {0} \
    CONFIG.PSU__ENET1__FIFO__ENABLE {0} \
    CONFIG.PSU__ENET1__GRP_MDIO__ENABLE {1} \
    CONFIG.PSU__ENET1__GRP_MDIO__IO {EMIO} \
    CONFIG.PSU__ENET1__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__ENET1__PERIPHERAL__IO {EMIO} \
    CONFIG.PSU__ENET1__PTP__ENABLE {0} \
    CONFIG.PSU__FPGA_PL1_ENABLE {1} \
    CONFIG.PSU__GEM0_COHERENCY {0} \
    CONFIG.PSU__GEM0_ROUTE_THROUGH_FPD {0} \
    CONFIG.PSU__GEM1_COHERENCY {0} \
    CONFIG.PSU__GEM1_ROUTE_THROUGH_FPD {0} \
    CONFIG.PSU__GEM__TSU__ENABLE {0} \
    CONFIG.PSU__GPIO0_MIO__IO {MIO 0 .. 25} \
    CONFIG.PSU__GPIO0_MIO__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__GPIO1_MIO__IO {MIO 26 .. 51} \
    CONFIG.PSU__GPIO1_MIO__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__GPIO2_MIO__IO {MIO 52 .. 77} \
    CONFIG.PSU__GPIO2_MIO__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__I2C0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__I2C0__PERIPHERAL__IO {MIO 10 .. 11} \
    CONFIG.PSU__I2C1__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__I2C1__PERIPHERAL__IO {EMIO} \
    CONFIG.PSU__IOU_SLCR__TTC0__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__MAXIGP0__DATA_WIDTH {128} \
    CONFIG.PSU__PL_CLK1_BUF {TRUE} \
    CONFIG.PSU__PROTECTION__MASTERS {USB1:NonSecure;1|USB0:NonSecure;1|S_AXI_LPD:NA;0|S_AXI_HPC1_FPD:NA;0|S_AXI_HPC0_FPD:NA;1|S_AXI_HP3_FPD:NA;0|S_AXI_HP2_FPD:NA;0|S_AXI_HP1_FPD:NA;0|S_AXI_HP0_FPD:NA;0|S_AXI_ACP:NA;0|S_AXI_ACE:NA;0|SD1:NonSecure;1|SD0:NonSecure;1|SATA1:NonSecure;0|SATA0:NonSecure;0|RPU1:Secure;1|RPU0:Secure;1|QSPI:NonSecure;1|PMU:NA;1|PCIe:NonSecure;0|NAND:NonSecure;0|LDMA:NonSecure;1|GPU:NonSecure;1|GEM3:NonSecure;0|GEM2:NonSecure;0|GEM1:NonSecure;1|GEM0:NonSecure;1|FDMA:NonSecure;1|DP:NonSecure;0|DAP:NA;1|Coresight:NA;1|CSU:NA;1|APU:NA;1}\
\
    CONFIG.PSU__PROTECTION__SLAVES {LPD;USB3_1_XHCI;FE300000;FE3FFFFF;1|LPD;USB3_1;FF9E0000;FF9EFFFF;1|LPD;USB3_0_XHCI;FE200000;FE2FFFFF;1|LPD;USB3_0;FF9D0000;FF9DFFFF;1|LPD;UART1;FF010000;FF01FFFF;0|LPD;UART0;FF000000;FF00FFFF;1|LPD;TTC3;FF140000;FF14FFFF;0|LPD;TTC2;FF130000;FF13FFFF;0|LPD;TTC1;FF120000;FF12FFFF;0|LPD;TTC0;FF110000;FF11FFFF;1|FPD;SWDT1;FD4D0000;FD4DFFFF;0|LPD;SWDT0;FF150000;FF15FFFF;0|LPD;SPI1;FF050000;FF05FFFF;0|LPD;SPI0;FF040000;FF04FFFF;0|FPD;SMMU_REG;FD5F0000;FD5FFFFF;1|FPD;SMMU;FD800000;FDFFFFFF;1|FPD;SIOU;FD3D0000;FD3DFFFF;1|FPD;SERDES;FD400000;FD47FFFF;1|LPD;SD1;FF170000;FF17FFFF;1|LPD;SD0;FF160000;FF16FFFF;1|FPD;SATA;FD0C0000;FD0CFFFF;0|LPD;RTC;FFA60000;FFA6FFFF;1|LPD;RSA_CORE;FFCE0000;FFCEFFFF;1|LPD;RPU;FF9A0000;FF9AFFFF;1|LPD;R5_TCM_RAM_GLOBAL;FFE00000;FFE3FFFF;1|LPD;R5_1_Instruction_Cache;FFEC0000;FFECFFFF;1|LPD;R5_1_Data_Cache;FFED0000;FFEDFFFF;1|LPD;R5_1_BTCM_GLOBAL;FFEB0000;FFEBFFFF;1|LPD;R5_1_ATCM_GLOBAL;FFE90000;FFE9FFFF;1|LPD;R5_0_Instruction_Cache;FFE40000;FFE4FFFF;1|LPD;R5_0_Data_Cache;FFE50000;FFE5FFFF;1|LPD;R5_0_BTCM_GLOBAL;FFE20000;FFE2FFFF;1|LPD;R5_0_ATCM_GLOBAL;FFE00000;FFE0FFFF;1|LPD;QSPI_Linear_Address;C0000000;DFFFFFFF;1|LPD;QSPI;FF0F0000;FF0FFFFF;1|LPD;PMU_RAM;FFDC0000;FFDDFFFF;1|LPD;PMU_GLOBAL;FFD80000;FFDBFFFF;1|FPD;PCIE_MAIN;FD0E0000;FD0EFFFF;0|FPD;PCIE_LOW;E0000000;EFFFFFFF;0|FPD;PCIE_HIGH2;8000000000;BFFFFFFFFF;0|FPD;PCIE_HIGH1;600000000;7FFFFFFFF;0|FPD;PCIE_DMA;FD0F0000;FD0FFFFF;0|FPD;PCIE_ATTRIB;FD480000;FD48FFFF;0|LPD;OCM_XMPU_CFG;FFA70000;FFA7FFFF;1|LPD;OCM_SLCR;FF960000;FF96FFFF;1|OCM;OCM;FFFC0000;FFFFFFFF;1|LPD;NAND;FF100000;FF10FFFF;0|LPD;MBISTJTAG;FFCF0000;FFCFFFFF;1|LPD;LPD_XPPU_SINK;FF9C0000;FF9CFFFF;1|LPD;LPD_XPPU;FF980000;FF98FFFF;1|LPD;LPD_SLCR_SECURE;FF4B0000;FF4DFFFF;1|LPD;LPD_SLCR;FF410000;FF4AFFFF;1|LPD;LPD_GPV;FE100000;FE1FFFFF;1|LPD;LPD_DMA_7;FFAF0000;FFAFFFFF;1|LPD;LPD_DMA_6;FFAE0000;FFAEFFFF;1|LPD;LPD_DMA_5;FFAD0000;FFADFFFF;1|LPD;LPD_DMA_4;FFAC0000;FFACFFFF;1|LPD;LPD_DMA_3;FFAB0000;FFABFFFF;1|LPD;LPD_DMA_2;FFAA0000;FFAAFFFF;1|LPD;LPD_DMA_1;FFA90000;FFA9FFFF;1|LPD;LPD_DMA_0;FFA80000;FFA8FFFF;1|LPD;IPI_CTRL;FF380000;FF3FFFFF;1|LPD;IOU_SLCR;FF180000;FF23FFFF;1|LPD;IOU_SECURE_SLCR;FF240000;FF24FFFF;1|LPD;IOU_SCNTRS;FF260000;FF26FFFF;1|LPD;IOU_SCNTR;FF250000;FF25FFFF;1|LPD;IOU_GPV;FE000000;FE0FFFFF;1|LPD;I2C1;FF030000;FF03FFFF;1|LPD;I2C0;FF020000;FF02FFFF;1|FPD;GPU;FD4B0000;FD4BFFFF;1|LPD;GPIO;FF0A0000;FF0AFFFF;1|LPD;GEM3;FF0E0000;FF0EFFFF;0|LPD;GEM2;FF0D0000;FF0DFFFF;0|LPD;GEM1;FF0C0000;FF0CFFFF;1|LPD;GEM0;FF0B0000;FF0BFFFF;1|FPD;FPD_XMPU_SINK;FD4F0000;FD4FFFFF;1|FPD;FPD_XMPU_CFG;FD5D0000;FD5DFFFF;1|FPD;FPD_SLCR_SECURE;FD690000;FD6CFFFF;1|FPD;FPD_SLCR;FD610000;FD68FFFF;1|FPD;FPD_DMA_CH7;FD570000;FD57FFFF;1|FPD;FPD_DMA_CH6;FD560000;FD56FFFF;1|FPD;FPD_DMA_CH5;FD550000;FD55FFFF;1|FPD;FPD_DMA_CH4;FD540000;FD54FFFF;1|FPD;FPD_DMA_CH3;FD530000;FD53FFFF;1|FPD;FPD_DMA_CH2;FD520000;FD52FFFF;1|FPD;FPD_DMA_CH1;FD510000;FD51FFFF;1|FPD;FPD_DMA_CH0;FD500000;FD50FFFF;1|LPD;EFUSE;FFCC0000;FFCCFFFF;1|FPD;Display\
Port;FD4A0000;FD4AFFFF;0|FPD;DPDMA;FD4C0000;FD4CFFFF;0|FPD;DDR_XMPU5_CFG;FD050000;FD05FFFF;1|FPD;DDR_XMPU4_CFG;FD040000;FD04FFFF;1|FPD;DDR_XMPU3_CFG;FD030000;FD03FFFF;1|FPD;DDR_XMPU2_CFG;FD020000;FD02FFFF;1|FPD;DDR_XMPU1_CFG;FD010000;FD01FFFF;1|FPD;DDR_XMPU0_CFG;FD000000;FD00FFFF;1|FPD;DDR_QOS_CTRL;FD090000;FD09FFFF;1|FPD;DDR_PHY;FD080000;FD08FFFF;1|DDR;DDR_LOW;0;7FFFFFFF;1|DDR;DDR_HIGH;800000000;87FFFFFFF;1|FPD;DDDR_CTRL;FD070000;FD070FFF;1|LPD;Coresight;FE800000;FEFFFFFF;1|LPD;CSU_DMA;FFC80000;FFC9FFFF;1|LPD;CSU;FFCA0000;FFCAFFFF;1|LPD;CRL_APB;FF5E0000;FF85FFFF;1|FPD;CRF_APB;FD1A0000;FD2DFFFF;1|FPD;CCI_REG;FD5E0000;FD5EFFFF;1|LPD;CAN1;FF070000;FF07FFFF;0|LPD;CAN0;FF060000;FF06FFFF;0|FPD;APU;FD5C0000;FD5CFFFF;1|LPD;APM_INTC_IOU;FFA20000;FFA2FFFF;1|LPD;APM_FPD_LPD;FFA30000;FFA3FFFF;1|FPD;APM_5;FD490000;FD49FFFF;1|FPD;APM_0;FD0B0000;FD0BFFFF;1|LPD;APM2;FFA10000;FFA1FFFF;1|LPD;APM1;FFA00000;FFA0FFFF;1|LPD;AMS;FFA50000;FFA5FFFF;1|FPD;AFI_5;FD3B0000;FD3BFFFF;1|FPD;AFI_4;FD3A0000;FD3AFFFF;1|FPD;AFI_3;FD390000;FD39FFFF;1|FPD;AFI_2;FD380000;FD38FFFF;1|FPD;AFI_1;FD370000;FD37FFFF;1|FPD;AFI_0;FD360000;FD36FFFF;1|LPD;AFIFM6;FF9B0000;FF9BFFFF;1|FPD;ACPU_GIC;F9010000;F907FFFF;1}\
\
    CONFIG.PSU__PSS_REF_CLK__FREQMHZ {33.333333} \
    CONFIG.PSU__QSPI_COHERENCY {0} \
    CONFIG.PSU__QSPI_ROUTE_THROUGH_FPD {0} \
    CONFIG.PSU__QSPI__GRP_FBCLK__ENABLE {1} \
    CONFIG.PSU__QSPI__GRP_FBCLK__IO {MIO 6} \
    CONFIG.PSU__QSPI__PERIPHERAL__DATA_MODE {x4} \
    CONFIG.PSU__QSPI__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__QSPI__PERIPHERAL__IO {MIO 0 .. 5} \
    CONFIG.PSU__QSPI__PERIPHERAL__MODE {Single} \
    CONFIG.PSU__SAXIGP0__DATA_WIDTH {128} \
    CONFIG.PSU__SD0_COHERENCY {0} \
    CONFIG.PSU__SD0_ROUTE_THROUGH_FPD {0} \
    CONFIG.PSU__SD0__CLK_200_SDR_OTAP_DLY {0x3} \
    CONFIG.PSU__SD0__CLK_50_DDR_ITAP_DLY {0x12} \
    CONFIG.PSU__SD0__CLK_50_DDR_OTAP_DLY {0x6} \
    CONFIG.PSU__SD0__CLK_50_SDR_ITAP_DLY {0x15} \
    CONFIG.PSU__SD0__CLK_50_SDR_OTAP_DLY {0x6} \
    CONFIG.PSU__SD0__DATA_TRANSFER_MODE {8Bit} \
    CONFIG.PSU__SD0__GRP_POW__ENABLE {0} \
    CONFIG.PSU__SD0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__SD0__PERIPHERAL__IO {MIO 13 .. 22} \
    CONFIG.PSU__SD0__SLOT_TYPE {eMMC} \
    CONFIG.PSU__SD1_COHERENCY {0} \
    CONFIG.PSU__SD1_ROUTE_THROUGH_FPD {0} \
    CONFIG.PSU__SD1__CLK_50_SDR_ITAP_DLY {0x15} \
    CONFIG.PSU__SD1__CLK_50_SDR_OTAP_DLY {0x5} \
    CONFIG.PSU__SD1__DATA_TRANSFER_MODE {4Bit} \
    CONFIG.PSU__SD1__GRP_CD__ENABLE {1} \
    CONFIG.PSU__SD1__GRP_CD__IO {MIO 45} \
    CONFIG.PSU__SD1__GRP_POW__ENABLE {0} \
    CONFIG.PSU__SD1__GRP_WP__ENABLE {0} \
    CONFIG.PSU__SD1__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__SD1__PERIPHERAL__IO {MIO 46 .. 51} \
    CONFIG.PSU__SD1__SLOT_TYPE {SD 2.0} \
    CONFIG.PSU__TSU__BUFG_PORT_PAIR {0} \
    CONFIG.PSU__TTC0__CLOCK__ENABLE {0} \
    CONFIG.PSU__TTC0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__TTC0__WAVEOUT__ENABLE {0} \
    CONFIG.PSU__UART0__BAUD_RATE {115200} \
    CONFIG.PSU__UART0__MODEM__ENABLE {0} \
    CONFIG.PSU__UART0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__UART0__PERIPHERAL__IO {MIO 38 .. 39} \
    CONFIG.PSU__USB0_COHERENCY {0} \
    CONFIG.PSU__USB0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__USB0__PERIPHERAL__IO {MIO 52 .. 63} \
    CONFIG.PSU__USB1_COHERENCY {0} \
    CONFIG.PSU__USB1__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__USB1__PERIPHERAL__IO {MIO 64 .. 75} \
    CONFIG.PSU__USB2_0__EMIO__ENABLE {0} \
    CONFIG.PSU__USB2_1__EMIO__ENABLE {0} \
    CONFIG.PSU__USB3_0__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__USB3_1__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__USB__RESET__MODE {Disable} \
    CONFIG.PSU__USE__IRQ0 {1} \
    CONFIG.PSU__USE__M_AXI_GP0 {1} \
    CONFIG.PSU__USE__S_AXI_GP0 {1} \
  ] $zynq_ultra_ps_e


  # Create instance: system_management_wiz, and set properties
  set system_management_wiz [ create_bd_cell -type ip -vlnv xilinx.com:ip:system_management_wiz:1.3 system_management_wiz ]
  set_property -dict [list \
    CONFIG.CHANNEL_ENABLE_VP_VN {false} \
    CONFIG.TEMPERATURE_ALARM_OT_TRIGGER {85} \
  ] $system_management_wiz


  # Create instance: led, and set properties
  set led [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 led ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_DOUT_DEFAULT {0x00000003} \
    CONFIG.C_GPIO_WIDTH {2} \
  ] $led


  # Create instance: ddr4, and set properties
  set ddr4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4:2.2 ddr4 ]
  set_property -dict [list \
    CONFIG.C0.DDR4_CasLatency {17} \
    CONFIG.C0.DDR4_CasWriteLatency {12} \
    CONFIG.C0.DDR4_DataWidth {16} \
    CONFIG.C0.DDR4_InputClockPeriod {9996} \
    CONFIG.C0.DDR4_MemoryPart {MT40A512M16HA-083E} \
    CONFIG.C0.DDR4_TimePeriod {833} \
  ] $ddr4


  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property CONFIG.NUM_MI {1} $axi_interconnect_0


  # Create instance: clk_wiz_gmii2rgmii, and set properties
  set clk_wiz_gmii2rgmii [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_gmii2rgmii ]
  set_property -dict [list \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {125.000} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {125.000} \
    CONFIG.CLKOUT2_REQUESTED_PHASE {90} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {25.000} \
    CONFIG.CLKOUT3_USED {true} \
    CONFIG.CLKOUT4_DRIVES {No_buffer} \
    CONFIG.CLKOUT4_REQUESTED_OUT_FREQ {10.000} \
    CONFIG.CLKOUT4_USED {true} \
    CONFIG.NUM_OUT_CLKS {4} \
    CONFIG.PRIM_SOURCE {No_buffer} \
    CONFIG.RESET_PORT {resetn} \
    CONFIG.RESET_TYPE {ACTIVE_LOW} \
    CONFIG.USE_LOCKED {true} \
  ] $clk_wiz_gmii2rgmii


  # Create instance: ps_sys_rst, and set properties
  set ps_sys_rst [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 ps_sys_rst ]

  # Create instance: ddr4_sys_rst, and set properties
  set ddr4_sys_rst [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 ddr4_sys_rst ]

  # Create instance: smartconnect_00, and set properties
  set smartconnect_00 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_00 ]
  set_property -dict [list \
    CONFIG.NUM_CLKS {1} \
    CONFIG.NUM_MI {5} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_00


  # Create instance: axi_dma_cmd, and set properties
  set axi_dma_cmd [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_cmd ]
  set_property -dict [list \
    CONFIG.c_include_mm2s {1} \
    CONFIG.c_include_mm2s_dre {1} \
    CONFIG.c_include_s2mm {0} \
    CONFIG.c_include_sg {0} \
    CONFIG.c_m_axis_mm2s_tdata_width {32} \
    CONFIG.c_mm2s_burst_size {16} \
  ] $axi_dma_cmd


  # Create instance: axis_dwidth_cmd, and set properties
  set axis_dwidth_cmd [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwidth_cmd ]
  set_property -dict [list \
    CONFIG.HAS_TKEEP {1} \
    CONFIG.HAS_TLAST {1} \
    CONFIG.M_TDATA_NUM_BYTES {1} \
    CONFIG.S_TDATA_NUM_BYTES {4} \
  ] $axis_dwidth_cmd


  # Create instance: axis_fifo_cmd, and set properties
  set axis_fifo_cmd [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_fifo_cmd ]
  set_property -dict [list \
    CONFIG.FIFO_DEPTH {1024} \
    CONFIG.HAS_TKEEP {1} \
    CONFIG.HAS_TLAST {1} \
    CONFIG.TDATA_NUM_BYTES {1} \
  ] $axis_fifo_cmd


  # Create instance: cmd_smartconnect_data, and set properties
  set cmd_smartconnect_data [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 cmd_smartconnect_data ]
  set_property -dict [list \
    CONFIG.NUM_MI {1} \
    CONFIG.NUM_SI {2} \
  ] $cmd_smartconnect_data


  # Create instance: cmd_irq_concat, and set properties
  set cmd_irq_concat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 cmd_irq_concat ]
  set_property CONFIG.NUM_PORTS {1} $cmd_irq_concat


  # Create instance: axis_cmd_packet_router_0, and set properties
  set block_name AXIS_CMD_PACKET_ROUTER
  set block_cell_name axis_cmd_packet_router_0
  if { [catch {set axis_cmd_packet_router_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $axis_cmd_packet_router_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: cmd_tready_const, and set properties
  set cmd_tready_const [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 cmd_tready_const ]
  set_property -dict [list \
    CONFIG.CONST_VAL {1} \
    CONFIG.CONST_WIDTH {1} \
  ] $cmd_tready_const


  # Create instance: axis_spike_programmer_0, and set properties
  set block_name AXIS_SPIKE_PROGRAMMER
  set block_cell_name axis_spike_programmer_0
  if { [catch {set axis_spike_programmer_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $axis_spike_programmer_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: fpga_timestamp_timer_16_0, and set properties
  set block_name FPGA_TIMESTAMP_TIMER_16
  set block_cell_name fpga_timestamp_timer_16_0
  if { [catch {set fpga_timestamp_timer_16_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $fpga_timestamp_timer_16_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property CONFIG.G_TICK_DIVIDER {100000} $fpga_timestamp_timer_16_0


  # Create instance: axis_telemetry_data_manager_0, and set properties
  set block_name AXIS_TELEMETRY_DATA_MANAGER
  set block_cell_name axis_telemetry_data_manager_0
  if { [catch {set axis_telemetry_data_manager_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $axis_telemetry_data_manager_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [list \
    CONFIG.G_HPU_SOURCE_ID {09} \
    CONFIG.G_MAX_PAYLOAD_BYTES {256} \
    CONFIG.G_VERSION {0x01} \
  ] $axis_telemetry_data_manager_0


  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   CONFIG.CLK_DOMAIN {Mercury_XU5_zynq_ultra_ps_e_0_pl_clk0} \
 ] [get_bd_intf_pins /axis_telemetry_data_manager_0/M_AXIS_O]

  # Create instance: timer_enable_const, and set properties
  set timer_enable_const [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 timer_enable_const ]
  set_property -dict [list \
    CONFIG.CONST_VAL {1} \
    CONFIG.CONST_WIDTH {1} \
  ] $timer_enable_const


  # Create instance: dm_const_zero_1, and set properties
  set dm_const_zero_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 dm_const_zero_1 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {1} \
  ] $dm_const_zero_1


  # Create instance: dm_const_zero_8, and set properties
  set dm_const_zero_8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 dm_const_zero_8 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {8} \
  ] $dm_const_zero_8


  # Create instance: dm_const_one_1, and set properties
  set dm_const_one_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 dm_const_one_1 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {1} \
    CONFIG.CONST_WIDTH {1} \
  ] $dm_const_one_1


  # Create instance: ad7266_adc1_driver, and set properties
  set block_name AD7266_AXIS_DRIVER
  set block_cell_name ad7266_adc1_driver
  if { [catch {set ad7266_adc1_driver [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $ad7266_adc1_driver eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   CONFIG.CLK_DOMAIN {Mercury_XU5_zynq_ultra_ps_e_0_pl_clk0} \
 ] [get_bd_intf_pins /ad7266_adc1_driver/M_AXIS_O]

  # Create instance: ad7266_adc2_driver, and set properties
  set block_name AD7266_AXIS_DRIVER
  set block_cell_name ad7266_adc2_driver
  if { [catch {set ad7266_adc2_driver [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $ad7266_adc2_driver eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   CONFIG.CLK_DOMAIN {Mercury_XU5_zynq_ultra_ps_e_0_pl_clk0} \
 ] [get_bd_intf_pins /ad7266_adc2_driver/M_AXIS_O]

  # Create instance: ad7266_adc3_driver, and set properties
  set block_name AD7266_AXIS_DRIVER
  set block_cell_name ad7266_adc3_driver
  if { [catch {set ad7266_adc3_driver [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $ad7266_adc3_driver eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   CONFIG.CLK_DOMAIN {Mercury_XU5_zynq_ultra_ps_e_0_pl_clk0} \
 ] [get_bd_intf_pins /ad7266_adc3_driver/M_AXIS_O]

  # Create instance: ad7266_adc4_driver, and set properties
  set block_name AD7266_AXIS_DRIVER
  set block_cell_name ad7266_adc4_driver
  if { [catch {set ad7266_adc4_driver [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $ad7266_adc4_driver eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   CONFIG.CLK_DOMAIN {Mercury_XU5_zynq_ultra_ps_e_0_pl_clk0} \
 ] [get_bd_intf_pins /ad7266_adc4_driver/M_AXIS_O]

  # Create instance: axi_dma_tm, and set properties
  set axi_dma_tm [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_tm ]
  set_property -dict [list \
    CONFIG.c_include_mm2s {0} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_include_s2mm_dre {1} \
    CONFIG.c_include_sg {0} \
    CONFIG.c_m_axi_s2mm_data_width {32} \
    CONFIG.c_s2mm_burst_size {16} \
    CONFIG.c_s_axis_s2mm_tdata_width {8} \
    CONFIG.c_sg_length_width {14} \
  ] $axi_dma_tm


  # Create instance: tm_tkeep_const_1, and set properties
  set tm_tkeep_const_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 tm_tkeep_const_1 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {1} \
    CONFIG.CONST_WIDTH {1} \
  ] $tm_tkeep_const_1


  # Create instance: adc_dout_zero_1, and set properties
  set adc_dout_zero_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 adc_dout_zero_1 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {1} \
  ] $adc_dout_zero_1


  # Create instance: ila_adc3_tm_debug, and set properties
  set ila_adc3_tm_debug [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_adc3_tm_debug ]
  set_property -dict [list \
    CONFIG.C_DATA_DEPTH {2048} \
    CONFIG.C_NUM_OF_PROBES {23} \
    CONFIG.C_PROBE0_WIDTH {1} \
    CONFIG.C_PROBE10_WIDTH {8} \
    CONFIG.C_PROBE11_WIDTH {1} \
    CONFIG.C_PROBE12_WIDTH {1} \
    CONFIG.C_PROBE13_WIDTH {3} \
    CONFIG.C_PROBE14_WIDTH {1} \
    CONFIG.C_PROBE15_WIDTH {1} \
    CONFIG.C_PROBE16_WIDTH {1} \
    CONFIG.C_PROBE17_WIDTH {12} \
    CONFIG.C_PROBE18_WIDTH {12} \
    CONFIG.C_PROBE19_WIDTH {1} \
    CONFIG.C_PROBE1_WIDTH {1} \
    CONFIG.C_PROBE20_WIDTH {1} \
    CONFIG.C_PROBE21_WIDTH {1} \
    CONFIG.C_PROBE22_WIDTH {8} \
    CONFIG.C_PROBE2_WIDTH {1} \
    CONFIG.C_PROBE3_WIDTH {8} \
    CONFIG.C_PROBE4_WIDTH {8} \
    CONFIG.C_PROBE5_WIDTH {1} \
    CONFIG.C_PROBE6_WIDTH {1} \
    CONFIG.C_PROBE7_WIDTH {1} \
    CONFIG.C_PROBE8_WIDTH {1} \
    CONFIG.C_PROBE9_WIDTH {1} \
  ] $ila_adc3_tm_debug


  # Create instance: dac8568_driver_1, and set properties
  set block_name axis_dac8568_waveform_driver
  set block_cell_name dac8568_driver_1
  if { [catch {set dac8568_driver_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dac8568_driver_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dac8568_driver_2, and set properties
  set block_name axis_dac8568_waveform_driver
  set block_cell_name dac8568_driver_2
  if { [catch {set dac8568_driver_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dac8568_driver_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dac8568_driver_3, and set properties
  set block_name axis_dac8568_waveform_driver
  set block_cell_name dac8568_driver_3
  if { [catch {set dac8568_driver_3 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dac8568_driver_3 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dac8568_driver_4, and set properties
  set block_name axis_dac8568_waveform_driver
  set block_cell_name dac8568_driver_4
  if { [catch {set dac8568_driver_4 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dac8568_driver_4 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: ad7266_adc3_sine_model, and set properties
  set block_name AD7266_SPI_SINE_MODEL
  set block_cell_name ad7266_adc3_sine_model
  if { [catch {set ad7266_adc3_sine_model [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $ad7266_adc3_sine_model eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [list \
    CONFIG.G_DOUTB_PHASE_OFFSET {16} \
    CONFIG.G_PAIR_PHASE_OFFSET {3} \
    CONFIG.G_PHASE_STEP {1} \
  ] $ad7266_adc3_sine_model


  # Create interface connections
  connect_bd_intf_net -intf_net C0_SYS_CLK_1 [get_bd_intf_ports C0_SYS_CLK] [get_bd_intf_pins ddr4/C0_SYS_CLK]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_pins zynq_ultra_ps_e/M_AXI_HPM0_FPD]
  connect_bd_intf_net -intf_net axi_dma_cmd_M_AXIS_MM2S [get_bd_intf_pins axi_dma_cmd/M_AXIS_MM2S] [get_bd_intf_pins axis_dwidth_cmd/S_AXIS]
  connect_bd_intf_net -intf_net axi_dma_cmd_M_AXI_MM2S [get_bd_intf_pins axi_dma_cmd/M_AXI_MM2S] [get_bd_intf_pins cmd_smartconnect_data/S00_AXI]
  connect_bd_intf_net -intf_net axi_dma_tm_M_AXI_S2MM [get_bd_intf_pins axi_dma_tm/M_AXI_S2MM] [get_bd_intf_pins cmd_smartconnect_data/S01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins ddr4/C0_DDR4_S_AXI]
  connect_bd_intf_net -intf_net axis_cmd_packet_router_0_M_DAC1 [get_bd_intf_pins axis_cmd_packet_router_0/M_DAC1] [get_bd_intf_pins dac8568_driver_1/S_AXIS]
  connect_bd_intf_net -intf_net axis_cmd_packet_router_0_M_DAC2 [get_bd_intf_pins axis_cmd_packet_router_0/M_DAC2] [get_bd_intf_pins dac8568_driver_2/S_AXIS]
  connect_bd_intf_net -intf_net axis_cmd_packet_router_0_M_DAC3 [get_bd_intf_pins axis_cmd_packet_router_0/M_DAC3] [get_bd_intf_pins dac8568_driver_3/S_AXIS]
  connect_bd_intf_net -intf_net axis_cmd_packet_router_0_M_DAC4 [get_bd_intf_pins axis_cmd_packet_router_0/M_DAC4] [get_bd_intf_pins dac8568_driver_4/S_AXIS]
  connect_bd_intf_net -intf_net axis_dwidth_cmd_M_AXIS [get_bd_intf_pins axis_dwidth_cmd/M_AXIS] [get_bd_intf_pins axis_fifo_cmd/S_AXIS]
  connect_bd_intf_net -intf_net axis_fifo_cmd_M_AXIS [get_bd_intf_pins axis_fifo_cmd/M_AXIS] [get_bd_intf_pins axis_cmd_packet_router_0/S_AXIS]
  connect_bd_intf_net -intf_net axis_telemetry_data_manager_0_M_AXIS_O [get_bd_intf_pins axis_telemetry_data_manager_0/M_AXIS_O] [get_bd_intf_pins axi_dma_tm/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net cmd_smartconnect_data_M00_AXI [get_bd_intf_pins cmd_smartconnect_data/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e/S_AXI_HPC0_FPD]
  connect_bd_intf_net -intf_net ddr4_C0_DDR4 [get_bd_intf_ports C0_DDR4] [get_bd_intf_pins ddr4/C0_DDR4]
  connect_bd_intf_net -intf_net smartconnect_00_M00_AXI [get_bd_intf_pins smartconnect_00/M00_AXI] [get_bd_intf_pins system_management_wiz/S_AXI_LITE]
  connect_bd_intf_net -intf_net smartconnect_00_M01_AXI [get_bd_intf_pins smartconnect_00/M01_AXI] [get_bd_intf_pins led/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_00_M02_AXI [get_bd_intf_pins smartconnect_00/M02_AXI] [get_bd_intf_pins axi_dma_cmd/S_AXI_LITE]
  connect_bd_intf_net -intf_net smartconnect_00_M03_AXI [get_bd_intf_pins smartconnect_00/M03_AXI] [get_bd_intf_pins axis_spike_programmer_0/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_00_M04_AXI [get_bd_intf_pins smartconnect_00/M04_AXI] [get_bd_intf_pins axi_dma_tm/S_AXI_LITE]
  connect_bd_intf_net -intf_net zynq_ultra_ps_e_GMII_ENET1 [get_bd_intf_ports GMII] [get_bd_intf_pins zynq_ultra_ps_e/GMII_ENET1]
  connect_bd_intf_net -intf_net zynq_ultra_ps_e_IIC_1 [get_bd_intf_ports IIC] [get_bd_intf_pins zynq_ultra_ps_e/IIC_1]
  connect_bd_intf_net -intf_net zynq_ultra_ps_e_MDIO_ENET1 [get_bd_intf_ports MDIO] [get_bd_intf_pins zynq_ultra_ps_e/MDIO_ENET1]
  connect_bd_intf_net -intf_net zynq_ultra_ps_e_M_AXI_HPM0_LPD [get_bd_intf_pins zynq_ultra_ps_e/M_AXI_HPM0_LPD] [get_bd_intf_pins smartconnect_00/S00_AXI]

  # Create port connections
  connect_bd_net -net ADC3_DOUTA_I_1  [get_bd_pins ad7266_adc3_sine_model/ADC_DOUTA_O] \
  [get_bd_pins ad7266_adc3_driver/ADC_DOUTA_I] \
  [get_bd_pins ila_adc3_tm_debug/probe14]
  connect_bd_net -net ADC3_DOUTB_I_1  [get_bd_pins ad7266_adc3_sine_model/ADC_DOUTB_O] \
  [get_bd_pins ad7266_adc3_driver/ADC_DOUTB_I] \
  [get_bd_pins ila_adc3_tm_debug/probe15]
  connect_bd_net -net ARESETN_1  [get_bd_pins ddr4_sys_rst/interconnect_aresetn] \
  [get_bd_pins axi_interconnect_0/ARESETN] \
  [get_bd_pins axi_interconnect_0/S00_ARESETN] \
  [get_bd_pins axi_interconnect_0/M00_ARESETN]
  connect_bd_net -net SPIKE_CHIP_Q_1  [get_bd_ports SPIKE_CHIP_Q] \
  [get_bd_pins axis_spike_programmer_0/CHIP_Q_I]
  connect_bd_net -net ad7266_adc1_driver_ADC_A_O  [get_bd_pins ad7266_adc1_driver/ADC_A_O]
  connect_bd_net -net ad7266_adc1_driver_ADC_CS_O  [get_bd_pins ad7266_adc1_driver/ADC_CS_O]
  connect_bd_net -net ad7266_adc1_driver_ADC_SCLK_O  [get_bd_pins ad7266_adc1_driver/ADC_SCLK_O]
  connect_bd_net -net ad7266_adc1_driver_M_AXIS_TDATA_O  [get_bd_pins ad7266_adc1_driver/M_AXIS_TDATA_O] \
  [get_bd_pins axis_telemetry_data_manager_0/S_ADC1_TDATA_I]
  connect_bd_net -net ad7266_adc1_driver_M_AXIS_TLAST_O  [get_bd_pins ad7266_adc1_driver/M_AXIS_TLAST_O] \
  [get_bd_pins axis_telemetry_data_manager_0/S_ADC1_TLAST_I]
  connect_bd_net -net ad7266_adc1_driver_M_AXIS_TVALID_O  [get_bd_pins ad7266_adc1_driver/M_AXIS_TVALID_O] \
  [get_bd_pins axis_telemetry_data_manager_0/S_ADC1_TVALID_I]
  connect_bd_net -net ad7266_adc1_driver_S_CMD_TREADY_O  [get_bd_pins ad7266_adc1_driver/S_CMD_TREADY_O] \
  [get_bd_pins axis_cmd_packet_router_0/M_ADC1_TREADY]
  connect_bd_net -net ad7266_adc2_driver_ADC_A_O  [get_bd_pins ad7266_adc2_driver/ADC_A_O]
  connect_bd_net -net ad7266_adc2_driver_ADC_CS_O  [get_bd_pins ad7266_adc2_driver/ADC_CS_O]
  connect_bd_net -net ad7266_adc2_driver_ADC_SCLK_O  [get_bd_pins ad7266_adc2_driver/ADC_SCLK_O]
  connect_bd_net -net ad7266_adc2_driver_M_AXIS_TDATA_O  [get_bd_pins ad7266_adc2_driver/M_AXIS_TDATA_O] \
  [get_bd_pins axis_telemetry_data_manager_0/S_ADC2_TDATA_I]
  connect_bd_net -net ad7266_adc2_driver_M_AXIS_TLAST_O  [get_bd_pins ad7266_adc2_driver/M_AXIS_TLAST_O] \
  [get_bd_pins axis_telemetry_data_manager_0/S_ADC2_TLAST_I]
  connect_bd_net -net ad7266_adc2_driver_M_AXIS_TVALID_O  [get_bd_pins ad7266_adc2_driver/M_AXIS_TVALID_O] \
  [get_bd_pins axis_telemetry_data_manager_0/S_ADC2_TVALID_I]
  connect_bd_net -net ad7266_adc2_driver_S_CMD_TREADY_O  [get_bd_pins ad7266_adc2_driver/S_CMD_TREADY_O] \
  [get_bd_pins axis_cmd_packet_router_0/M_ADC2_TREADY]
  connect_bd_net -net ad7266_adc3_driver_ACTIVE_MASK_O  [get_bd_pins ad7266_adc3_driver/ACTIVE_MASK_O] \
  [get_bd_pins ila_adc3_tm_debug/probe4]
  connect_bd_net -net ad7266_adc3_driver_ADC_A_O  [get_bd_pins ad7266_adc3_driver/ADC_A_O] \
  [get_bd_pins ila_adc3_tm_debug/probe13] \
  [get_bd_pins ad7266_adc3_sine_model/ADC_A_I]
  connect_bd_net -net ad7266_adc3_driver_ADC_CS_O  [get_bd_pins ad7266_adc3_driver/ADC_CS_O] \
  [get_bd_pins ila_adc3_tm_debug/probe11] \
  [get_bd_pins ad7266_adc3_sine_model/ADC_CS_I]
  connect_bd_net -net ad7266_adc3_driver_ADC_SCLK_O  [get_bd_pins ad7266_adc3_driver/ADC_SCLK_O] \
  [get_bd_pins ila_adc3_tm_debug/probe12] \
  [get_bd_pins ad7266_adc3_sine_model/ADC_SCLK_I]
  connect_bd_net -net ad7266_adc3_driver_BUSY_O  [get_bd_pins ad7266_adc3_driver/BUSY_O] \
  [get_bd_pins ila_adc3_tm_debug/probe5]
  connect_bd_net -net ad7266_adc3_driver_M_AXIS_TDATA_O  [get_bd_pins ad7266_adc3_driver/M_AXIS_TDATA_O] \
  [get_bd_pins axis_telemetry_data_manager_0/S_ADC3_TDATA_I] \
  [get_bd_pins ila_adc3_tm_debug/probe10]
  connect_bd_net -net ad7266_adc3_driver_M_AXIS_TLAST_O  [get_bd_pins ad7266_adc3_driver/M_AXIS_TLAST_O] \
  [get_bd_pins axis_telemetry_data_manager_0/S_ADC3_TLAST_I] \
  [get_bd_pins ila_adc3_tm_debug/probe9]
  connect_bd_net -net ad7266_adc3_driver_M_AXIS_TVALID_O  [get_bd_pins ad7266_adc3_driver/M_AXIS_TVALID_O] \
  [get_bd_pins axis_telemetry_data_manager_0/S_ADC3_TVALID_I] \
  [get_bd_pins ila_adc3_tm_debug/probe7]
  connect_bd_net -net ad7266_adc3_driver_SAMPLE_VALID_PULSE_O  [get_bd_pins ad7266_adc3_driver/SAMPLE_VALID_PULSE_O] \
  [get_bd_pins ila_adc3_tm_debug/probe6]
  connect_bd_net -net ad7266_adc3_driver_S_CMD_TREADY_O  [get_bd_pins ad7266_adc3_driver/S_CMD_TREADY_O] \
  [get_bd_pins axis_cmd_packet_router_0/M_ADC3_TREADY] \
  [get_bd_pins ila_adc3_tm_debug/probe1]
  connect_bd_net -net ad7266_adc3_sine_model_CONVERSION_PULSE_O  [get_bd_pins ad7266_adc3_sine_model/CONVERSION_PULSE_O] \
  [get_bd_pins ila_adc3_tm_debug/probe16]
  connect_bd_net -net ad7266_adc3_sine_model_SAMPLE_A_DEBUG_O  [get_bd_pins ad7266_adc3_sine_model/SAMPLE_A_DEBUG_O] \
  [get_bd_pins ila_adc3_tm_debug/probe17]
  connect_bd_net -net ad7266_adc3_sine_model_SAMPLE_B_DEBUG_O  [get_bd_pins ad7266_adc3_sine_model/SAMPLE_B_DEBUG_O] \
  [get_bd_pins ila_adc3_tm_debug/probe18]
  connect_bd_net -net ad7266_adc4_driver_ADC_A_O  [get_bd_pins ad7266_adc4_driver/ADC_A_O]
  connect_bd_net -net ad7266_adc4_driver_ADC_CS_O  [get_bd_pins ad7266_adc4_driver/ADC_CS_O]
  connect_bd_net -net ad7266_adc4_driver_ADC_SCLK_O  [get_bd_pins ad7266_adc4_driver/ADC_SCLK_O]
  connect_bd_net -net ad7266_adc4_driver_M_AXIS_TDATA_O  [get_bd_pins ad7266_adc4_driver/M_AXIS_TDATA_O] \
  [get_bd_pins axis_telemetry_data_manager_0/S_ADC4_TDATA_I]
  connect_bd_net -net ad7266_adc4_driver_M_AXIS_TLAST_O  [get_bd_pins ad7266_adc4_driver/M_AXIS_TLAST_O] \
  [get_bd_pins axis_telemetry_data_manager_0/S_ADC4_TLAST_I]
  connect_bd_net -net ad7266_adc4_driver_M_AXIS_TVALID_O  [get_bd_pins ad7266_adc4_driver/M_AXIS_TVALID_O] \
  [get_bd_pins axis_telemetry_data_manager_0/S_ADC4_TVALID_I]
  connect_bd_net -net ad7266_adc4_driver_S_CMD_TREADY_O  [get_bd_pins ad7266_adc4_driver/S_CMD_TREADY_O] \
  [get_bd_pins axis_cmd_packet_router_0/M_ADC4_TREADY]
  connect_bd_net -net adc_dout_zero_1_dout  [get_bd_pins adc_dout_zero_1/dout] \
  [get_bd_pins ad7266_adc1_driver/ADC_DOUTA_I] \
  [get_bd_pins ad7266_adc1_driver/ADC_DOUTB_I] \
  [get_bd_pins ad7266_adc2_driver/ADC_DOUTA_I] \
  [get_bd_pins ad7266_adc2_driver/ADC_DOUTB_I] \
  [get_bd_pins ad7266_adc4_driver/ADC_DOUTA_I] \
  [get_bd_pins ad7266_adc4_driver/ADC_DOUTB_I]
  connect_bd_net -net axi_dma_cmd_mm2s_introut  [get_bd_pins axi_dma_cmd/mm2s_introut] \
  [get_bd_pins cmd_irq_concat/In0]
  connect_bd_net -net axi_dma_tm_s_axis_s2mm_tready1  [get_bd_pins axi_dma_tm/s_axis_s2mm_tready] \
  [get_bd_pins axis_telemetry_data_manager_0/M_AXIS_TREADY_I] \
  [get_bd_pins ila_adc3_tm_debug/probe20]
  connect_bd_net -net axis_cmd_packet_router_0_BAD_VERSION  [get_bd_pins axis_cmd_packet_router_0/BAD_VERSION]
  connect_bd_net -net axis_cmd_packet_router_0_CURRENT_ROUTE  [get_bd_pins axis_cmd_packet_router_0/CURRENT_ROUTE]
  connect_bd_net -net axis_cmd_packet_router_0_INVALID_ID  [get_bd_pins axis_cmd_packet_router_0/INVALID_ID]
  connect_bd_net -net axis_cmd_packet_router_0_LENGTH_MISMATCH  [get_bd_pins axis_cmd_packet_router_0/LENGTH_MISMATCH]
  connect_bd_net -net axis_cmd_packet_router_0_M_ADC1_TDATA  [get_bd_pins axis_cmd_packet_router_0/M_ADC1_TDATA] \
  [get_bd_pins ad7266_adc1_driver/S_CMD_TDATA_I]
  connect_bd_net -net axis_cmd_packet_router_0_M_ADC1_TLAST  [get_bd_pins axis_cmd_packet_router_0/M_ADC1_TLAST] \
  [get_bd_pins ad7266_adc1_driver/S_CMD_TLAST_I]
  connect_bd_net -net axis_cmd_packet_router_0_M_ADC1_TVALID  [get_bd_pins axis_cmd_packet_router_0/M_ADC1_TVALID] \
  [get_bd_pins ad7266_adc1_driver/S_CMD_TVALID_I]
  connect_bd_net -net axis_cmd_packet_router_0_M_ADC2_TDATA  [get_bd_pins axis_cmd_packet_router_0/M_ADC2_TDATA] \
  [get_bd_pins ad7266_adc2_driver/S_CMD_TDATA_I]
  connect_bd_net -net axis_cmd_packet_router_0_M_ADC2_TLAST  [get_bd_pins axis_cmd_packet_router_0/M_ADC2_TLAST] \
  [get_bd_pins ad7266_adc2_driver/S_CMD_TLAST_I]
  connect_bd_net -net axis_cmd_packet_router_0_M_ADC2_TVALID  [get_bd_pins axis_cmd_packet_router_0/M_ADC2_TVALID] \
  [get_bd_pins ad7266_adc2_driver/S_CMD_TVALID_I]
  connect_bd_net -net axis_cmd_packet_router_0_M_ADC3_TDATA  [get_bd_pins axis_cmd_packet_router_0/M_ADC3_TDATA] \
  [get_bd_pins ad7266_adc3_driver/S_CMD_TDATA_I] \
  [get_bd_pins ila_adc3_tm_debug/probe3]
  connect_bd_net -net axis_cmd_packet_router_0_M_ADC3_TLAST  [get_bd_pins axis_cmd_packet_router_0/M_ADC3_TLAST] \
  [get_bd_pins ad7266_adc3_driver/S_CMD_TLAST_I] \
  [get_bd_pins ila_adc3_tm_debug/probe2]
  connect_bd_net -net axis_cmd_packet_router_0_M_ADC3_TVALID  [get_bd_pins axis_cmd_packet_router_0/M_ADC3_TVALID] \
  [get_bd_pins ad7266_adc3_driver/S_CMD_TVALID_I] \
  [get_bd_pins ila_adc3_tm_debug/probe0]
  connect_bd_net -net axis_cmd_packet_router_0_M_ADC4_TDATA  [get_bd_pins axis_cmd_packet_router_0/M_ADC4_TDATA] \
  [get_bd_pins ad7266_adc4_driver/S_CMD_TDATA_I]
  connect_bd_net -net axis_cmd_packet_router_0_M_ADC4_TLAST  [get_bd_pins axis_cmd_packet_router_0/M_ADC4_TLAST] \
  [get_bd_pins ad7266_adc4_driver/S_CMD_TLAST_I]
  connect_bd_net -net axis_cmd_packet_router_0_M_ADC4_TVALID  [get_bd_pins axis_cmd_packet_router_0/M_ADC4_TVALID] \
  [get_bd_pins ad7266_adc4_driver/S_CMD_TVALID_I]
  connect_bd_net -net axis_cmd_packet_router_0_M_SPIKE_TDATA  [get_bd_pins axis_cmd_packet_router_0/M_SPIKE_TDATA] \
  [get_bd_pins axis_spike_programmer_0/S_AXIS_TDATA]
  connect_bd_net -net axis_cmd_packet_router_0_M_SPIKE_TKEEP  [get_bd_pins axis_cmd_packet_router_0/M_SPIKE_TKEEP] \
  [get_bd_pins axis_spike_programmer_0/S_AXIS_TKEEP]
  connect_bd_net -net axis_cmd_packet_router_0_M_SPIKE_TLAST  [get_bd_pins axis_cmd_packet_router_0/M_SPIKE_TLAST] \
  [get_bd_pins axis_spike_programmer_0/S_AXIS_TLAST]
  connect_bd_net -net axis_cmd_packet_router_0_M_SPIKE_TVALID  [get_bd_pins axis_cmd_packet_router_0/M_SPIKE_TVALID] \
  [get_bd_pins axis_spike_programmer_0/S_AXIS_TVALID]
  connect_bd_net -net axis_cmd_packet_router_0_PACKET_DONE  [get_bd_pins axis_cmd_packet_router_0/PACKET_DONE]
  connect_bd_net -net axis_spike_programmer_0_CHIP_CLK_O  [get_bd_pins axis_spike_programmer_0/CHIP_CLK_O] \
  [get_bd_ports SPIKE_CHIP_CLK]
  connect_bd_net -net axis_spike_programmer_0_CHIP_DATA_O  [get_bd_pins axis_spike_programmer_0/CHIP_DATA_O] \
  [get_bd_ports SPIKE_CHIP_DATA]
  connect_bd_net -net axis_spike_programmer_0_CHIP_ENABLE_O  [get_bd_pins axis_spike_programmer_0/CHIP_ENABLE_O] \
  [get_bd_ports SPIKE_CHIP_ENABLE]
  connect_bd_net -net axis_spike_programmer_0_CHIP_LATCH_O  [get_bd_pins axis_spike_programmer_0/CHIP_LATCH_O] \
  [get_bd_ports SPIKE_CHIP_LATCH]
  connect_bd_net -net axis_spike_programmer_0_SUCCESS_LED_O  [get_bd_pins axis_spike_programmer_0/SUCCESS_LED_O] \
  [get_bd_ports SPIKE_SUCCESS_LED]
  connect_bd_net -net axis_spike_programmer_0_S_AXIS_TREADY  [get_bd_pins axis_spike_programmer_0/S_AXIS_TREADY] \
  [get_bd_pins axis_cmd_packet_router_0/M_SPIKE_TREADY]
  connect_bd_net -net axis_telemetry_data_manager_0_M_AXIS_TDATA_O  [get_bd_pins axis_telemetry_data_manager_0/M_AXIS_TDATA_O] \
  [get_bd_pins ila_adc3_tm_debug/probe22] \
  [get_bd_pins axi_dma_tm/s_axis_s2mm_tdata]
  connect_bd_net -net axis_telemetry_data_manager_0_M_AXIS_TLAST_O  [get_bd_pins axis_telemetry_data_manager_0/M_AXIS_TLAST_O] \
  [get_bd_pins ila_adc3_tm_debug/probe21] \
  [get_bd_pins axi_dma_tm/s_axis_s2mm_tlast]
  connect_bd_net -net axis_telemetry_data_manager_0_M_AXIS_TVALID_O  [get_bd_pins axis_telemetry_data_manager_0/M_AXIS_TVALID_O] \
  [get_bd_pins ila_adc3_tm_debug/probe19] \
  [get_bd_pins axi_dma_tm/s_axis_s2mm_tvalid]
  connect_bd_net -net axis_telemetry_data_manager_0_S_ADC1_TREADY_O  [get_bd_pins axis_telemetry_data_manager_0/S_ADC1_TREADY_O] \
  [get_bd_pins ad7266_adc1_driver/M_AXIS_TREADY_I]
  connect_bd_net -net axis_telemetry_data_manager_0_S_ADC2_TREADY_O  [get_bd_pins axis_telemetry_data_manager_0/S_ADC2_TREADY_O] \
  [get_bd_pins ad7266_adc2_driver/M_AXIS_TREADY_I]
  connect_bd_net -net axis_telemetry_data_manager_0_S_ADC3_TREADY_O  [get_bd_pins axis_telemetry_data_manager_0/S_ADC3_TREADY_O] \
  [get_bd_pins ad7266_adc3_driver/M_AXIS_TREADY_I] \
  [get_bd_pins ila_adc3_tm_debug/probe8]
  connect_bd_net -net axis_telemetry_data_manager_0_S_ADC4_TREADY_O  [get_bd_pins axis_telemetry_data_manager_0/S_ADC4_TREADY_O] \
  [get_bd_pins ad7266_adc4_driver/M_AXIS_TREADY_I]
  connect_bd_net -net clk_wiz_gmii2rgmii_clk_out1  [get_bd_pins clk_wiz_gmii2rgmii/clk_out1] \
  [get_bd_ports ETH_CLK125]
  connect_bd_net -net clk_wiz_gmii2rgmii_clk_out2  [get_bd_pins clk_wiz_gmii2rgmii/clk_out2] \
  [get_bd_ports ETH_CLK125_90]
  connect_bd_net -net clk_wiz_gmii2rgmii_clk_out3  [get_bd_pins clk_wiz_gmii2rgmii/clk_out3] \
  [get_bd_ports ETH_CLK25]
  connect_bd_net -net clk_wiz_gmii2rgmii_clk_out4  [get_bd_pins clk_wiz_gmii2rgmii/clk_out4] \
  [get_bd_ports ETH_CLK10]
  connect_bd_net -net clk_wiz_gmii2rgmii_locked  [get_bd_pins clk_wiz_gmii2rgmii/locked] \
  [get_bd_ports ETH_resetn]
  connect_bd_net -net cmd_tready_const_dout  [get_bd_pins cmd_tready_const/dout] \
  [get_bd_pins axis_cmd_packet_router_0/M_DAC1_TREADY] \
  [get_bd_pins axis_cmd_packet_router_0/M_DAC2_TREADY] \
  [get_bd_pins axis_cmd_packet_router_0/M_DAC3_TREADY] \
  [get_bd_pins axis_cmd_packet_router_0/M_DAC4_TREADY]
  connect_bd_net -net dac8568_driver_1_DAC_CLR_N_O  [get_bd_pins dac8568_driver_1/DAC_CLR_N_O] \
  [get_bd_ports DAC1_CLR_N]
  connect_bd_net -net dac8568_driver_1_DAC_DIN_O  [get_bd_pins dac8568_driver_1/DAC_DIN_O] \
  [get_bd_ports DAC1_DIN]
  connect_bd_net -net dac8568_driver_1_DAC_LDAC_N_O  [get_bd_pins dac8568_driver_1/DAC_LDAC_N_O] \
  [get_bd_ports DAC1_LDAC_N]
  connect_bd_net -net dac8568_driver_1_DAC_SCLK_O  [get_bd_pins dac8568_driver_1/DAC_SCLK_O] \
  [get_bd_ports DAC1_SCLK]
  connect_bd_net -net dac8568_driver_1_DAC_SYNC_N_O  [get_bd_pins dac8568_driver_1/DAC_SYNC_N_O] \
  [get_bd_ports DAC1_SYNC_N]
  connect_bd_net -net dac8568_driver_2_DAC_CLR_N_O  [get_bd_pins dac8568_driver_2/DAC_CLR_N_O] \
  [get_bd_ports DAC2_CLR_N]
  connect_bd_net -net dac8568_driver_2_DAC_DIN_O  [get_bd_pins dac8568_driver_2/DAC_DIN_O] \
  [get_bd_ports DAC2_DIN]
  connect_bd_net -net dac8568_driver_2_DAC_LDAC_N_O  [get_bd_pins dac8568_driver_2/DAC_LDAC_N_O] \
  [get_bd_ports DAC2_LDAC_N]
  connect_bd_net -net dac8568_driver_2_DAC_SCLK_O  [get_bd_pins dac8568_driver_2/DAC_SCLK_O] \
  [get_bd_ports DAC2_SCLK]
  connect_bd_net -net dac8568_driver_2_DAC_SYNC_N_O  [get_bd_pins dac8568_driver_2/DAC_SYNC_N_O] \
  [get_bd_ports DAC2_SYNC_N]
  connect_bd_net -net dac8568_driver_3_DAC_CLR_N_O  [get_bd_pins dac8568_driver_3/DAC_CLR_N_O] \
  [get_bd_ports DAC3_CLR_N]
  connect_bd_net -net dac8568_driver_3_DAC_DIN_O  [get_bd_pins dac8568_driver_3/DAC_DIN_O] \
  [get_bd_ports DAC3_DIN]
  connect_bd_net -net dac8568_driver_3_DAC_LDAC_N_O  [get_bd_pins dac8568_driver_3/DAC_LDAC_N_O] \
  [get_bd_ports DAC3_LDAC_N]
  connect_bd_net -net dac8568_driver_3_DAC_SCLK_O  [get_bd_pins dac8568_driver_3/DAC_SCLK_O] \
  [get_bd_ports DAC3_SCLK]
  connect_bd_net -net dac8568_driver_3_DAC_SYNC_N_O  [get_bd_pins dac8568_driver_3/DAC_SYNC_N_O] \
  [get_bd_ports DAC3_SYNC_N]
  connect_bd_net -net dac8568_driver_4_DAC_CLR_N_O  [get_bd_pins dac8568_driver_4/DAC_CLR_N_O] \
  [get_bd_ports DAC4_CLR_N]
  connect_bd_net -net dac8568_driver_4_DAC_DIN_O  [get_bd_pins dac8568_driver_4/DAC_DIN_O] \
  [get_bd_ports DAC4_DIN]
  connect_bd_net -net dac8568_driver_4_DAC_LDAC_N_O  [get_bd_pins dac8568_driver_4/DAC_LDAC_N_O] \
  [get_bd_ports DAC4_LDAC_N]
  connect_bd_net -net dac8568_driver_4_DAC_SCLK_O  [get_bd_pins dac8568_driver_4/DAC_SCLK_O] \
  [get_bd_ports DAC4_SCLK]
  connect_bd_net -net dac8568_driver_4_DAC_SYNC_N_O  [get_bd_pins dac8568_driver_4/DAC_SYNC_N_O] \
  [get_bd_ports DAC4_SYNC_N]
  connect_bd_net -net ddr4_c0_ddr4_ui_clk  [get_bd_pins ddr4/c0_ddr4_ui_clk] \
  [get_bd_pins zynq_ultra_ps_e/maxihpm0_fpd_aclk] \
  [get_bd_pins ddr4_sys_rst/slowest_sync_clk] \
  [get_bd_pins axi_interconnect_0/ACLK] \
  [get_bd_pins axi_interconnect_0/S00_ACLK] \
  [get_bd_pins axi_interconnect_0/M00_ACLK]
  connect_bd_net -net ddr4_sys_rst_peripheral_aresetn  [get_bd_pins ddr4_sys_rst/peripheral_aresetn] \
  [get_bd_pins ddr4/c0_ddr4_aresetn]
  connect_bd_net -net ddr4_sys_rst_peripheral_reset  [get_bd_pins ddr4_sys_rst/peripheral_reset] \
  [get_bd_pins ddr4/sys_rst]
  connect_bd_net -net dm_const_one_1_dout  [get_bd_pins dm_const_one_1/dout]
  connect_bd_net -net dm_const_zero_1_dout  [get_bd_pins dm_const_zero_1/dout] \
  [get_bd_pins axis_telemetry_data_manager_0/S_DAC1_TVALID_I] \
  [get_bd_pins axis_telemetry_data_manager_0/S_DAC1_TLAST_I] \
  [get_bd_pins axis_telemetry_data_manager_0/S_DAC2_TVALID_I] \
  [get_bd_pins axis_telemetry_data_manager_0/S_DAC2_TLAST_I] \
  [get_bd_pins axis_telemetry_data_manager_0/S_DAC3_TVALID_I] \
  [get_bd_pins axis_telemetry_data_manager_0/S_DAC3_TLAST_I] \
  [get_bd_pins axis_telemetry_data_manager_0/S_DAC4_TVALID_I] \
  [get_bd_pins axis_telemetry_data_manager_0/S_DAC4_TLAST_I] \
  [get_bd_pins axis_telemetry_data_manager_0/S_HPU_TVALID_I] \
  [get_bd_pins axis_telemetry_data_manager_0/S_HPU_TLAST_I]
  connect_bd_net -net dm_const_zero_8_dout  [get_bd_pins dm_const_zero_8/dout] \
  [get_bd_pins axis_telemetry_data_manager_0/S_DAC1_TDATA_I] \
  [get_bd_pins axis_telemetry_data_manager_0/S_DAC2_TDATA_I] \
  [get_bd_pins axis_telemetry_data_manager_0/S_DAC3_TDATA_I] \
  [get_bd_pins axis_telemetry_data_manager_0/S_DAC4_TDATA_I] \
  [get_bd_pins axis_telemetry_data_manager_0/S_HPU_TDATA_I]
  connect_bd_net -net fpga_timestamp_timer_16_0_TIME_O  [get_bd_pins fpga_timestamp_timer_16_0/TIME_O] \
  [get_bd_pins axis_telemetry_data_manager_0/TIME_I]
  connect_bd_net -net led_gpio_io_o  [get_bd_pins led/gpio_io_o] \
  [get_bd_ports LED_N_PL]
  connect_bd_net -net ps_sys_rst_interconnect_aresetn  [get_bd_pins ps_sys_rst/interconnect_aresetn] \
  [get_bd_pins smartconnect_00/aresetn]
  connect_bd_net -net ps_sys_rst_peripheral_aresetn  [get_bd_pins ps_sys_rst/peripheral_aresetn] \
  [get_bd_pins system_management_wiz/s_axi_aresetn] \
  [get_bd_pins led/s_axi_aresetn] \
  [get_bd_pins axi_dma_cmd/axi_resetn] \
  [get_bd_pins axis_dwidth_cmd/aresetn] \
  [get_bd_pins axis_fifo_cmd/s_axis_aresetn] \
  [get_bd_pins axis_cmd_packet_router_0/ARESETN] \
  [get_bd_pins cmd_smartconnect_data/aresetn] \
  [get_bd_pins axis_spike_programmer_0/ARESETN] \
  [get_bd_pins axi_dma_tm/axi_resetn] \
  [get_bd_pins dac8568_driver_1/ARESETN] \
  [get_bd_pins dac8568_driver_2/ARESETN] \
  [get_bd_pins dac8568_driver_3/ARESETN] \
  [get_bd_pins dac8568_driver_4/ARESETN]
  connect_bd_net -net ps_sys_rst_peripheral_reset  [get_bd_pins ps_sys_rst/peripheral_reset] \
  [get_bd_pins fpga_timestamp_timer_16_0/RST_I] \
  [get_bd_pins axis_telemetry_data_manager_0/RST_I] \
  [get_bd_pins ad7266_adc1_driver/RST_I] \
  [get_bd_pins ad7266_adc2_driver/RST_I] \
  [get_bd_pins ad7266_adc3_driver/RST_I] \
  [get_bd_pins ad7266_adc4_driver/RST_I] \
  [get_bd_pins ad7266_adc3_sine_model/RST_I]
  connect_bd_net -net system_management_wiz_ip2intc_irpt  [get_bd_pins system_management_wiz/ip2intc_irpt] \
  [get_bd_pins zynq_ultra_ps_e/pl_ps_irq0]
  connect_bd_net -net timer_enable_const_dout  [get_bd_pins timer_enable_const/dout] \
  [get_bd_pins fpga_timestamp_timer_16_0/ENABLE_I]
  connect_bd_net -net tm_tkeep_const_1_dout  [get_bd_pins tm_tkeep_const_1/dout] \
  [get_bd_pins axi_dma_tm/s_axis_s2mm_tkeep]
  connect_bd_net -net zynq_ultra_ps_e_pl_clk0  [get_bd_pins zynq_ultra_ps_e/pl_clk0] \
  [get_bd_pins zynq_ultra_ps_e/maxihpm0_lpd_aclk] \
  [get_bd_pins ps_sys_rst/slowest_sync_clk] \
  [get_bd_pins smartconnect_00/aclk] \
  [get_bd_pins system_management_wiz/s_axi_aclk] \
  [get_bd_pins led/s_axi_aclk] \
  [get_bd_pins axi_dma_cmd/s_axi_lite_aclk] \
  [get_bd_pins axi_dma_cmd/m_axi_mm2s_aclk] \
  [get_bd_pins axis_dwidth_cmd/aclk] \
  [get_bd_pins axis_fifo_cmd/s_axis_aclk] \
  [get_bd_pins axis_cmd_packet_router_0/ACLK] \
  [get_bd_pins cmd_smartconnect_data/aclk] \
  [get_bd_pins zynq_ultra_ps_e/saxihpc0_fpd_aclk] \
  [get_bd_pins axis_spike_programmer_0/ACLK] \
  [get_bd_pins fpga_timestamp_timer_16_0/CLK_I] \
  [get_bd_pins axis_telemetry_data_manager_0/CLK_I] \
  [get_bd_pins ad7266_adc1_driver/CLK_I] \
  [get_bd_pins ad7266_adc2_driver/CLK_I] \
  [get_bd_pins ad7266_adc3_driver/CLK_I] \
  [get_bd_pins ad7266_adc4_driver/CLK_I] \
  [get_bd_pins axi_dma_tm/s_axi_lite_aclk] \
  [get_bd_pins axi_dma_tm/m_axi_s2mm_aclk] \
  [get_bd_pins ila_adc3_tm_debug/clk] \
  [get_bd_pins dac8568_driver_1/ACLK] \
  [get_bd_pins dac8568_driver_2/ACLK] \
  [get_bd_pins dac8568_driver_3/ACLK] \
  [get_bd_pins dac8568_driver_4/ACLK] \
  [get_bd_pins ad7266_adc3_sine_model/CLK_I]
  connect_bd_net -net zynq_ultra_ps_e_pl_clk1  [get_bd_pins zynq_ultra_ps_e/pl_clk1] \
  [get_bd_pins clk_wiz_gmii2rgmii/clk_in1]
  connect_bd_net -net zynq_ultra_ps_e_pl_resetn0  [get_bd_pins zynq_ultra_ps_e/pl_resetn0] \
  [get_bd_pins ps_sys_rst/ext_reset_in] \
  [get_bd_pins ddr4_sys_rst/ext_reset_in] \
  [get_bd_pins clk_wiz_gmii2rgmii/resetn] \
  [get_bd_ports Rst_N]

  # Create address segments
  assign_bd_address -offset 0x80020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e/Data] [get_bd_addr_segs axi_dma_cmd/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x80040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e/Data] [get_bd_addr_segs axi_dma_tm/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x80030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e/Data] [get_bd_addr_segs axis_spike_programmer_0/S_AXI/reg0] -force
  assign_bd_address -offset 0x000400000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e/Data] [get_bd_addr_segs ddr4/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x80000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e/Data] [get_bd_addr_segs led/S_AXI/Reg] -force
  assign_bd_address -offset 0x80010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e/Data] [get_bd_addr_segs system_management_wiz/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_dma_cmd/Data_MM2S] [get_bd_addr_segs zynq_ultra_ps_e/SAXIGP0/HPC0_DDR_LOW] -force
  assign_bd_address -offset 0xC0000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces axi_dma_cmd/Data_MM2S] [get_bd_addr_segs zynq_ultra_ps_e/SAXIGP0/HPC0_QSPI] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_dma_tm/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps_e/SAXIGP0/HPC0_DDR_LOW] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces axi_dma_cmd/Data_MM2S] [get_bd_addr_segs zynq_ultra_ps_e/SAXIGP0/HPC0_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces axi_dma_cmd/Data_MM2S] [get_bd_addr_segs zynq_ultra_ps_e/SAXIGP0/HPC0_LPS_OCM]


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


