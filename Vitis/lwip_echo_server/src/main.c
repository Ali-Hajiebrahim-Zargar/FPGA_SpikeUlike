/*
 * Copyright (C) 2009 - 2022 Xilinx, Inc.
 * Copyright (C) 2022 - 2024 Advanced Micro Devices, Inc.
 * All rights reserved.
 *
 * Modified for Mercury XU5 PE1 UDP -> AXI DMA MM2S -> PL CMD router test.
 * Debug version with Enclustra MacConfig_SgmiiPcs stub.
 * Updated for AXIS_SPIKE_PROGRAMMER AXI-Lite configuration.
 * Updated for AXI DMA S2MM telemetry path.
 */

#include <stdio.h>

#include "xparameters.h"
#include "xstatus.h"
#include "xaxidma.h"

#include "netif/xadapter.h"

#include "platform.h"
#include "platform_config.h"
#include "xil_printf.h"
#include "xil_cache.h"
#include "xil_io.h"
#include "xil_types.h"

#include "lwip/tcp.h"

#if LWIP_IPV6==1
#include "lwip/ip.h"
#else
#if LWIP_DHCP==1
#include "lwip/dhcp.h"
#endif
#endif

void print_app_header();
int start_application();
int transfer_data();
void tcp_fasttmr(void);
void tcp_slowtmr(void);

void lwip_init();

#if LWIP_IPV6==0
#if LWIP_DHCP==1
extern volatile int dhcp_timoutcntr;
err_t dhcp_start(struct netif *netif);
#endif
#endif

extern volatile int TcpFastTmrFlag;
extern volatile int TcpSlowTmrFlag;

static struct netif server_netif;
struct netif *echo_netif;

XAxiDma AxiDmaCmd;
XAxiDma AxiDmaTm;

/*
 * Enclustra-modified lwIP may call this function from liblwip220.a.
 * In this project we do not configure a separate SGMII PCS here,
 * so this is a safe no-operation stub.
 */
void MacConfig_SgmiiPcs(void)
{
    xil_printf("INFO: MacConfig_SgmiiPcs stub called - no SGMII PCS configuration required\r\n");
}

/* -------------------------------------------------------------------------- */
/* AXI DMA CMD selection                                                       */
/* -------------------------------------------------------------------------- */

#if defined(XPAR_AXI_DMA_CMD_BASEADDR)
#define CMD_AXI_DMA_BASEADDR XPAR_AXI_DMA_CMD_BASEADDR
#elif defined(XPAR_AXI_DMA_CMD_0_BASEADDR)
#define CMD_AXI_DMA_BASEADDR XPAR_AXI_DMA_CMD_0_BASEADDR
#elif defined(XPAR_XAXIDMA_0_BASEADDR)
#define CMD_AXI_DMA_BASEADDR XPAR_XAXIDMA_0_BASEADDR
#elif defined(XPAR_XAXIDMA_1_BASEADDR)
#define CMD_AXI_DMA_BASEADDR XPAR_XAXIDMA_1_BASEADDR
#endif

#if defined(XPAR_AXI_DMA_CMD_DEVICE_ID)
#define CMD_AXI_DMA_DEVICE_ID XPAR_AXI_DMA_CMD_DEVICE_ID
#elif defined(XPAR_AXI_DMA_CMD_0_DEVICE_ID)
#define CMD_AXI_DMA_DEVICE_ID XPAR_AXI_DMA_CMD_0_DEVICE_ID
#elif defined(XPAR_XAXIDMA_0_DEVICE_ID)
#define CMD_AXI_DMA_DEVICE_ID XPAR_XAXIDMA_0_DEVICE_ID
#elif defined(XPAR_XAXIDMA_1_DEVICE_ID)
#define CMD_AXI_DMA_DEVICE_ID XPAR_XAXIDMA_1_DEVICE_ID
#endif

/* -------------------------------------------------------------------------- */
/* AXI DMA TM selection                                                        */
/* -------------------------------------------------------------------------- */

