#include <stdio.h>
#include <string.h>

#include "xil_printf.h"
#include "xil_types.h"
#include "xstatus.h"
#include "xil_cache.h"
#include "xil_io.h"
#include "xaxidma.h"
#include "xparameters.h"

#include "lwip/err.h"
#include "lwip/pbuf.h"
#include "lwip/udp.h"
#include "lwip/ip_addr.h"

/*
 * UDP command port used by the PC GUI / Python test script.
 * Keep the PC and GUI set to this same port.
 */
#define UDP_CMD_PORT        5001U

/*
 * Command format uses a 4-byte outer header and an 8-bit DATA_LENGTH_MINUS_ONE
 * field. Therefore the largest legal payload is 256 bytes and the largest
 * complete command packet is 260 bytes.
 */
#define CMD_DMA_MAX_PAYLOAD_SIZE  256U
#define CMD_DMA_BUF_SIZE          (4U + CMD_DMA_MAX_PAYLOAD_SIZE)

/* Polling timeout for one MM2S DMA transfer. */
#define CMD_DMA_TIMEOUT           10000000U

/*
 * Telemetry frames are variable length:
 *
 * VERSION | TEL_SEQ | TIME_MSB | TIME_LSB | SOURCE | DATA_LENGTH | DATA...
 *
 * Examples:
 *   ADC pair sample:       6-byte header + 6-byte payload  = 12 bytes
 *   HPU event:             6-byte header + 5-byte payload  = 11 bytes
 *   HPU write response:    6-byte header + 4-byte payload  = 10 bytes
 *   HPU read response:     6-byte header + 8-byte payload  = 14 bytes
 *
 * S2MM is armed with the full receive-buffer capacity. After TLAST, AXI DMA
 * updates S2MM_LENGTH with the actual number of bytes written.
 */
#define TM_DMA_HEADER_SIZE  6U
#define TM_DMA_BUF_SIZE     64U

/* AXI DMA instances are created and initialized in main.c. */
extern XAxiDma AxiDmaCmd;
extern XAxiDma AxiDmaTm;

static struct udp_pcb *UDP_CMD_PCB = NULL;

/* Aligned buffer for AXI DMA MM2S reads from DDR. */
static u8 CmdDmaTxBuf[CMD_DMA_BUF_SIZE] __attribute__((aligned(64)));

/* Aligned buffer for AXI DMA S2MM writes to DDR. */
static u8 TmDmaRxBuf[TM_DMA_BUF_SIZE] __attribute__((aligned(64)));

static u8 TmDmaRxInProgress = 0U;
static u32 TmDmaArmCounter = 0U;
static u32 TmDmaBusyPrintCounter = 0U;

#if defined(XPAR_AXI_DMA_TM_BASEADDR)
#define TM_DMA_BASEADDR XPAR_AXI_DMA_TM_BASEADDR
#elif defined(XPAR_AXI_DMA_TM_0_BASEADDR)
#define TM_DMA_BASEADDR XPAR_AXI_DMA_TM_0_BASEADDR
#elif defined(XPAR_XAXIDMA_1_BASEADDR)
#define TM_DMA_BASEADDR XPAR_XAXIDMA_1_BASEADDR
#else
#define TM_DMA_BASEADDR 0x80040000U
#endif

#define TM_DMA_S2MM_DMASR_OFFSET     0x34U
#define TM_DMA_S2MM_LENGTH_OFFSET    0x58U
#define TM_DMA_LENGTH_MASK           0x03FFFFFFU

static u32 ReadTmDmaS2mmStatus(void)
{
    return Xil_In32((UINTPTR)(TM_DMA_BASEADDR + TM_DMA_S2MM_DMASR_OFFSET));
}

static u32 ReadTmDmaS2mmActualLength(void)
{
    return Xil_In32((UINTPTR)(TM_DMA_BASEADDR + TM_DMA_S2MM_LENGTH_OFFSET)) &
           TM_DMA_LENGTH_MASK;
}

static int ShouldPrintTmDebug(u32 Counter)
{
    return ((Counter <= 8U) || ((Counter & 0x3FU) == 0U));
}

static u32 TmFrameCounter = 0U;

/*
 * Telemetry is sent to the latest UDP client that sent us a command.
 * This keeps the PC GUI simple: send command, then receive echo + telemetry
 * on the same UDP socket.
 */
