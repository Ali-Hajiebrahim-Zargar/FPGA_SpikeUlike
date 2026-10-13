-- AXIS_HPU_TELEMETRY_ADAPTER
--
-- Purpose:
--   1. Accept 32-bit event words from HPU Core M_AXIS.
--   2. Buffer the events in a configurable FIFO.
--   3. Convert every HPU event into one typed 8-bit AXI4-Stream frame:
--        byte 0 = 0x40
--        byte 1 = event[31:24]
--        byte 2 = event[23:16]
--        byte 3 = event[15:8]
--        byte 4 = event[7:0], TLAST = 1
--   4. Arbitrate those event frames with the typed register responses generated
--      by AXIS_HPU_CONTROL_BRIDGE. Register responses have priority between
--      complete event frames and are passed through without modification.
--
-- Notes:
--   * HPU Core must be configured with OnlyEventsRx = 1.
--   * Each accepted 32-bit HPU beat is treated as one complete event.
--   * S_HPU_TLAST is intentionally not used because the required Ethernet
--     telemetry policy is one packet per event, independent of HPU batching.
--   * Backpressure is applied to HPU Core when the event FIFO is full.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY AXIS_HPU_TELEMETRY_ADAPTER IS
    GENERIC (
        G_EVENT_FIFO_DEPTH : POSITIVE := 4096;
        G_EVENT_TYPE       : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"40"
    );
    PORT (
        ACLK    : IN  STD_LOGIC;
        ARESETN : IN  STD_LOGIC;

        -- 32-bit event stream from HPU Core M_AXIS
        S_HPU_TDATA  : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        S_HPU_TVALID : IN  STD_LOGIC;
        S_HPU_TREADY : OUT STD_LOGIC;
        S_HPU_TLAST  : IN  STD_LOGIC;

        -- 8-bit typed response stream from AXIS_HPU_CONTROL_BRIDGE
        S_RESPONSE_TDATA  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        S_RESPONSE_TKEEP  : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
        S_RESPONSE_TVALID : IN  STD_LOGIC;
        S_RESPONSE_TREADY : OUT STD_LOGIC;
        S_RESPONSE_TLAST  : IN  STD_LOGIC;

        -- 8-bit typed stream toward AXIS_TELEMETRY_DATA_MANAGER.S_HPU
        M_AXIS_TDATA  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        M_AXIS_TKEEP  : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        M_AXIS_TVALID : OUT STD_LOGIC;
        M_AXIS_TREADY : IN  STD_LOGIC;
        M_AXIS_TLAST  : OUT STD_LOGIC;

        FIFO_LEVEL_O : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        FIFO_FULL_O  : OUT STD_LOGIC;
        EVENT_SENT_O : OUT STD_LOGIC;
        RESPONSE_SENT_O : OUT STD_LOGIC
    );
END ENTITY AXIS_HPU_TELEMETRY_ADAPTER;