#if defined(XPAR_AXI_DMA_TM_BASEADDR)
#define TM_AXI_DMA_BASEADDR XPAR_AXI_DMA_TM_BASEADDR
#elif defined(XPAR_AXI_DMA_TM_0_BASEADDR)
#define TM_AXI_DMA_BASEADDR XPAR_AXI_DMA_TM_0_BASEADDR
#elif defined(XPAR_XAXIDMA_1_BASEADDR)
#define TM_AXI_DMA_BASEADDR XPAR_XAXIDMA_1_BASEADDR
#endif

#if defined(XPAR_AXI_DMA_TM_DEVICE_ID)
#define TM_AXI_DMA_DEVICE_ID XPAR_AXI_DMA_TM_DEVICE_ID
#elif defined(XPAR_AXI_DMA_TM_0_DEVICE_ID)
#define TM_AXI_DMA_DEVICE_ID XPAR_AXI_DMA_TM_0_DEVICE_ID
#elif defined(XPAR_XAXIDMA_1_DEVICE_ID)
#define TM_AXI_DMA_DEVICE_ID XPAR_XAXIDMA_1_DEVICE_ID
#endif

/* -------------------------------------------------------------------------- */
/* AXIS_SPIKE_PROGRAMMER AXI-Lite register map                                 */
/* -------------------------------------------------------------------------- */

#define SPIKE_PROG_BASEADDR        0x80030000U

#define SPIKE_PROG_CONTROL_OFFSET  0x00U
#define SPIKE_PROG_STATUS_OFFSET   0x04U
#define SPIKE_PROG_DIV_OFFSET      0x08U
#define SPIKE_PROG_CHIP_BITS_OFF   0x0CU
#define SPIKE_PROG_MARKER_OFFSET   0x10U
#define SPIKE_PROG_READBACK_OFFSET 0x14U
#define SPIKE_PROG_PAYLOAD_OFFSET  0x18U
#define SPIKE_PROG_TOTAL_BITS_OFF  0x1CU

#define SPIKE_PROG_CONTROL_ENABLE  0x00000001U
#define SPIKE_PROG_CONTROL_CLEAR   0x00000002U
#define SPIKE_PROG_CONTROL_ABORT   0x00000004U

#define SPIKE_STATUS_BUSY          0x00000001U
#define SPIKE_STATUS_DONE          0x00000002U
#define SPIKE_STATUS_SUCCESS       0x00000004U
#define SPIKE_STATUS_ERROR         0x00000008U
#define SPIKE_STATUS_OVERFLOW      0x00000010U
#define SPIKE_STATUS_READBACK_VAL  0x00000020U

/*
 * 100 MHz AXI clock:
 * SERIAL_DIV_HALF = 50 gives approximately 1 MHz serial clock.
 */
#define SPIKE_SERIAL_DIV_HALF      50U

/*
 * Marker byte used internally by AXIS_SPIKE_PROGRAMMER.
 */
#define SPIKE_MARKER_BYTE          0xC5U

/*
 * IMPORTANT:
 * Change this value based on the real number of bits inside your Spikeulike
 * chip / shift-register chain.
 */
#define SPIKE_CHIP_BITS            8U

