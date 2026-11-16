-- AXIS_HPU_CONTROL_BRIDGE
--
-- Converts the HPU command payload delivered by AXIS_CMD_PACKET_ROUTER
-- into AXI4-Lite transactions for HPU Core.
--
-- Input AXI4-Stream payload protocol (SOURCE_ID 0x09 header is already removed):
--
--   Write register (8 bytes):
--     Byte 0 : 0x01
--     Byte 1 : register address
--     Byte 2 : AXI WSTRB[3:0] in bits [3:0]
--     Byte 3 : reserved
--     Byte 4 : write data[31:24]
--     Byte 5 : write data[23:16]
--     Byte 6 : write data[15:8]
--     Byte 7 : write data[7:0], TLAST=1
--
--   Read register (2 bytes):
--     Byte 0 : 0x02
--     Byte 1 : register address, TLAST=1
--
-- Output AXI4-Stream response protocol:
--
--   Write response (4 bytes):
--     Byte 0 : 0x81
--     Byte 1 : register address
--     Byte 2 : 0x00,0x01,0x02,0x03 = AXI BRESP
--     Byte 3 : reserved, TLAST=1
--
--   Read response (8 bytes):
--     Byte 0 : 0x82
--     Byte 1 : register address
--     Byte 2 : 0x00,0x01,0x02,0x03 = AXI RRESP
--     Byte 3 : reserved
--     Byte 4 : read data[31:24]
--     Byte 5 : read data[23:16]
--     Byte 6 : read data[15:8]
--     Byte 7 : read data[7:0], TLAST=1
--
--   Bridge error response (4 bytes):
--     Byte 0 : 0xE0
--     Byte 1 : error code
--              0x01 unknown command
--              0x02 invalid command length
--              0x03 invalid TKEEP or payload overflow
--              0x10 AXI write timeout
--              0x11 AXI read timeout
--     Byte 2 : register address if available
--     Byte 3 : reserved, TLAST=1
--
-- The bridge supports one outstanding AXI4-Lite transaction.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY AXIS_HPU_CONTROL_BRIDGE IS
    GENERIC (
        G_AXI_ADDR_WIDTH      : POSITIVE := 8;
        G_AXI_TIMEOUT_CYCLES  : POSITIVE := 100000
    );
    PORT (
        ACLK                  : IN  STD_LOGIC;
        ARESETN               : IN  STD_LOGIC;

        -- 8-bit command stream from AXIS_CMD_PACKET_ROUTER.M_HPU
        S_AXIS_TDATA          : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        S_AXIS_TKEEP          : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
        S_AXIS_TVALID         : IN  STD_LOGIC;
        S_AXIS_TREADY         : OUT STD_LOGIC;
        S_AXIS_TLAST          : IN  STD_LOGIC;

        -- 8-bit response stream toward the telemetry path
        M_AXIS_TDATA          : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        M_AXIS_TKEEP          : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        M_AXIS_TVALID         : OUT STD_LOGIC;
        M_AXIS_TREADY         : IN  STD_LOGIC;
        M_AXIS_TLAST          : OUT STD_LOGIC;

        -- AXI4-Lite master interface toward HPU Core S_AXI
        M_AXI_AWADDR          : OUT STD_LOGIC_VECTOR(G_AXI_ADDR_WIDTH-1 DOWNTO 0);
        M_AXI_AWPROT          : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        M_AXI_AWVALID         : OUT STD_LOGIC;
        M_AXI_AWREADY         : IN  STD_LOGIC;

        M_AXI_WDATA           : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        M_AXI_WSTRB           : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        M_AXI_WVALID          : OUT STD_LOGIC;
        M_AXI_WREADY          : IN  STD_LOGIC;

        M_AXI_BRESP           : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
        M_AXI_BVALID          : IN  STD_LOGIC;
        M_AXI_BREADY          : OUT STD_LOGIC;

        M_AXI_ARADDR          : OUT STD_LOGIC_VECTOR(G_AXI_ADDR_WIDTH-1 DOWNTO 0);
        M_AXI_ARPROT          : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        M_AXI_ARVALID         : OUT STD_LOGIC;
        M_AXI_ARREADY         : IN  STD_LOGIC;

        M_AXI_RDATA           : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        M_AXI_RRESP           : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
        M_AXI_RVALID          : IN  STD_LOGIC;
        M_AXI_RREADY          : OUT STD_LOGIC;

        BUSY                  : OUT STD_LOGIC;
        COMMAND_DONE          : OUT STD_LOGIC;
        PROTOCOL_ERROR        : OUT STD_LOGIC
    );