static ip_addr_t LastClientAddr;
static u16_t LastClientPort = 0U;
static u8 HaveLastClient = 0U;

void print_app_header(void)
{
    xil_printf("\r\n");
    xil_printf("----- UDP CMD Echo + AXI DMA + Telemetry Server -----\r\n");
    xil_printf("Listening on UDP port %u\r\n", (unsigned int)UDP_CMD_PORT);
    xil_printf("CMD packet format:\r\n");
    xil_printf("  BYTE0 VERSION=0x01, BYTE1 PACK_SEQ, BYTE2 SOURCE_ID, BYTE3 DATA_LENGTH, BYTE4..DATA\r\n");
    xil_printf("Example SPIKE packet: 01 00 00 02 AA BB CC\r\n");
    xil_printf("Example ADC3 all-pairs command: 01 00 07 00 FC\r\n");
    xil_printf("Telemetry frame format:\r\n");
    xil_printf("  VERSION | TEL_SEQ | TIME_MSB | TIME_LSB | SOURCE | DATA_LENGTH | DATA...\r\n");
    xil_printf("Supported command SOURCE_ID range: 0x00..0x09\r\n");
    xil_printf("Variable telemetry receive buffer: %u bytes maximum\r\n",
               (unsigned int)TM_DMA_BUF_SIZE);
    xil_printf("-----------------------------------------------------\r\n");
}

static void PrintCmdBytes(const u8 *DataPtr, u32 Length)
{
    u32 i;

    xil_printf("CMD bytes: ");
    for (i = 0U; i < Length; i++) {
        xil_printf("%02X ", DataPtr[i]);
    }
    xil_printf("\r\n");
}

static void PrintCmdHeaderInfo(const u8 *DataPtr, u32 Length)
{
    u8 Version;
    u8 PackSeq;
    u8 SourceId;
    u8 DataLenMinusOne;
    u32 ExpectedTotal;

    if (Length < 4U) {
        xil_printf("CMD header: packet too short for header, Length=%lu\r\n",
                   (unsigned long)Length);
        return;
    }

    Version = DataPtr[0];
    PackSeq = DataPtr[1];
    SourceId = DataPtr[2];
    DataLenMinusOne = DataPtr[3];
    ExpectedTotal = 4U + ((u32)DataLenMinusOne + 1U);

    xil_printf("CMD header: VERSION=0x%02X, PACK_SEQ=0x%02X, SOURCE_ID=0x%02X, DATA_LENGTH=0x%02X\r\n",
               Version,
               PackSeq,
               SourceId,
               DataLenMinusOne);

    if (Version != 0x01U) {
        xil_printf("WARNING: CMD VERSION is not 0x01. Router will flag BAD_VERSION.\r\n");
    }

    if (SourceId > 0x09U) {
        xil_printf("WARNING: SOURCE_ID is outside 0x00..0x09. Router will flag INVALID_ID.\r\n");
    }

    if (ExpectedTotal != Length) {
        xil_printf("WARNING: Length mismatch. Expected total=%lu, actual=%lu. Router may flag LENGTH_MISMATCH.\r\n",
                   (unsigned long)ExpectedTotal,
                   (unsigned long)Length);
    }
}