static int InitCmdDma(void)
{
    XAxiDma_Config *CfgPtr = NULL;
    int Status;

#if defined(SDT)
    #if defined(CMD_AXI_DMA_BASEADDR)
    xil_printf("DBG: AXI DMA CMD lookup by base address: 0x%08lx\r\n",
               (unsigned long)CMD_AXI_DMA_BASEADDR);
    CfgPtr = XAxiDma_LookupConfig((UINTPTR)CMD_AXI_DMA_BASEADDR);
    #else
    xil_printf("ERROR: AXI DMA CMD base address macro is missing\r\n");
    return XST_FAILURE;
    #endif
#else
    #if defined(CMD_AXI_DMA_DEVICE_ID)
    xil_printf("DBG: AXI DMA CMD lookup by device ID: %lu\r\n",
               (unsigned long)CMD_AXI_DMA_DEVICE_ID);
    CfgPtr = XAxiDma_LookupConfig(CMD_AXI_DMA_DEVICE_ID);
    #elif defined(CMD_AXI_DMA_BASEADDR)
    xil_printf("DBG: AXI DMA CMD lookup fallback by base address: 0x%08lx\r\n",
               (unsigned long)CMD_AXI_DMA_BASEADDR);
    CfgPtr = XAxiDma_LookupConfig((UINTPTR)CMD_AXI_DMA_BASEADDR);
    #else
    xil_printf("ERROR: AXI DMA CMD macro is missing\r\n");
    return XST_FAILURE;
    #endif
#endif

    if (CfgPtr == NULL) {
        xil_printf("ERROR: AXI DMA CMD config not found\r\n");
        return XST_FAILURE;
    }

    xil_printf("DBG: before XAxiDma_CfgInitialize CMD\r\n");
    Status = XAxiDma_CfgInitialize(&AxiDmaCmd, CfgPtr);
    xil_printf("DBG: after XAxiDma_CfgInitialize CMD, Status=%d\r\n", Status);

    if (Status != XST_SUCCESS) {
        xil_printf("ERROR: XAxiDma_CfgInitialize CMD failed\r\n");
        return XST_FAILURE;
    }

    if (XAxiDma_HasSg(&AxiDmaCmd)) {
        xil_printf("ERROR: AXI DMA CMD is in scatter-gather mode. Simple mode is required.\r\n");
        return XST_FAILURE;
    }

    XAxiDma_IntrDisable(&AxiDmaCmd, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);

    xil_printf("AXI DMA CMD initialized successfully\r\n");
    return XST_SUCCESS;
}

static int InitTmDma(void)
{
    XAxiDma_Config *CfgPtr = NULL;
    int Status;

#if defined(SDT)
    #if defined(TM_AXI_DMA_BASEADDR)
    xil_printf("DBG: AXI DMA TM lookup by base address: 0x%08lx\r\n",
               (unsigned long)TM_AXI_DMA_BASEADDR);
    CfgPtr = XAxiDma_LookupConfig((UINTPTR)TM_AXI_DMA_BASEADDR);
    #else
    xil_printf("ERROR: AXI DMA TM base address macro is missing\r\n");
    return XST_FAILURE;
    #endif
#else
    #if defined(TM_AXI_DMA_DEVICE_ID)
    xil_printf("DBG: AXI DMA TM lookup by device ID: %lu\r\n",
               (unsigned long)TM_AXI_DMA_DEVICE_ID);
    CfgPtr = XAxiDma_LookupConfig(TM_AXI_DMA_DEVICE_ID);
    #elif defined(TM_AXI_DMA_BASEADDR)
    xil_printf("DBG: AXI DMA TM lookup fallback by base address: 0x%08lx\r\n",
               (unsigned long)TM_AXI_DMA_BASEADDR);
    CfgPtr = XAxiDma_LookupConfig((UINTPTR)TM_AXI_DMA_BASEADDR);
    #else
    xil_printf("ERROR: AXI DMA TM macro is missing\r\n");
    return XST_FAILURE;
    #endif
#endif

    if (CfgPtr == NULL) {
        xil_printf("ERROR: AXI DMA TM config not found\r\n");
        return XST_FAILURE;
    }

    xil_printf("DBG: before XAxiDma_CfgInitialize TM\r\n");
    Status = XAxiDma_CfgInitialize(&AxiDmaTm, CfgPtr);
    xil_printf("DBG: after XAxiDma_CfgInitialize TM, Status=%d\r\n", Status);

    if (Status != XST_SUCCESS) {
        xil_printf("ERROR: XAxiDma_CfgInitialize TM failed\r\n");
        return XST_FAILURE;
    }

    if (XAxiDma_HasSg(&AxiDmaTm)) {
        xil_printf("ERROR: AXI DMA TM is in scatter-gather mode. Simple mode is required.\r\n");
        return XST_FAILURE;
    }

    XAxiDma_IntrDisable(&AxiDmaTm, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);

    xil_printf("AXI DMA TM initialized successfully\r\n");
    return XST_SUCCESS;
}