END ENTITY AXIS_HPU_CONTROL_BRIDGE;

ARCHITECTURE RTL OF AXIS_HPU_CONTROL_BRIDGE IS

    ATTRIBUTE X_INTERFACE_INFO      : STRING;
    ATTRIBUTE X_INTERFACE_PARAMETER : STRING;

    ATTRIBUTE X_INTERFACE_INFO OF ACLK : SIGNAL IS
        "xilinx.com:signal:clock:1.0 ACLK CLK";
    ATTRIBUTE X_INTERFACE_PARAMETER OF ACLK : SIGNAL IS
        "ASSOCIATED_BUSIF S_AXIS:M_AXIS:M_AXI, ASSOCIATED_RESET ARESETN";
    ATTRIBUTE X_INTERFACE_INFO OF ARESETN : SIGNAL IS
        "xilinx.com:signal:reset:1.0 ARESETN RST";
    ATTRIBUTE X_INTERFACE_PARAMETER OF ARESETN : SIGNAL IS
        "POLARITY ACTIVE_LOW";

    ATTRIBUTE X_INTERFACE_INFO OF S_AXIS_TDATA  : SIGNAL IS "xilinx.com:interface:axis:1.0 S_AXIS TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXIS_TKEEP  : SIGNAL IS "xilinx.com:interface:axis:1.0 S_AXIS TKEEP";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXIS_TVALID : SIGNAL IS "xilinx.com:interface:axis:1.0 S_AXIS TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXIS_TREADY : SIGNAL IS "xilinx.com:interface:axis:1.0 S_AXIS TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXIS_TLAST  : SIGNAL IS "xilinx.com:interface:axis:1.0 S_AXIS TLAST";

    ATTRIBUTE X_INTERFACE_INFO OF M_AXIS_TDATA  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_AXIS TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXIS_TKEEP  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_AXIS TKEEP";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXIS_TVALID : SIGNAL IS "xilinx.com:interface:axis:1.0 M_AXIS TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXIS_TREADY : SIGNAL IS "xilinx.com:interface:axis:1.0 M_AXIS TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXIS_TLAST  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_AXIS TLAST";

    ATTRIBUTE X_INTERFACE_INFO OF M_AXI_AWADDR  : SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI AWADDR";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXI_AWPROT  : SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI AWPROT";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXI_AWVALID : SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI AWVALID";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXI_AWREADY : SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI AWREADY";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXI_WDATA   : SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI WDATA";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXI_WSTRB   : SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI WSTRB";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXI_WVALID  : SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI WVALID";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXI_WREADY  : SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI WREADY";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXI_BRESP   : SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI BRESP";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXI_BVALID  : SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI BVALID";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXI_BREADY  : SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI BREADY";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXI_ARADDR  : SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI ARADDR";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXI_ARPROT  : SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI ARPROT";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXI_ARVALID : SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI ARVALID";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXI_ARREADY : SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI ARREADY";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXI_RDATA   : SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI RDATA";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXI_RRESP   : SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI RRESP";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXI_RVALID  : SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI RVALID";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXI_RREADY  : SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI RREADY";
    ATTRIBUTE X_INTERFACE_PARAMETER OF M_AXI_AWADDR : SIGNAL IS
        "PROTOCOL AXI4LITE, DATA_WIDTH 32, ADDR_WIDTH 8, FREQ_HZ 100000000";

    TYPE STATE_T IS (
        ST_RECEIVE,
        ST_WRITE_REQUEST,
        ST_WRITE_RESPONSE,
        ST_READ_REQUEST,
        ST_READ_RESPONSE,
        ST_SEND_RESPONSE
    );

    TYPE BYTE_ARRAY_T IS ARRAY (0 TO 7) OF STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL STATE_R            : STATE_T := ST_RECEIVE;

    SIGNAL RX_INDEX_R         : INTEGER RANGE 0 TO 8 := 0;
    SIGNAL RX_COMMAND_R       : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL RX_ADDRESS_R       : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL RX_WSTRB_R         : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL RX_WDATA_R         : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL RX_FRAME_ERROR_R   : STD_LOGIC := '0';

    SIGNAL AW_DONE_R          : STD_LOGIC := '0';
    SIGNAL W_DONE_R           : STD_LOGIC := '0';

    SIGNAL RESPONSE_R         : BYTE_ARRAY_T := (OTHERS => (OTHERS => '0'));
    SIGNAL RESPONSE_LAST_R    : INTEGER RANGE 0 TO 7 := 0;
    SIGNAL RESPONSE_INDEX_R   : INTEGER RANGE 0 TO 7 := 0;

    SIGNAL TIMEOUT_COUNT_R    : INTEGER RANGE 0 TO G_AXI_TIMEOUT_CYCLES := 0;

    SIGNAL COMMAND_DONE_R     : STD_LOGIC := '0';
    SIGNAL PROTOCOL_ERROR_R   : STD_LOGIC := '0';

    PROCEDURE LOAD_ERROR_RESPONSE (
        SIGNAL RESP      : OUT BYTE_ARRAY_T;
        SIGNAL RESP_LAST : OUT INTEGER;
        CONSTANT CODE    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        CONSTANT ADDRESS : IN  STD_LOGIC_VECTOR(7 DOWNTO 0)
    ) IS
    BEGIN
        RESP(0) <= X"E0";
        RESP(1) <= CODE;
        RESP(2) <= ADDRESS;
        RESP(3) <= X"00";
        RESP(4) <= X"00";
        RESP(5) <= X"00";
        RESP(6) <= X"00";
        RESP(7) <= X"00";
        RESP_LAST <= 3;
    END PROCEDURE;

