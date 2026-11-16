set(AXIETHERNET_NUM_DRIVER_INSTANCES "")
set(EMACLITE_NUM_DRIVER_INSTANCES "")
set(EMACPS_NUM_DRIVER_INSTANCES "psu_ethernet_0;psu_ethernet_1")
set(EMACPS0_PROP_LIST "0xff0b0000;0x4039")
list(APPEND TOTAL_EMACPS_PROP_LIST EMACPS0_PROP_LIST)
set(EMACPS1_PROP_LIST "0xff0c0000;0x403b")
list(APPEND TOTAL_EMACPS_PROP_LIST EMACPS1_PROP_LIST)
set(TMRCTR_NUM_DRIVER_INSTANCES "")
set(TTCPS_NUM_DRIVER_INSTANCES "psu_ttc_0")
set(TTCPS0_PROP_LIST "0xff110000;0x4024")
list(APPEND TOTAL_TTCPS_PROP_LIST TTCPS0_PROP_LIST)
set(psu_ddr_1_memory_1 "0x800000000;0x80000000")
set(psu_ddr_0_memory_0 "0x0;0x7ff00000")
set(ddr4_memory_0 "0x400000000;0x40000000")
set(psu_ocm_ram_0_memory_0 "0xfffc0000;0x40000")
set(DDR psu_ddr_0_memory_0)
set(CODE psu_ddr_0_memory_0)
set(DATA psu_ddr_0_memory_0)
set(TOTAL_MEM_CONTROLLERS "psu_ddr_1_memory_1;psu_ddr_0_memory_0;ddr4_memory_0;psu_ocm_ram_0_memory_0")
set(MEMORY_SECTION "MEMORY
{
	psu_ddr_1_memory_1 : ORIGIN = 0x800000000, LENGTH = 0x80000000
	psu_ddr_0_memory_0 : ORIGIN = 0x0, LENGTH = 0x7ff00000
	ddr4_memory_0 : ORIGIN = 0x400000000, LENGTH = 0x40000000
	psu_qspi_linear_0_memory_0 : ORIGIN = 0xc0000000, LENGTH = 0x20000000
	psu_ocm_ram_0_memory_0 : ORIGIN = 0xfffc0000, LENGTH = 0x40000
}")
set(STACK_SIZE 0xa000)
set(HEAP_SIZE 0xa000)