static void InitSpikeProgrammer(void)
{
    u32 StatusReg;
    u32 ReadbackReg;
    u32 PayloadBytesReg;
    u32 TotalShiftBitsReg;

    xil_printf("DBG: before InitSpikeProgrammer\r\n");
    xil_printf("Initializing AXIS_SPIKE_PROGRAMMER...\r\n");

    /*
     * Disable module first.
     */
    Xil_Out32((UINTPTR)(SPIKE_PROG_BASEADDR + SPIKE_PROG_CONTROL_OFFSET),
              0x00000000U);

    /*
     * Clear old DONE / ERROR / SUCCESS flags.
     * CLEAR_STATUS is a pulse.
     */
    Xil_Out32((UINTPTR)(SPIKE_PROG_BASEADDR + SPIKE_PROG_CONTROL_OFFSET),
              SPIKE_PROG_CONTROL_CLEAR);

    Xil_Out32((UINTPTR)(SPIKE_PROG_BASEADDR + SPIKE_PROG_CONTROL_OFFSET),
              0x00000000U);

    /*
     * Configure serial clock divider.
     */
    Xil_Out32((UINTPTR)(SPIKE_PROG_BASEADDR + SPIKE_PROG_DIV_OFFSET),
              SPIKE_SERIAL_DIV_HALF);

    /*
     * Configure chip shift-chain length.
     */
    Xil_Out32((UINTPTR)(SPIKE_PROG_BASEADDR + SPIKE_PROG_CHIP_BITS_OFF),
              SPIKE_CHIP_BITS);

    /*
     * Configure marker byte.
     */
    Xil_Out32((UINTPTR)(SPIKE_PROG_BASEADDR + SPIKE_PROG_MARKER_OFFSET),
              SPIKE_MARKER_BYTE);

    /*
     * Enable module.
     */
    Xil_Out32((UINTPTR)(SPIKE_PROG_BASEADDR + SPIKE_PROG_CONTROL_OFFSET),
              SPIKE_PROG_CONTROL_ENABLE);

    StatusReg = Xil_In32((UINTPTR)(SPIKE_PROG_BASEADDR + SPIKE_PROG_STATUS_OFFSET));
    ReadbackReg = Xil_In32((UINTPTR)(SPIKE_PROG_BASEADDR + SPIKE_PROG_READBACK_OFFSET));
    PayloadBytesReg = Xil_In32((UINTPTR)(SPIKE_PROG_BASEADDR + SPIKE_PROG_PAYLOAD_OFFSET));
    TotalShiftBitsReg = Xil_In32((UINTPTR)(SPIKE_PROG_BASEADDR + SPIKE_PROG_TOTAL_BITS_OFF));

    xil_printf("AXIS_SPIKE_PROGRAMMER configured\r\n");
    xil_printf("  BASEADDR         = 0x%08lX\r\n", (unsigned long)SPIKE_PROG_BASEADDR);
    xil_printf("  SERIAL_DIV_HALF  = %lu\r\n", (unsigned long)SPIKE_SERIAL_DIV_HALF);
    xil_printf("  CHIP_BITS        = %lu\r\n", (unsigned long)SPIKE_CHIP_BITS);
    xil_printf("  MARKER_BYTE      = 0x%02lX\r\n", (unsigned long)SPIKE_MARKER_BYTE);
    xil_printf("  STATUS           = 0x%08lX\r\n", (unsigned long)StatusReg);
    xil_printf("  READBACK_BYTE    = 0x%08lX\r\n", (unsigned long)ReadbackReg);
    xil_printf("  PAYLOAD_BYTES    = 0x%08lX\r\n", (unsigned long)PayloadBytesReg);
    xil_printf("  TOTAL_SHIFT_BITS = 0x%08lX\r\n", (unsigned long)TotalShiftBitsReg);

    xil_printf("DBG: after InitSpikeProgrammer\r\n");
}