BEGIN

    S_AXIS_TREADY <= '1' WHEN STATE_R = ST_RECEIVE ELSE '0';

    M_AXIS_TDATA  <= RESPONSE_R(RESPONSE_INDEX_R);
    M_AXIS_TKEEP  <= "1";
    M_AXIS_TVALID <= '1' WHEN STATE_R = ST_SEND_RESPONSE ELSE '0';
    M_AXIS_TLAST  <= '1' WHEN (STATE_R = ST_SEND_RESPONSE AND RESPONSE_INDEX_R = RESPONSE_LAST_R) ELSE '0';

    M_AXI_AWADDR  <= RX_ADDRESS_R(G_AXI_ADDR_WIDTH-1 DOWNTO 0);
    M_AXI_AWPROT  <= "000";
    M_AXI_AWVALID <= '1' WHEN (STATE_R = ST_WRITE_REQUEST AND AW_DONE_R = '0') ELSE '0';

    M_AXI_WDATA   <= RX_WDATA_R;
    M_AXI_WSTRB   <= RX_WSTRB_R;
    M_AXI_WVALID  <= '1' WHEN (STATE_R = ST_WRITE_REQUEST AND W_DONE_R = '0') ELSE '0';

    M_AXI_BREADY  <= '1' WHEN STATE_R = ST_WRITE_RESPONSE ELSE '0';

    M_AXI_ARADDR  <= RX_ADDRESS_R(G_AXI_ADDR_WIDTH-1 DOWNTO 0);
    M_AXI_ARPROT  <= "000";
    M_AXI_ARVALID <= '1' WHEN STATE_R = ST_READ_REQUEST ELSE '0';

    M_AXI_RREADY  <= '1' WHEN STATE_R = ST_READ_RESPONSE ELSE '0';

    BUSY           <= '0' WHEN STATE_R = ST_RECEIVE ELSE '1';
    COMMAND_DONE   <= COMMAND_DONE_R;
    PROTOCOL_ERROR <= PROTOCOL_ERROR_R;

    P_MAIN : PROCESS (ACLK)
        VARIABLE V_AW_COMPLETE : BOOLEAN;
        VARIABLE V_W_COMPLETE  : BOOLEAN;
        VARIABLE V_FRAME_SIZE  : INTEGER RANGE 1 TO 9;
        VARIABLE V_COMMAND     : STD_LOGIC_VECTOR(7 DOWNTO 0);
        VARIABLE V_ADDRESS     : STD_LOGIC_VECTOR(7 DOWNTO 0);
    BEGIN
        IF RISING_EDGE(ACLK) THEN
            IF ARESETN = '0' THEN
                STATE_R            <= ST_RECEIVE;
                RX_INDEX_R         <= 0;
                RX_COMMAND_R       <= (OTHERS => '0');
                RX_ADDRESS_R       <= (OTHERS => '0');
                RX_WSTRB_R         <= (OTHERS => '0');
                RX_WDATA_R         <= (OTHERS => '0');
                RX_FRAME_ERROR_R   <= '0';
                AW_DONE_R          <= '0';
                W_DONE_R           <= '0';
                RESPONSE_R         <= (OTHERS => (OTHERS => '0'));
                RESPONSE_LAST_R    <= 0;
                RESPONSE_INDEX_R   <= 0;
                TIMEOUT_COUNT_R    <= 0;
                COMMAND_DONE_R     <= '0';
                PROTOCOL_ERROR_R   <= '0';
            ELSE
                COMMAND_DONE_R   <= '0';
                PROTOCOL_ERROR_R <= '0';

                CASE STATE_R IS
                    WHEN ST_RECEIVE =>
                        TIMEOUT_COUNT_R <= 0;
                        AW_DONE_R       <= '0';
                        W_DONE_R        <= '0';

                        IF S_AXIS_TVALID = '1' THEN
                            IF S_AXIS_TKEEP(0) = '0' THEN
                                RX_FRAME_ERROR_R <= '1';
                            END IF;

                            IF RX_INDEX_R = 0 THEN
                                RX_COMMAND_R <= S_AXIS_TDATA;
                            ELSIF RX_INDEX_R = 1 THEN
                                RX_ADDRESS_R <= S_AXIS_TDATA;
                            ELSIF RX_INDEX_R = 2 THEN
                                RX_WSTRB_R <= S_AXIS_TDATA(3 DOWNTO 0);
                            ELSIF RX_INDEX_R = 4 THEN
                                RX_WDATA_R(31 DOWNTO 24) <= S_AXIS_TDATA;
                            ELSIF RX_INDEX_R = 5 THEN
                                RX_WDATA_R(23 DOWNTO 16) <= S_AXIS_TDATA;
                            ELSIF RX_INDEX_R = 6 THEN
                                RX_WDATA_R(15 DOWNTO 8) <= S_AXIS_TDATA;
                            ELSIF RX_INDEX_R = 7 THEN
                                RX_WDATA_R(7 DOWNTO 0) <= S_AXIS_TDATA;
                            ELSE
                                NULL;
                            END IF;

                            IF RX_INDEX_R = 8 THEN
                                RX_FRAME_ERROR_R <= '1';
                            ELSE
                                RX_INDEX_R <= RX_INDEX_R + 1;
                            END IF;

                            IF S_AXIS_TLAST = '1' THEN
                                V_FRAME_SIZE := RX_INDEX_R + 1;

                                IF RX_INDEX_R = 0 THEN
                                    V_COMMAND := S_AXIS_TDATA;
                                ELSE
                                    V_COMMAND := RX_COMMAND_R;
                                END IF;

                                IF RX_INDEX_R = 1 THEN
                                    V_ADDRESS := S_AXIS_TDATA;
                                ELSE
                                    V_ADDRESS := RX_ADDRESS_R;
                                END IF;

                                RX_INDEX_R <= 0;

                                IF RX_FRAME_ERROR_R = '1' OR S_AXIS_TKEEP(0) = '0' OR RX_INDEX_R = 8 THEN
                                    LOAD_ERROR_RESPONSE(RESPONSE_R, RESPONSE_LAST_R, X"03", V_ADDRESS);
                                    RESPONSE_INDEX_R <= 0;
                                    RX_FRAME_ERROR_R <= '0';
                                    PROTOCOL_ERROR_R <= '1';
                                    STATE_R <= ST_SEND_RESPONSE;

                                ELSIF V_COMMAND = X"01" THEN
                                    IF V_FRAME_SIZE = 8 THEN
                                        RX_FRAME_ERROR_R <= '0';
                                        TIMEOUT_COUNT_R <= 0;
                                        STATE_R <= ST_WRITE_REQUEST;
                                    ELSE
                                        LOAD_ERROR_RESPONSE(RESPONSE_R, RESPONSE_LAST_R, X"02", V_ADDRESS);
                                        RESPONSE_INDEX_R <= 0;
                                        RX_FRAME_ERROR_R <= '0';
                                        PROTOCOL_ERROR_R <= '1';
                                        STATE_R <= ST_SEND_RESPONSE;
                                    END IF;

                                ELSIF V_COMMAND = X"02" THEN
                                    IF V_FRAME_SIZE = 2 THEN
                                        RX_FRAME_ERROR_R <= '0';
                                        TIMEOUT_COUNT_R <= 0;
                                        STATE_R <= ST_READ_REQUEST;
                                    ELSE
                                        LOAD_ERROR_RESPONSE(RESPONSE_R, RESPONSE_LAST_R, X"02", V_ADDRESS);
                                        RESPONSE_INDEX_R <= 0;
                                        RX_FRAME_ERROR_R <= '0';
                                        PROTOCOL_ERROR_R <= '1';
                                        STATE_R <= ST_SEND_RESPONSE;
                                    END IF;

                                ELSE
                                    LOAD_ERROR_RESPONSE(RESPONSE_R, RESPONSE_LAST_R, X"01", V_ADDRESS);
                                    RESPONSE_INDEX_R <= 0;
                                    RX_FRAME_ERROR_R <= '0';
                                    PROTOCOL_ERROR_R <= '1';
                                    STATE_R <= ST_SEND_RESPONSE;
                                END IF;
                            END IF;
                        END IF;

                    WHEN ST_WRITE_REQUEST =>
                        V_AW_COMPLETE := (AW_DONE_R = '1') OR (M_AXI_AWREADY = '1');
                        V_W_COMPLETE  := (W_DONE_R = '1') OR (M_AXI_WREADY = '1');

                        IF AW_DONE_R = '0' AND M_AXI_AWREADY = '1' THEN
                            AW_DONE_R <= '1';
                        END IF;

                        IF W_DONE_R = '0' AND M_AXI_WREADY = '1' THEN
                            W_DONE_R <= '1';
                        END IF;

                        IF V_AW_COMPLETE AND V_W_COMPLETE THEN
                            AW_DONE_R       <= '0';
                            W_DONE_R        <= '0';
                            TIMEOUT_COUNT_R <= 0;
                            STATE_R         <= ST_WRITE_RESPONSE;
                        ELSIF TIMEOUT_COUNT_R = G_AXI_TIMEOUT_CYCLES-1 THEN
                            LOAD_ERROR_RESPONSE(RESPONSE_R, RESPONSE_LAST_R, X"10", RX_ADDRESS_R);
                            RESPONSE_INDEX_R <= 0;
                            TIMEOUT_COUNT_R  <= 0;
                            STATE_R          <= ST_SEND_RESPONSE;
                        ELSE
                            TIMEOUT_COUNT_R <= TIMEOUT_COUNT_R + 1;
                        END IF;

                    WHEN ST_WRITE_RESPONSE =>
                        IF M_AXI_BVALID = '1' THEN
                            RESPONSE_R(0) <= X"81";
                            RESPONSE_R(1) <= RX_ADDRESS_R;
                            RESPONSE_R(2) <= "000000" & M_AXI_BRESP;
                            RESPONSE_R(3) <= X"00";
                            RESPONSE_R(4) <= X"00";
                            RESPONSE_R(5) <= X"00";
                            RESPONSE_R(6) <= X"00";
                            RESPONSE_R(7) <= X"00";
                            RESPONSE_LAST_R  <= 3;
                            RESPONSE_INDEX_R <= 0;
                            TIMEOUT_COUNT_R  <= 0;
                            STATE_R          <= ST_SEND_RESPONSE;
                        ELSIF TIMEOUT_COUNT_R = G_AXI_TIMEOUT_CYCLES-1 THEN
                            LOAD_ERROR_RESPONSE(RESPONSE_R, RESPONSE_LAST_R, X"10", RX_ADDRESS_R);
                            RESPONSE_INDEX_R <= 0;
                            TIMEOUT_COUNT_R  <= 0;
                            STATE_R          <= ST_SEND_RESPONSE;
                        ELSE
                            TIMEOUT_COUNT_R <= TIMEOUT_COUNT_R + 1;
                        END IF;

                    WHEN ST_READ_REQUEST =>
                        IF M_AXI_ARREADY = '1' THEN
                            TIMEOUT_COUNT_R <= 0;
                            STATE_R <= ST_READ_RESPONSE;
                        ELSIF TIMEOUT_COUNT_R = G_AXI_TIMEOUT_CYCLES-1 THEN
                            LOAD_ERROR_RESPONSE(RESPONSE_R, RESPONSE_LAST_R, X"11", RX_ADDRESS_R);
                            RESPONSE_INDEX_R <= 0;
                            TIMEOUT_COUNT_R  <= 0;
                            STATE_R          <= ST_SEND_RESPONSE;
                        ELSE
                            TIMEOUT_COUNT_R <= TIMEOUT_COUNT_R + 1;
                        END IF;

                    WHEN ST_READ_RESPONSE =>
                        IF M_AXI_RVALID = '1' THEN
                            RESPONSE_R(0) <= X"82";
                            RESPONSE_R(1) <= RX_ADDRESS_R;
                            RESPONSE_R(2) <= "000000" & M_AXI_RRESP;
                            RESPONSE_R(3) <= X"00";
                            RESPONSE_R(4) <= M_AXI_RDATA(31 DOWNTO 24);
                            RESPONSE_R(5) <= M_AXI_RDATA(23 DOWNTO 16);
                            RESPONSE_R(6) <= M_AXI_RDATA(15 DOWNTO 8);
                            RESPONSE_R(7) <= M_AXI_RDATA(7 DOWNTO 0);
                            RESPONSE_LAST_R  <= 7;
                            RESPONSE_INDEX_R <= 0;
                            TIMEOUT_COUNT_R  <= 0;
                            STATE_R          <= ST_SEND_RESPONSE;
                        ELSIF TIMEOUT_COUNT_R = G_AXI_TIMEOUT_CYCLES-1 THEN
                            LOAD_ERROR_RESPONSE(RESPONSE_R, RESPONSE_LAST_R, X"11", RX_ADDRESS_R);
                            RESPONSE_INDEX_R <= 0;
                            TIMEOUT_COUNT_R  <= 0;
                            STATE_R          <= ST_SEND_RESPONSE;
                        ELSE
                            TIMEOUT_COUNT_R <= TIMEOUT_COUNT_R + 1;
                        END IF;

                    WHEN ST_SEND_RESPONSE =>
                        IF M_AXIS_TREADY = '1' THEN
                            IF RESPONSE_INDEX_R = RESPONSE_LAST_R THEN
                                RESPONSE_INDEX_R <= 0;
                                COMMAND_DONE_R   <= '1';
                                STATE_R          <= ST_RECEIVE;
                            ELSE
                                RESPONSE_INDEX_R <= RESPONSE_INDEX_R + 1;
                            END IF;
                        END IF;

                    WHEN OTHERS =>
                        STATE_R <= ST_RECEIVE;
                END CASE;
            END IF;
        END IF;
    END PROCESS P_MAIN;

END ARCHITECTURE RTL;