static void PrintTmFrameInfo(const u8 *DataPtr, u32 Length)
{
    u8 Version;
    u8 TelSeq;
    u16 Timestamp;
    u8 SourceId;
    u8 DataLenMinusOne;
    u32 PayloadLength;
    u32 ExpectedTotal;

    if ((DataPtr == NULL) || (Length < TM_DMA_HEADER_SIZE)) {
        xil_printf("TM frame too short, Length=%lu\r\n", (unsigned long)Length);
        return;
    }

    Version = DataPtr[0];
    TelSeq = DataPtr[1];
    Timestamp = ((u16)DataPtr[2] << 8) | (u16)DataPtr[3];
    SourceId = DataPtr[4];
    DataLenMinusOne = DataPtr[5];
    PayloadLength = (u32)DataLenMinusOne + 1U;
    ExpectedTotal = TM_DMA_HEADER_SIZE + PayloadLength;

    xil_printf("TM frame #%lu: LEN=%lu, VERSION=0x%02X, TEL_SEQ=0x%02X, TIME=0x%04X, SOURCE=0x%02X, DATA_LENGTH=0x%02X\r\n",
               (unsigned long)TmFrameCounter,
               (unsigned long)Length,
               Version,
               TelSeq,
               Timestamp,
               SourceId,
               DataLenMinusOne);

    if (ExpectedTotal != Length) {
        xil_printf("  WARNING: telemetry length mismatch, header expects %lu bytes\r\n",
                   (unsigned long)ExpectedTotal);
    }

    if (((SourceId >= 0x05U) && (SourceId <= 0x08U)) &&
        (PayloadLength >= 6U) &&
        (Length >= 12U)) {
        u8 ChA = DataPtr[6];
        u16 SampleA = ((u16)DataPtr[7] << 8) | (u16)DataPtr[8];
        u8 ChB = DataPtr[9];
        u16 SampleB = ((u16)DataPtr[10] << 8) | (u16)DataPtr[11];

        xil_printf("  ADC samples: CH%u=0x%04X, CH%u=0x%04X\r\n",
                   (unsigned int)ChA,
                   SampleA,
                   (unsigned int)ChB,
                   SampleB);
    }

    if ((SourceId == 0x09U) && (PayloadLength >= 1U) && (Length >= 7U)) {
        u8 HpuType = DataPtr[6];

        if ((HpuType == 0x40U) && (PayloadLength >= 5U) && (Length >= 11U)) {
            u32 EventWord = ((u32)DataPtr[7] << 24) |
                            ((u32)DataPtr[8] << 16) |
                            ((u32)DataPtr[9] << 8) |
                            (u32)DataPtr[10];
            u32 EventAddress = EventWord & 0x000001FFU;

            xil_printf("  HPU event: RAW=0x%08lX, ADDR9=0x%03lX (%lu)\r\n",
                       (unsigned long)EventWord,
                       (unsigned long)EventAddress,
                       (unsigned long)EventAddress);
        } else if ((HpuType == 0x81U) &&
                   (PayloadLength >= 4U) &&
                   (Length >= 10U)) {
            xil_printf("  HPU write response: ADDR=0x%02X, AXI_RESP=0x%02X\r\n",
                       DataPtr[7],
                       DataPtr[8]);
        } else if ((HpuType == 0x82U) &&
                   (PayloadLength >= 8U) &&
                   (Length >= 14U)) {
            u32 ReadData = ((u32)DataPtr[10] << 24) |
                           ((u32)DataPtr[11] << 16) |
                           ((u32)DataPtr[12] << 8) |
                           (u32)DataPtr[13];

            xil_printf("  HPU read response: ADDR=0x%02X, AXI_RESP=0x%02X, DATA=0x%08lX\r\n",
                       DataPtr[7],
                       DataPtr[8],
                       (unsigned long)ReadData);
        } else if (HpuType == 0xE0U) {
            xil_printf("  HPU bridge error response\r\n");
        } else {
            xil_printf("  HPU payload type: 0x%02X\r\n", HpuType);
        }
    }
}

static int SendCmdPacketToPl(const u8 *DataPtr, u32 Length)
{
    int Status;
    u32 Timeout;
    u32 i;

    if ((DataPtr == NULL) || (Length == 0U) || (Length > CMD_DMA_BUF_SIZE)) {
        xil_printf("ERROR: Invalid CMD packet length for DMA: %lu\r\n",
                   (unsigned long)Length);
        return XST_FAILURE;
    }

    if (DataPtr != CmdDmaTxBuf) {
        for (i = 0U; i < Length; i++) {
            CmdDmaTxBuf[i] = DataPtr[i];
        }
    }

    /* Make sure the DMA sees the latest CPU-written bytes in DDR. */
    Xil_DCacheFlushRange((UINTPTR)CmdDmaTxBuf, Length);

    Status = XAxiDma_SimpleTransfer(&AxiDmaCmd,
                                    (UINTPTR)CmdDmaTxBuf,
                                    Length,
                                    XAXIDMA_DMA_TO_DEVICE);

    if (Status != XST_SUCCESS) {
        xil_printf("ERROR: XAxiDma_SimpleTransfer CMD failed, Status=%d\r\n", Status);
        return XST_FAILURE;
    }

    Timeout = CMD_DMA_TIMEOUT;
    while (XAxiDma_Busy(&AxiDmaCmd, XAXIDMA_DMA_TO_DEVICE)) {
        Timeout--;
        if (Timeout == 0U) {
            xil_printf("ERROR: AXI DMA CMD MM2S timeout\r\n");
            return XST_FAILURE;
        }
    }

    xil_printf("DMA MM2S sent CMD packet to PL, Length=%lu\r\n",
               (unsigned long)Length);
    return XST_SUCCESS;
}