#if LWIP_IPV6==1
void print_ip6(char *msg, ip_addr_t *ip)
{
    print(msg);
    xil_printf(" %x:%x:%x:%x:%x:%x:%x:%x\n\r",
           IP6_ADDR_BLOCK1(&ip->u_addr.ip6),
           IP6_ADDR_BLOCK2(&ip->u_addr.ip6),
           IP6_ADDR_BLOCK3(&ip->u_addr.ip6),
           IP6_ADDR_BLOCK4(&ip->u_addr.ip6),
           IP6_ADDR_BLOCK5(&ip->u_addr.ip6),
           IP6_ADDR_BLOCK6(&ip->u_addr.ip6),
           IP6_ADDR_BLOCK7(&ip->u_addr.ip6),
           IP6_ADDR_BLOCK8(&ip->u_addr.ip6));
}
#else
void print_ip(char *msg, ip_addr_t *ip)
{
    print(msg);
    xil_printf("%d.%d.%d.%d\n\r",
               ip4_addr1(ip),
               ip4_addr2(ip),
               ip4_addr3(ip),
               ip4_addr4(ip));
}

void print_ip_settings(ip_addr_t *ip, ip_addr_t *mask, ip_addr_t *gw)
{
    print_ip("Board IP: ", ip);
    print_ip("Netmask : ", mask);
    print_ip("Gateway : ", gw);
}
#endif

#if defined (__arm__) && !defined (ARMR5)
#if XPAR_GIGE_PCS_PMA_SGMII_CORE_PRESENT == 1 || XPAR_GIGE_PCS_PMA_1000BASEX_CORE_PRESENT == 1
int ProgramSi5324(void);
int ProgramSfpPhy(void);
#endif
#endif

#ifdef XPS_BOARD_ZCU102
#if defined (XPAR_XIICPS_0_DEVICE_ID) || defined (XPAR_XIICPS_0_BASEADDR)
int IicPhyReset(void);
#endif
#endif