ARCHITECTURE RTL OF AXIS_HPU_TELEMETRY_ADAPTER IS

    ATTRIBUTE X_INTERFACE_INFO      : STRING;
    ATTRIBUTE X_INTERFACE_PARAMETER : STRING;

    ATTRIBUTE X_INTERFACE_INFO OF ACLK : SIGNAL IS
        "xilinx.com:signal:clock:1.0 ACLK CLK";
    ATTRIBUTE X_INTERFACE_PARAMETER OF ACLK : SIGNAL IS
        "XIL_INTERFACENAME ACLK, ASSOCIATED_BUSIF S_HPU:S_RESPONSE:M_AXIS, ASSOCIATED_RESET ARESETN, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0";

    ATTRIBUTE X_INTERFACE_INFO OF ARESETN : SIGNAL IS
        "xilinx.com:signal:reset:1.0 ARESETN RST";
    ATTRIBUTE X_INTERFACE_PARAMETER OF ARESETN : SIGNAL IS
        "XIL_INTERFACENAME ARESETN, POLARITY ACTIVE_LOW";

    ATTRIBUTE X_INTERFACE_INFO OF S_HPU_TDATA  : SIGNAL IS "xilinx.com:interface:axis:1.0 S_HPU TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF S_HPU_TVALID : SIGNAL IS "xilinx.com:interface:axis:1.0 S_HPU TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF S_HPU_TREADY : SIGNAL IS "xilinx.com:interface:axis:1.0 S_HPU TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF S_HPU_TLAST  : SIGNAL IS "xilinx.com:interface:axis:1.0 S_HPU TLAST";
    ATTRIBUTE X_INTERFACE_PARAMETER OF S_HPU_TDATA : SIGNAL IS
        "XIL_INTERFACENAME S_HPU, TDATA_NUM_BYTES 4, HAS_TKEEP 0, HAS_TLAST 1";

    ATTRIBUTE X_INTERFACE_INFO OF S_RESPONSE_TDATA  : SIGNAL IS "xilinx.com:interface:axis:1.0 S_RESPONSE TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF S_RESPONSE_TKEEP  : SIGNAL IS "xilinx.com:interface:axis:1.0 S_RESPONSE TKEEP";
    ATTRIBUTE X_INTERFACE_INFO OF S_RESPONSE_TVALID : SIGNAL IS "xilinx.com:interface:axis:1.0 S_RESPONSE TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF S_RESPONSE_TREADY : SIGNAL IS "xilinx.com:interface:axis:1.0 S_RESPONSE TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF S_RESPONSE_TLAST  : SIGNAL IS "xilinx.com:interface:axis:1.0 S_RESPONSE TLAST";
    ATTRIBUTE X_INTERFACE_PARAMETER OF S_RESPONSE_TDATA : SIGNAL IS
        "XIL_INTERFACENAME S_RESPONSE, TDATA_NUM_BYTES 1, HAS_TKEEP 1, HAS_TLAST 1";

    ATTRIBUTE X_INTERFACE_INFO OF M_AXIS_TDATA  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_AXIS TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXIS_TKEEP  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_AXIS TKEEP";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXIS_TVALID : SIGNAL IS "xilinx.com:interface:axis:1.0 M_AXIS TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXIS_TREADY : SIGNAL IS "xilinx.com:interface:axis:1.0 M_AXIS TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXIS_TLAST  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_AXIS TLAST";
    ATTRIBUTE X_INTERFACE_PARAMETER OF M_AXIS_TDATA : SIGNAL IS
        "XIL_INTERFACENAME M_AXIS, TDATA_NUM_BYTES 1, HAS_TKEEP 1, HAS_TLAST 1";

    TYPE T_EVENT_MEMORY IS ARRAY (0 TO G_EVENT_FIFO_DEPTH - 1) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
    TYPE T_OUTPUT_STATE IS (ST_IDLE, ST_EVENT, ST_RESPONSE);

    SIGNAL R_EVENT_MEMORY : T_EVENT_MEMORY;
    ATTRIBUTE RAM_STYLE : STRING;
    ATTRIBUTE RAM_STYLE OF R_EVENT_MEMORY : SIGNAL IS "block";

    SIGNAL R_WRITE_POINTER : INTEGER RANGE 0 TO G_EVENT_FIFO_DEPTH - 1 := 0;
    SIGNAL R_READ_POINTER  : INTEGER RANGE 0 TO G_EVENT_FIFO_DEPTH - 1 := 0;
    SIGNAL R_FIFO_COUNT    : INTEGER RANGE 0 TO G_EVENT_FIFO_DEPTH := 0;

    SIGNAL R_OUTPUT_STATE  : T_OUTPUT_STATE := ST_IDLE;
    SIGNAL R_EVENT_WORD    : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL R_EVENT_INDEX   : INTEGER RANGE 0 TO 4 := 0;

    SIGNAL R_EVENT_SENT    : STD_LOGIC := '0';
    SIGNAL R_RESPONSE_SENT : STD_LOGIC := '0';

    SIGNAL W_HPU_READY     : STD_LOGIC;
    SIGNAL W_PUSH_EVENT    : STD_LOGIC;
    SIGNAL W_POP_EVENT     : STD_LOGIC;

    FUNCTION NEXT_POINTER (
        CONSTANT POINTER_VALUE : IN INTEGER;
        CONSTANT DEPTH_VALUE   : IN POSITIVE
    ) RETURN INTEGER IS
    BEGIN
        IF POINTER_VALUE = DEPTH_VALUE - 1 THEN
            RETURN 0;
        ELSE
            RETURN POINTER_VALUE + 1;
        END IF;
    END FUNCTION;