static int StartTmDmaReceive(void)
{
    int Status;
    u32 i;

    if (TmDmaRxInProgress != 0U) {
        return XST_SUCCESS;
    }

    /*
     * Keep the full variable-length receive buffer cache-safe.
     */
    for (i = 0U; i < TM_DMA_BUF_SIZE; i++) {
        TmDmaRxBuf[i] = 0U;
    }

    Xil_DCacheFlushRange((UINTPTR)TmDmaRxBuf, TM_DMA_BUF_SIZE);
    Xil_DCacheInvalidateRange((UINTPTR)TmDmaRxBuf, TM_DMA_BUF_SIZE);

    TmDmaArmCounter++;

    if (ShouldPrintTmDebug(TmDmaArmCounter)) {
        xil_printf("[TM DMA] arm request #%lu, buf=0x%08lx, max_len=%lu, DMASR before=0x%08lx\r\n",
                   (unsigned long)TmDmaArmCounter,
                   (unsigned long)((UINTPTR)TmDmaRxBuf),
                   (unsigned long)TM_DMA_BUF_SIZE,
                   (unsigned long)ReadTmDmaS2mmStatus());
    }

    Status = XAxiDma_SimpleTransfer(&AxiDmaTm,
                                    (UINTPTR)TmDmaRxBuf,
                                    TM_DMA_BUF_SIZE,
                                    XAXIDMA_DEVICE_TO_DMA);

    if (Status != XST_SUCCESS) {
        xil_printf("ERROR: XAxiDma_SimpleTransfer TM S2MM failed, Status=%d\r\n", Status);
        TmDmaRxInProgress = 0U;
        return XST_FAILURE;
    }

    TmDmaRxInProgress = 1U;

    if (ShouldPrintTmDebug(TmDmaArmCounter)) {
        xil_printf("[TM DMA] armed OK, DMASR after=0x%08lx\r\n",
                   (unsigned long)ReadTmDmaS2mmStatus());
    }

    return XST_SUCCESS;
}

static void SendTelemetryToPc(const u8 *DataPtr, u32 Length)
{
    struct pbuf *PbufPtr;
    err_t Err;

    if ((DataPtr == NULL) || (Length == 0U)) {
        return;
    }

    if ((UDP_CMD_PCB == NULL) || (HaveLastClient == 0U)) {
        /*
         * No PC has sent us a command yet, so we do not know where to send telemetry.
         */
        return;
    }

    PbufPtr = pbuf_alloc(PBUF_TRANSPORT, (u16_t)Length, PBUF_RAM);
    if (PbufPtr == NULL) {
        xil_printf("[UDP ERROR] pbuf_alloc failed for telemetry\r\n");
        return;
    }

    memcpy(PbufPtr->payload, DataPtr, Length);

    Err = udp_sendto(UDP_CMD_PCB, PbufPtr, &LastClientAddr, LastClientPort);
    if (Err != ERR_OK) {
        xil_printf("[UDP ERROR] telemetry udp_sendto failed, err=%d\r\n", Err);
    }

    pbuf_free(PbufPtr);
}