int main()
{
    xil_printf("\r\nprog start\r\n");

#if LWIP_IPV6==0
    ip_addr_t ipaddr, netmask, gw;
#endif

    unsigned char mac_ethernet_address[] =
    { 0x00, 0x0A, 0x35, 0x00, 0x01, 0x02 };

    echo_netif = &server_netif;

#if defined (__arm__) && !defined (ARMR5)
#if XPAR_GIGE_PCS_PMA_SGMII_CORE_PRESENT == 1 || XPAR_GIGE_PCS_PMA_1000BASEX_CORE_PRESENT == 1
    xil_printf("DBG: before ProgramSi5324\r\n");
    ProgramSi5324();
    xil_printf("DBG: after ProgramSi5324\r\n");

    xil_printf("DBG: before ProgramSfpPhy\r\n");
    ProgramSfpPhy();
    xil_printf("DBG: after ProgramSfpPhy\r\n");
#endif
#endif

#ifdef XPS_BOARD_ZCU102
    xil_printf("DBG: before IicPhyReset\r\n");
    if (IicPhyReset()) {
        xil_printf("ERROR: IicPhyReset failed\r\n");
        return -1;
    }
    xil_printf("DBG: after IicPhyReset\r\n");
#endif

    xil_printf("DBG: before init_platform\r\n");
    init_platform();
    xil_printf("DBG: after init_platform\r\n");

    xil_printf("UDP CMD DMA + TM DMA application started\r\n");

    xil_printf("DBG: before InitCmdDma\r\n");
    if (InitCmdDma() != XST_SUCCESS) {
        xil_printf("ERROR: InitCmdDma failed\r\n");
        return -1;
    }
    xil_printf("DBG: after InitCmdDma\r\n");

    xil_printf("DBG: before InitTmDma\r\n");
    if (InitTmDma() != XST_SUCCESS) {
        xil_printf("ERROR: InitTmDma failed\r\n");
        return -1;
    }
    xil_printf("DBG: after InitTmDma\r\n");

    /*
     * Configure the AXIS_SPIKE_PROGRAMMER AXI-Lite registers.
     * This must be done before sending UDP packets from the PC.
     */
    InitSpikeProgrammer();

#if LWIP_IPV6==0
#if LWIP_DHCP==1
    ipaddr.addr = 0;
    gw.addr = 0;
    netmask.addr = 0;
#else
    IP4_ADDR(&ipaddr,  192, 168,   1, 50);
    IP4_ADDR(&netmask, 255, 255, 255,  0);
    IP4_ADDR(&gw,      192, 168,   1,  1);
#endif
#endif

    xil_printf("DBG: before print_app_header\r\n");
    print_app_header();
    xil_printf("DBG: after print_app_header\r\n");

    xil_printf("DBG: before lwip_init\r\n");
    lwip_init();
    xil_printf("DBG: after lwip_init\r\n");

#if (LWIP_IPV6 == 0)
    xil_printf("DBG: before xemac_add, PLATFORM_EMAC_BASEADDR=0x%08lx\r\n",
               (unsigned long)PLATFORM_EMAC_BASEADDR);

    if (!xemac_add(echo_netif, &ipaddr, &netmask,
                   &gw, mac_ethernet_address,
                   PLATFORM_EMAC_BASEADDR)) {
        xil_printf("ERROR: xemac_add failed\r\n");
        return -1;
    }

    xil_printf("DBG: after xemac_add\r\n");
#else
    xil_printf("DBG: before xemac_add IPv6, PLATFORM_EMAC_BASEADDR=0x%08lx\r\n",
               (unsigned long)PLATFORM_EMAC_BASEADDR);

    if (!xemac_add(echo_netif, NULL, NULL, NULL,
                   mac_ethernet_address,
                   PLATFORM_EMAC_BASEADDR)) {
        xil_printf("ERROR: xemac_add IPv6 failed\r\n");
        return -1;
    }

    xil_printf("DBG: after xemac_add IPv6\r\n");

    echo_netif->ip6_autoconfig_enabled = 1;

    netif_create_ip6_linklocal_address(echo_netif, 1);
    netif_ip6_addr_set_state(echo_netif, 0, IP6_ADDR_VALID);

    print_ip6("\n\rBoard IPv6 address ", &echo_netif->ip6_addr[0].u_addr.ip6);
#endif

    xil_printf("DBG: before netif_set_default\r\n");
    netif_set_default(echo_netif);
    xil_printf("DBG: after netif_set_default\r\n");

#ifndef SDT
    xil_printf("DBG: before platform_enable_interrupts\r\n");
    platform_enable_interrupts();
    xil_printf("DBG: after platform_enable_interrupts\r\n");
#endif

    xil_printf("DBG: before netif_set_up\r\n");
    netif_set_up(echo_netif);
    xil_printf("DBG: after netif_set_up\r\n");

#if (LWIP_IPV6 == 0)
#if (LWIP_DHCP==1)
    xil_printf("DBG: before dhcp_start\r\n");
    dhcp_start(echo_netif);
    dhcp_timoutcntr = 240;
    xil_printf("DBG: after dhcp_start\r\n");

    while (((echo_netif->ip_addr.addr) == 0) && (dhcp_timoutcntr > 0)) {
        xemacif_input(echo_netif);
    }

    if (dhcp_timoutcntr <= 0) {
        if ((echo_netif->ip_addr.addr) == 0) {
            xil_printf("DHCP Timeout\r\n");
            xil_printf("Configuring default IP of 192.168.1.50\r\n");
            IP4_ADDR(&(echo_netif->ip_addr),  192, 168,   1, 50);
            IP4_ADDR(&(echo_netif->netmask), 255, 255, 255,  0);
            IP4_ADDR(&(echo_netif->gw),      192, 168,   1,  1);
        }
    }

    ipaddr.addr = echo_netif->ip_addr.addr;
    gw.addr = echo_netif->gw.addr;
    netmask.addr = echo_netif->netmask.addr;
#endif

    xil_printf("DBG: before print_ip_settings\r\n");
    print_ip_settings(&ipaddr, &netmask, &gw);
    xil_printf("DBG: after print_ip_settings\r\n");
#endif

    xil_printf("DBG: before start_application\r\n");
    if (start_application() != 0) {
        xil_printf("ERROR: start_application failed\r\n");
        return -1;
    }
    xil_printf("DBG: after start_application\r\n");

    xil_printf("DBG: entering main receive loop\r\n");

    while (1) {
        if (TcpFastTmrFlag) {
            tcp_fasttmr();
            TcpFastTmrFlag = 0;
        }

        if (TcpSlowTmrFlag) {
            tcp_slowtmr();
            TcpSlowTmrFlag = 0;
        }

        xemacif_input(echo_netif);
        transfer_data();
    }

    cleanup_platform();
    return 0;
}