BEGIN

    ASSERT G_EVENT_FIFO_DEPTH <= 65535
        REPORT "G_EVENT_FIFO_DEPTH MUST BE <= 65535 BECAUSE FIFO_LEVEL_O IS 16 BITS."
        SEVERITY FAILURE;

    -- S_HPU_TLAST is intentionally ignored; every accepted beat is one event.
    W_HPU_READY <= '1' WHEN R_FIFO_COUNT < G_EVENT_FIFO_DEPTH ELSE '0';
    S_HPU_TREADY <= W_HPU_READY;
    W_PUSH_EVENT <= S_HPU_TVALID AND W_HPU_READY;

    -- A buffered event is removed only when a new event frame is selected.
    -- Register responses have priority while the adapter is idle.
    W_POP_EVENT <= '1' WHEN (
        R_OUTPUT_STATE = ST_IDLE AND
        S_RESPONSE_TVALID = '0' AND
        R_FIFO_COUNT > 0
    ) ELSE '0';

    S_RESPONSE_TREADY <= M_AXIS_TREADY WHEN R_OUTPUT_STATE = ST_RESPONSE ELSE '0';

    M_AXIS_TKEEP <= S_RESPONSE_TKEEP WHEN R_OUTPUT_STATE = ST_RESPONSE ELSE "1";

    P_OUTPUT_COMB : PROCESS (
        R_OUTPUT_STATE,
        R_EVENT_INDEX,
        R_EVENT_WORD,
        S_RESPONSE_TDATA,
        S_RESPONSE_TVALID,
        S_RESPONSE_TLAST
    )
    BEGIN
        M_AXIS_TDATA  <= (OTHERS => '0');
        M_AXIS_TVALID <= '0';
        M_AXIS_TLAST  <= '0';

        CASE R_OUTPUT_STATE IS
            WHEN ST_EVENT =>
                M_AXIS_TVALID <= '1';

                CASE R_EVENT_INDEX IS
                    WHEN 0 => M_AXIS_TDATA <= G_EVENT_TYPE;
                    WHEN 1 => M_AXIS_TDATA <= R_EVENT_WORD(31 DOWNTO 24);
                    WHEN 2 => M_AXIS_TDATA <= R_EVENT_WORD(23 DOWNTO 16);
                    WHEN 3 => M_AXIS_TDATA <= R_EVENT_WORD(15 DOWNTO 8);
                    WHEN 4 =>
                        M_AXIS_TDATA <= R_EVENT_WORD(7 DOWNTO 0);
                        M_AXIS_TLAST <= '1';
                    WHEN OTHERS =>
                        M_AXIS_TDATA <= (OTHERS => '0');
                END CASE;

            WHEN ST_RESPONSE =>
                M_AXIS_TDATA  <= S_RESPONSE_TDATA;
                M_AXIS_TVALID <= S_RESPONSE_TVALID;
                M_AXIS_TLAST  <= S_RESPONSE_TLAST;

            WHEN OTHERS =>
                NULL;
        END CASE;
    END PROCESS P_OUTPUT_COMB;

    P_FIFO_AND_STATE : PROCESS (ACLK)
        VARIABLE V_PUSH : BOOLEAN;
        VARIABLE V_POP  : BOOLEAN;
    BEGIN
        IF RISING_EDGE(ACLK) THEN
            IF ARESETN = '0' THEN
                R_WRITE_POINTER <= 0;
                R_READ_POINTER  <= 0;
                R_FIFO_COUNT    <= 0;
                R_OUTPUT_STATE  <= ST_IDLE;
                R_EVENT_WORD    <= (OTHERS => '0');
                R_EVENT_INDEX   <= 0;
                R_EVENT_SENT    <= '0';
                R_RESPONSE_SENT <= '0';
            ELSE
                R_EVENT_SENT    <= '0';
                R_RESPONSE_SENT <= '0';

                V_PUSH := (W_PUSH_EVENT = '1');
                V_POP  := (W_POP_EVENT = '1');

                IF V_PUSH THEN
                    R_EVENT_MEMORY(R_WRITE_POINTER) <= S_HPU_TDATA;
                    R_WRITE_POINTER <= NEXT_POINTER(R_WRITE_POINTER, G_EVENT_FIFO_DEPTH);
                END IF;

                IF V_POP THEN
                    R_EVENT_WORD   <= R_EVENT_MEMORY(R_READ_POINTER);
                    R_READ_POINTER <= NEXT_POINTER(R_READ_POINTER, G_EVENT_FIFO_DEPTH);
                END IF;

                IF V_PUSH AND NOT V_POP THEN
                    R_FIFO_COUNT <= R_FIFO_COUNT + 1;
                ELSIF V_POP AND NOT V_PUSH THEN
                    R_FIFO_COUNT <= R_FIFO_COUNT - 1;
                END IF;

                CASE R_OUTPUT_STATE IS
                    WHEN ST_IDLE =>
                        R_EVENT_INDEX <= 0;

                        IF S_RESPONSE_TVALID = '1' THEN
                            R_OUTPUT_STATE <= ST_RESPONSE;
                        ELSIF R_FIFO_COUNT > 0 THEN
                            R_OUTPUT_STATE <= ST_EVENT;
                        END IF;

                    WHEN ST_EVENT =>
                        IF M_AXIS_TREADY = '1' THEN
                            IF R_EVENT_INDEX = 4 THEN
                                R_EVENT_INDEX  <= 0;
                                R_OUTPUT_STATE <= ST_IDLE;
                                R_EVENT_SENT   <= '1';
                            ELSE
                                R_EVENT_INDEX <= R_EVENT_INDEX + 1;
                            END IF;
                        END IF;

                    WHEN ST_RESPONSE =>
                        IF S_RESPONSE_TVALID = '1' AND M_AXIS_TREADY = '1' AND S_RESPONSE_TLAST = '1' THEN
                            R_OUTPUT_STATE  <= ST_IDLE;
                            R_RESPONSE_SENT <= '1';
                        END IF;
                END CASE;
            END IF;
        END IF;
    END PROCESS P_FIFO_AND_STATE;

    FIFO_LEVEL_O <= STD_LOGIC_VECTOR(TO_UNSIGNED(R_FIFO_COUNT, FIFO_LEVEL_O'LENGTH));
    FIFO_FULL_O  <= '1' WHEN R_FIFO_COUNT = G_EVENT_FIFO_DEPTH ELSE '0';
    EVENT_SENT_O <= R_EVENT_SENT;
    RESPONSE_SENT_O <= R_RESPONSE_SENT;

END ARCHITECTURE RTL;