static void CheckTmDmaReceive(void)
{
    u32 ActualLength;
    u32 StatusReg;

    if (TmDmaRxInProgress == 0U) {
        (void)StartTmDmaReceive();
        return;
    }

    if (XAxiDma_Busy(&AxiDmaTm, XAXIDMA_DEVICE_TO_DMA)) {
        TmDmaBusyPrintCounter++;

        if ((TmDmaBusyPrintCounter <= 10U) ||
            ((TmDmaBusyPrintCounter & 0xFFFFFU) == 0U)) {
            xil_printf("[TM DMA] still busy, poll=%lu, DMASR=0x%08lx\r\n",
                       (unsigned long)TmDmaBusyPrintCounter,
                       (unsigned long)ReadTmDmaS2mmStatus());
        }

        return;
    }

    StatusReg = ReadTmDmaS2mmStatus();
    ActualLength = ReadTmDmaS2mmActualLength();
    TmDmaRxInProgress = 0U;

    /* DMA has written the telemetry frame into DDR. */
    Xil_DCacheInvalidateRange((UINTPTR)TmDmaRxBuf, TM_DMA_BUF_SIZE);

    if ((ActualLength == 0U) || (ActualLength > TM_DMA_BUF_SIZE)) {
        xil_printf("ERROR: invalid TM DMA actual length=%lu, DMASR=0x%08lx\r\n",
                   (unsigned long)ActualLength,
                   (unsigned long)StatusReg);
        (void)StartTmDmaReceive();
        return;
    }

    TmFrameCounter++;

    /* Avoid making UART the telemetry bottleneck. */
    if (ShouldPrintTmDebug(TmFrameCounter)) {
        xil_printf("[TM DMA] complete, actual_len=%lu, DMASR=0x%08lx\r\n",
                   (unsigned long)ActualLength,
                   (unsigned long)StatusReg);
        PrintTmFrameInfo(TmDmaRxBuf, ActualLength);
    }

    SendTelemetryToPc(TmDmaRxBuf, ActualLength);

    /* Re-arm DMA for the next complete AXI4-Stream frame. */
    (void)StartTmDmaReceive();
}

static void udp_cmd_recv_callback(void *arg,
                                  struct udp_pcb *pcb,
                                  struct pbuf *p,
                                  const ip_addr_t *addr,
                                  u16_t port)
{
    err_t Err;
    u32 Length;

    (void)arg;

    if (p == NULL) {
        return;
    }

    Length = (u32)p->tot_len;

    if ((Length == 0U) || (Length > CMD_DMA_BUF_SIZE)) {
        xil_printf("ERROR: UDP packet length invalid: %lu\r\n",
                   (unsigned long)Length);
        pbuf_free(p);
        return;
    }

    /*
     * Remember the latest PC endpoint.
     * Telemetry frames will be sent back to this IP/port.
     */
    LastClientAddr = *addr;
    LastClientPort = port;
    HaveLastClient = 1U;

    /* pbuf can be chained, so copy it into one linear aligned DMA buffer. */
    pbuf_copy_partial(p, CmdDmaTxBuf, Length, 0);

    xil_printf("[UDP RX] %lu bytes received from source port %u\r\n",
               (unsigned long)Length,
               (unsigned int)port);

    PrintCmdBytes(CmdDmaTxBuf, Length);
    PrintCmdHeaderInfo(CmdDmaTxBuf, Length);

    /* Echo the original UDP payload back to the PC. */
    Err = udp_sendto(pcb, p, addr, port);
    if (Err != ERR_OK) {
        xil_printf("[UDP ERROR] udp_sendto failed, err=%d\r\n", Err);
    } else {
        xil_printf("[UDP TX] %lu bytes echoed\r\n", (unsigned long)Length);
    }

    /* Send the full CMD packet to PL. The PL router strips the first 4 bytes. */
    (void)SendCmdPacketToPl(CmdDmaTxBuf, Length);

    pbuf_free(p);
}

int start_application(void)
{
    err_t Err;

    UDP_CMD_PCB = udp_new();
    if (UDP_CMD_PCB == NULL) {
        xil_printf("[UDP ERROR] udp_new failed\r\n");
        return -1;
    }

    Err = udp_bind(UDP_CMD_PCB, IP_ADDR_ANY, UDP_CMD_PORT);
    if (Err != ERR_OK) {
        xil_printf("[UDP ERROR] udp_bind failed, err=%d\r\n", Err);
        udp_remove(UDP_CMD_PCB);
        UDP_CMD_PCB = NULL;
        return -2;
    }

    udp_recv(UDP_CMD_PCB, udp_cmd_recv_callback, NULL);

    xil_printf("[UDP] CMD echo + DMA + TM server started on port %u\r\n",
               (unsigned int)UDP_CMD_PORT);

    /*
     * Arm the telemetry S2MM DMA once with the maximum buffer capacity.
     * TLAST terminates each variable-length telemetry frame.
     */
    (void)StartTmDmaReceive();

    return 0;
}

int transfer_data(void)
{
    /*
     * UDP raw API packets are handled by udp_cmd_recv_callback().
     * Telemetry S2MM DMA is polled here.
     */
    CheckTmDmaReceive();

    return 0;
}