LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY AXIS_SPIKE_PROGRAMMER IS
    GENERIC (
        G_MAX_PAYLOAD_BYTES     : POSITIVE := 1024;
        G_MAX_CHIP_BITS         : POSITIVE := 65536;
        G_MAX_SERIAL_DIV_HALF   : POSITIVE := 1000000;

        G_INPUT_CLK_HZ          : POSITIVE := 100000000;
        G_SERIAL_CLK_HZ         : POSITIVE := 1000000;

        G_CHIP_BITS_DEFAULT     : POSITIVE := 1024;
        G_MARKER_BYTE           : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"C5"
    );
    PORT (
        ACLK                    : IN  STD_LOGIC;
        ARESETN                 : IN  STD_LOGIC;

        S_AXIS_TDATA            : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        S_AXIS_TVALID           : IN  STD_LOGIC;
        S_AXIS_TREADY           : OUT STD_LOGIC;
        S_AXIS_TLAST            : IN  STD_LOGIC;
        S_AXIS_TKEEP            : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);

        S_AXI_AWADDR            : IN  STD_LOGIC_VECTOR(5 DOWNTO 0);
        S_AXI_AWPROT            : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        S_AXI_AWVALID           : IN  STD_LOGIC;
        S_AXI_AWREADY           : OUT STD_LOGIC;

        S_AXI_WDATA             : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        S_AXI_WSTRB             : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        S_AXI_WVALID            : IN  STD_LOGIC;
        S_AXI_WREADY            : OUT STD_LOGIC;

        S_AXI_BRESP             : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        S_AXI_BVALID            : OUT STD_LOGIC;
        S_AXI_BREADY            : IN  STD_LOGIC;

        S_AXI_ARADDR            : IN  STD_LOGIC_VECTOR(5 DOWNTO 0);
        S_AXI_ARPROT            : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        S_AXI_ARVALID           : IN  STD_LOGIC;
        S_AXI_ARREADY           : OUT STD_LOGIC;

        S_AXI_RDATA             : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        S_AXI_RRESP             : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        S_AXI_RVALID            : OUT STD_LOGIC;
        S_AXI_RREADY            : IN  STD_LOGIC;

        CHIP_ENABLE_O           : OUT STD_LOGIC;
        CHIP_CLK_O              : OUT STD_LOGIC;
        CHIP_DATA_O             : OUT STD_LOGIC;
        CHIP_LATCH_O            : OUT STD_LOGIC;
        CHIP_Q_I                : IN  STD_LOGIC;

        SUCCESS_LED_O           : OUT STD_LOGIC
    );

    ATTRIBUTE X_INTERFACE_INFO      : STRING;
    ATTRIBUTE X_INTERFACE_PARAMETER : STRING;

    ATTRIBUTE X_INTERFACE_INFO OF ACLK : SIGNAL IS "xilinx.com:signal:clock:1.0 ACLK CLK";
    ATTRIBUTE X_INTERFACE_PARAMETER OF ACLK : SIGNAL IS "ASSOCIATED_BUSIF S_AXIS:S_AXI, ASSOCIATED_RESET ARESETN, FREQ_HZ 100000000";
    ATTRIBUTE X_INTERFACE_INFO OF ARESETN : SIGNAL IS "xilinx.com:signal:reset:1.0 ARESETN RST";
    ATTRIBUTE X_INTERFACE_PARAMETER OF ARESETN : SIGNAL IS "POLARITY ACTIVE_LOW";

    ATTRIBUTE X_INTERFACE_INFO OF S_AXIS_TDATA  : SIGNAL IS "xilinx.com:interface:axis:1.0 S_AXIS TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXIS_TVALID : SIGNAL IS "xilinx.com:interface:axis:1.0 S_AXIS TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXIS_TREADY : SIGNAL IS "xilinx.com:interface:axis:1.0 S_AXIS TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXIS_TLAST  : SIGNAL IS "xilinx.com:interface:axis:1.0 S_AXIS TLAST";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXIS_TKEEP  : SIGNAL IS "xilinx.com:interface:axis:1.0 S_AXIS TKEEP";
    ATTRIBUTE X_INTERFACE_PARAMETER OF S_AXIS_TDATA : SIGNAL IS "HAS_TLAST 1, HAS_TKEEP 1, TDATA_NUM_BYTES 1, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0, FREQ_HZ 100000000";

    ATTRIBUTE X_INTERFACE_INFO OF S_AXI_AWADDR  : SIGNAL IS "xilinx.com:interface:aximm:1.0 S_AXI AWADDR";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXI_AWPROT  : SIGNAL IS "xilinx.com:interface:aximm:1.0 S_AXI AWPROT";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXI_AWVALID : SIGNAL IS "xilinx.com:interface:aximm:1.0 S_AXI AWVALID";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXI_AWREADY : SIGNAL IS "xilinx.com:interface:aximm:1.0 S_AXI AWREADY";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXI_WDATA   : SIGNAL IS "xilinx.com:interface:aximm:1.0 S_AXI WDATA";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXI_WSTRB   : SIGNAL IS "xilinx.com:interface:aximm:1.0 S_AXI WSTRB";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXI_WVALID  : SIGNAL IS "xilinx.com:interface:aximm:1.0 S_AXI WVALID";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXI_WREADY  : SIGNAL IS "xilinx.com:interface:aximm:1.0 S_AXI WREADY";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXI_BRESP   : SIGNAL IS "xilinx.com:interface:aximm:1.0 S_AXI BRESP";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXI_BVALID  : SIGNAL IS "xilinx.com:interface:aximm:1.0 S_AXI BVALID";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXI_BREADY  : SIGNAL IS "xilinx.com:interface:aximm:1.0 S_AXI BREADY";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXI_ARADDR  : SIGNAL IS "xilinx.com:interface:aximm:1.0 S_AXI ARADDR";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXI_ARPROT  : SIGNAL IS "xilinx.com:interface:aximm:1.0 S_AXI ARPROT";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXI_ARVALID : SIGNAL IS "xilinx.com:interface:aximm:1.0 S_AXI ARVALID";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXI_ARREADY : SIGNAL IS "xilinx.com:interface:aximm:1.0 S_AXI ARREADY";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXI_RDATA   : SIGNAL IS "xilinx.com:interface:aximm:1.0 S_AXI RDATA";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXI_RRESP   : SIGNAL IS "xilinx.com:interface:aximm:1.0 S_AXI RRESP";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXI_RVALID  : SIGNAL IS "xilinx.com:interface:aximm:1.0 S_AXI RVALID";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXI_RREADY  : SIGNAL IS "xilinx.com:interface:aximm:1.0 S_AXI RREADY";
    ATTRIBUTE X_INTERFACE_PARAMETER OF S_AXI_AWADDR : SIGNAL IS "PROTOCOL AXI4LITE, DATA_WIDTH 32, ADDR_WIDTH 6, FREQ_HZ 100000000, HAS_BURST 0, HAS_LOCK 0, HAS_PROT 1, HAS_CACHE 0, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, NUM_READ_OUTSTANDING 1, NUM_WRITE_OUTSTANDING 1, MAX_BURST_LENGTH 1";

END ENTITY AXIS_SPIKE_PROGRAMMER;

ARCHITECTURE RTL OF AXIS_SPIKE_PROGRAMMER IS

    FUNCTION F_MAX_NATURAL(A : NATURAL; B : NATURAL) RETURN NATURAL IS
    BEGIN
        IF A > B THEN
            RETURN A;
        ELSE
            RETURN B;
        END IF;
    END FUNCTION;

    FUNCTION F_CLAMP_POSITIVE(
        VALUE_IN : NATURAL;
        MIN_IN   : POSITIVE;
        MAX_IN   : POSITIVE
    ) RETURN POSITIVE IS
    BEGIN
        IF VALUE_IN < MIN_IN THEN
            RETURN MIN_IN;
        ELSIF VALUE_IN > MAX_IN THEN
            RETURN MAX_IN;
        ELSE
            RETURN VALUE_IN;
        END IF;
    END FUNCTION;

    FUNCTION F_DEFAULT_SERIAL_DIV_HALF RETURN POSITIVE IS
        VARIABLE V_DIV : NATURAL;
    BEGIN
        V_DIV := G_INPUT_CLK_HZ / (2 * G_SERIAL_CLK_HZ);

        IF V_DIV < 1 THEN
            V_DIV := 1;
        END IF;

        IF V_DIV > G_MAX_SERIAL_DIV_HALF THEN
            V_DIV := G_MAX_SERIAL_DIV_HALF;
        END IF;

        RETURN V_DIV;
    END FUNCTION;

    FUNCTION F_TO_SLV32(VALUE_IN : NATURAL) RETURN STD_LOGIC_VECTOR IS
    BEGIN
        RETURN STD_LOGIC_VECTOR(TO_UNSIGNED(VALUE_IN, 32));
    END FUNCTION;

    CONSTANT C_DEFAULT_SERIAL_DIV_HALF : POSITIVE := F_DEFAULT_SERIAL_DIV_HALF;
    CONSTANT C_DEFAULT_CHIP_BITS       : POSITIVE := F_CLAMP_POSITIVE(
                                                        G_CHIP_BITS_DEFAULT,
                                                        1,
                                                        G_MAX_CHIP_BITS
                                                    );

    CONSTANT C_MAX_PAYLOAD_BITS        : NATURAL := G_MAX_PAYLOAD_BYTES * 8;
    CONSTANT C_MAX_SHIFT_BITS          : NATURAL := F_MAX_NATURAL(
                                                        G_MAX_CHIP_BITS + 8,
                                                        C_MAX_PAYLOAD_BITS + 8
                                                    );

    CONSTANT C_REG_CONTROL             : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0000";
    CONSTANT C_REG_STATUS              : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0001";
    CONSTANT C_REG_SERIAL_DIV_HALF     : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0010";
    CONSTANT C_REG_CHIP_BITS           : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0011";
    CONSTANT C_REG_MARKER_BYTE         : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0100";
    CONSTANT C_REG_READBACK_BYTE       : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0101";
    CONSTANT C_REG_PAYLOAD_BYTES       : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0110";
    CONSTANT C_REG_TOTAL_SHIFT_BITS    : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0111";

    TYPE T_STATE IS (
        ST_IDLE,
        ST_LOAD_PAYLOAD,
        ST_PREPARE_PROGRAM,
        ST_SHIFT_LOW,
        ST_SHIFT_HIGH,
        ST_CHECK_RESULT,
        ST_DONE
    );

    TYPE T_PAYLOAD_MEM IS ARRAY (0 TO G_MAX_PAYLOAD_BYTES - 1) OF STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL STATE_R                     : T_STATE := ST_IDLE;

    SIGNAL PAYLOAD_MEM_R               : T_PAYLOAD_MEM;
    SIGNAL PAYLOAD_COUNT_R             : NATURAL RANGE 0 TO G_MAX_PAYLOAD_BYTES := 0;

    SIGNAL BIT_INDEX_R                 : NATURAL RANGE 0 TO C_MAX_SHIFT_BITS := 0;
    SIGNAL TOTAL_SHIFT_BITS_R          : NATURAL RANGE 0 TO C_MAX_SHIFT_BITS := 0;
    SIGNAL DIV_COUNT_R                 : NATURAL RANGE 0 TO G_MAX_SERIAL_DIV_HALF := 0;

    SIGNAL READBACK_SHIFT_R            : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL READBACK_VALID_R            : STD_LOGIC := '0';

    SIGNAL MODULE_ENABLE_R             : STD_LOGIC := '1';
    SIGNAL SERIAL_DIV_HALF_R           : NATURAL RANGE 1 TO G_MAX_SERIAL_DIV_HALF := C_DEFAULT_SERIAL_DIV_HALF;
    SIGNAL CHIP_BITS_R                 : NATURAL RANGE 1 TO G_MAX_CHIP_BITS := C_DEFAULT_CHIP_BITS;
    SIGNAL MARKER_BYTE_R               : STD_LOGIC_VECTOR(7 DOWNTO 0) := G_MARKER_BYTE;

    SIGNAL BUSY_R                      : STD_LOGIC := '0';
    SIGNAL DONE_R                      : STD_LOGIC := '0';
    SIGNAL SUCCESS_R                   : STD_LOGIC := '0';
    SIGNAL ERROR_R                     : STD_LOGIC := '0';
    SIGNAL PAYLOAD_OVERFLOW_R          : STD_LOGIC := '0';

    SIGNAL CLEAR_STATUS_PULSE_R        : STD_LOGIC := '0';
    SIGNAL ABORT_PULSE_R               : STD_LOGIC := '0';

    SIGNAL CHIP_ENABLE_R               : STD_LOGIC := '1';
    SIGNAL CHIP_CLK_R                  : STD_LOGIC := '0';
    SIGNAL CHIP_DATA_R                 : STD_LOGIC := '0';
    SIGNAL CHIP_LATCH_R                : STD_LOGIC := '1';

    SIGNAL CHIP_Q_META_R               : STD_LOGIC := '0';
    SIGNAL CHIP_Q_SYNC_R               : STD_LOGIC := '0';

    SIGNAL AXIL_AWADDR_R               : STD_LOGIC_VECTOR(5 DOWNTO 0) := (OTHERS => '0');
    SIGNAL AXIL_WDATA_R                : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL AXIL_WSTRB_R                : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');

    SIGNAL AXIL_AW_VALID_R             : STD_LOGIC := '0';
    SIGNAL AXIL_W_VALID_R              : STD_LOGIC := '0';

    SIGNAL S_AXI_AWREADY_R             : STD_LOGIC := '0';
    SIGNAL S_AXI_WREADY_R              : STD_LOGIC := '0';
    SIGNAL S_AXI_BVALID_R              : STD_LOGIC := '0';
    SIGNAL S_AXI_ARREADY_R             : STD_LOGIC := '0';
    SIGNAL S_AXI_RDATA_R               : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL S_AXI_RVALID_R              : STD_LOGIC := '0';

BEGIN

    S_AXIS_TREADY <= '1' WHEN MODULE_ENABLE_R = '1' AND
                              (STATE_R = ST_IDLE OR STATE_R = ST_LOAD_PAYLOAD)
                     ELSE '0';

    S_AXI_AWREADY <= S_AXI_AWREADY_R;
    S_AXI_WREADY  <= S_AXI_WREADY_R;
    S_AXI_BRESP   <= "00";
    S_AXI_BVALID  <= S_AXI_BVALID_R;

    S_AXI_ARREADY <= S_AXI_ARREADY_R;
    S_AXI_RDATA   <= S_AXI_RDATA_R;
    S_AXI_RRESP   <= "00";
    S_AXI_RVALID  <= S_AXI_RVALID_R;

    CHIP_ENABLE_O <= CHIP_ENABLE_R;
    CHIP_CLK_O    <= CHIP_CLK_R;
    CHIP_DATA_O   <= CHIP_DATA_R;
    CHIP_LATCH_O  <= CHIP_LATCH_R;

    SUCCESS_LED_O <= SUCCESS_R;

    PROCESS(ACLK)
        VARIABLE READ_DATA_V   : STD_LOGIC_VECTOR(31 DOWNTO 0);
        VARIABLE WRITE_VALUE_V : NATURAL;
    BEGIN
        IF RISING_EDGE(ACLK) THEN

            S_AXI_AWREADY_R      <= '0';
            S_AXI_WREADY_R       <= '0';
            S_AXI_ARREADY_R      <= '0';

            CLEAR_STATUS_PULSE_R <= '0';
            ABORT_PULSE_R        <= '0';

            IF ARESETN = '0' THEN

                AXIL_AWADDR_R        <= (OTHERS => '0');
                AXIL_WDATA_R         <= (OTHERS => '0');
                AXIL_WSTRB_R         <= (OTHERS => '0');

                AXIL_AW_VALID_R      <= '0';
                AXIL_W_VALID_R       <= '0';

                S_AXI_AWREADY_R      <= '0';
                S_AXI_WREADY_R       <= '0';
                S_AXI_BVALID_R       <= '0';
                S_AXI_ARREADY_R      <= '0';
                S_AXI_RDATA_R        <= (OTHERS => '0');
                S_AXI_RVALID_R       <= '0';

                MODULE_ENABLE_R      <= '1';
                SERIAL_DIV_HALF_R    <= C_DEFAULT_SERIAL_DIV_HALF;
                CHIP_BITS_R          <= C_DEFAULT_CHIP_BITS;
                MARKER_BYTE_R        <= G_MARKER_BYTE;

                CLEAR_STATUS_PULSE_R <= '0';
                ABORT_PULSE_R        <= '0';

            ELSE

                IF AXIL_AW_VALID_R = '0' AND S_AXI_AWVALID = '1' THEN
                    AXIL_AWADDR_R   <= S_AXI_AWADDR;
                    AXIL_AW_VALID_R <= '1';
                    S_AXI_AWREADY_R <= '1';
                END IF;

                IF AXIL_W_VALID_R = '0' AND S_AXI_WVALID = '1' THEN
                    AXIL_WDATA_R    <= S_AXI_WDATA;
                    AXIL_WSTRB_R    <= S_AXI_WSTRB;
                    AXIL_W_VALID_R  <= '1';
                    S_AXI_WREADY_R  <= '1';
                END IF;

                IF AXIL_AW_VALID_R = '1' AND AXIL_W_VALID_R = '1' AND S_AXI_BVALID_R = '0' THEN

                    CASE AXIL_AWADDR_R(5 DOWNTO 2) IS

                        WHEN C_REG_CONTROL =>
                            MODULE_ENABLE_R <= AXIL_WDATA_R(0);

                            IF AXIL_WDATA_R(1) = '1' THEN
                                CLEAR_STATUS_PULSE_R <= '1';
                            END IF;

                            IF AXIL_WDATA_R(2) = '1' THEN
                                ABORT_PULSE_R <= '1';
                            END IF;

                        WHEN C_REG_SERIAL_DIV_HALF =>
                            IF BUSY_R = '0' THEN
                                WRITE_VALUE_V := TO_INTEGER(UNSIGNED(AXIL_WDATA_R(23 DOWNTO 0)));

                                IF WRITE_VALUE_V < 1 THEN
                                    SERIAL_DIV_HALF_R <= 1;
                                ELSIF WRITE_VALUE_V > G_MAX_SERIAL_DIV_HALF THEN
                                    SERIAL_DIV_HALF_R <= G_MAX_SERIAL_DIV_HALF;
                                ELSE
                                    SERIAL_DIV_HALF_R <= WRITE_VALUE_V;
                                END IF;
                            END IF;

                        WHEN C_REG_CHIP_BITS =>
                            IF BUSY_R = '0' THEN
                                WRITE_VALUE_V := TO_INTEGER(UNSIGNED(AXIL_WDATA_R(23 DOWNTO 0)));

                                IF WRITE_VALUE_V < 1 THEN
                                    CHIP_BITS_R <= 1;
                                ELSIF WRITE_VALUE_V > G_MAX_CHIP_BITS THEN
                                    CHIP_BITS_R <= G_MAX_CHIP_BITS;
                                ELSE
                                    CHIP_BITS_R <= WRITE_VALUE_V;
                                END IF;
                            END IF;

                        WHEN C_REG_MARKER_BYTE =>
                            IF BUSY_R = '0' THEN
                                MARKER_BYTE_R <= AXIL_WDATA_R(7 DOWNTO 0);
                            END IF;

                        WHEN OTHERS =>
                            NULL;

                    END CASE;

                    AXIL_AW_VALID_R <= '0';
                    AXIL_W_VALID_R  <= '0';
                    S_AXI_BVALID_R  <= '1';

                END IF;

                IF S_AXI_BVALID_R = '1' AND S_AXI_BREADY = '1' THEN
                    S_AXI_BVALID_R <= '0';
                END IF;

                IF S_AXI_RVALID_R = '1' AND S_AXI_RREADY = '1' THEN
                    S_AXI_RVALID_R <= '0';
                END IF;

                IF S_AXI_ARVALID = '1' AND S_AXI_RVALID_R = '0' THEN

                    READ_DATA_V := (OTHERS => '0');

                    CASE S_AXI_ARADDR(5 DOWNTO 2) IS

                        WHEN C_REG_CONTROL =>
                            READ_DATA_V(0) := MODULE_ENABLE_R;
                            READ_DATA_V(1) := '0';
                            READ_DATA_V(2) := '0';

                        WHEN C_REG_STATUS =>
                            READ_DATA_V(0) := BUSY_R;
                            READ_DATA_V(1) := DONE_R;
                            READ_DATA_V(2) := SUCCESS_R;
                            READ_DATA_V(3) := ERROR_R;
                            READ_DATA_V(4) := PAYLOAD_OVERFLOW_R;
                            READ_DATA_V(5) := READBACK_VALID_R;

                        WHEN C_REG_SERIAL_DIV_HALF =>
                            READ_DATA_V := F_TO_SLV32(SERIAL_DIV_HALF_R);

                        WHEN C_REG_CHIP_BITS =>
                            READ_DATA_V := F_TO_SLV32(CHIP_BITS_R);

                        WHEN C_REG_MARKER_BYTE =>
                            READ_DATA_V(7 DOWNTO 0) := MARKER_BYTE_R;

                        WHEN C_REG_READBACK_BYTE =>
                            READ_DATA_V(7 DOWNTO 0) := READBACK_SHIFT_R;

                        WHEN C_REG_PAYLOAD_BYTES =>
                            READ_DATA_V := F_TO_SLV32(PAYLOAD_COUNT_R);

                        WHEN C_REG_TOTAL_SHIFT_BITS =>
                            READ_DATA_V := F_TO_SLV32(TOTAL_SHIFT_BITS_R);

                        WHEN OTHERS =>
                            READ_DATA_V := (OTHERS => '0');

                    END CASE;

                    S_AXI_RDATA_R   <= READ_DATA_V;
                    S_AXI_RVALID_R  <= '1';
                    S_AXI_ARREADY_R <= '1';

                END IF;

            END IF;
        END IF;
    END PROCESS;

    PROCESS(ACLK)
        VARIABLE PAYLOAD_BITS_V      : NATURAL;
        VARIABLE MIN_SHIFT_A_V       : NATURAL;
        VARIABLE MIN_SHIFT_B_V       : NATURAL;
        VARIABLE REL_BIT_V           : NATURAL;
        VARIABLE BYTE_INDEX_V        : NATURAL;
        VARIABLE BIT_IN_BYTE_V       : NATURAL;
        VARIABLE TX_BIT_V            : STD_LOGIC;
        VARIABLE READBACK_POS_V      : NATURAL;
        VARIABLE OVERFLOW_NOW_V      : STD_LOGIC;
    BEGIN
        IF RISING_EDGE(ACLK) THEN

            CHIP_Q_META_R <= CHIP_Q_I;
            CHIP_Q_SYNC_R <= CHIP_Q_META_R;

            IF ARESETN = '0' THEN

                STATE_R            <= ST_IDLE;

                PAYLOAD_COUNT_R    <= 0;
                BIT_INDEX_R        <= 0;
                TOTAL_SHIFT_BITS_R <= 0;
                DIV_COUNT_R        <= 0;

                READBACK_SHIFT_R   <= (OTHERS => '0');
                READBACK_VALID_R   <= '0';

                BUSY_R             <= '0';
                DONE_R             <= '0';
                SUCCESS_R          <= '0';
                ERROR_R            <= '0';
                PAYLOAD_OVERFLOW_R <= '0';

                CHIP_ENABLE_R      <= '1';
                CHIP_CLK_R         <= '0';
                CHIP_DATA_R        <= '0';
                CHIP_LATCH_R       <= '1';

            ELSE

                IF CLEAR_STATUS_PULSE_R = '1' THEN
                    DONE_R             <= '0';
                    SUCCESS_R          <= '0';
                    ERROR_R            <= '0';
                    PAYLOAD_OVERFLOW_R <= '0';
                    READBACK_VALID_R   <= '0';
                    READBACK_SHIFT_R   <= (OTHERS => '0');
                END IF;

                IF ABORT_PULSE_R = '1' OR MODULE_ENABLE_R = '0' THEN

                    STATE_R         <= ST_IDLE;
                    BUSY_R          <= '0';

                    CHIP_ENABLE_R   <= '1';
                    CHIP_CLK_R      <= '0';
                    CHIP_DATA_R     <= '0';
                    CHIP_LATCH_R    <= '1';

                    PAYLOAD_COUNT_R <= 0;
                    BIT_INDEX_R     <= 0;
                    DIV_COUNT_R     <= 0;

                ELSE

                    CASE STATE_R IS

                        WHEN ST_IDLE =>

                            BUSY_R        <= '0';
                            CHIP_ENABLE_R <= '1';
                            CHIP_CLK_R    <= '0';
                            CHIP_DATA_R   <= '0';
                            CHIP_LATCH_R  <= '1';

                            IF S_AXIS_TVALID = '1' THEN

                                DONE_R             <= '0';
                                SUCCESS_R          <= '0';
                                ERROR_R            <= '0';
                                PAYLOAD_OVERFLOW_R <= '0';
                                READBACK_VALID_R   <= '0';
                                READBACK_SHIFT_R   <= (OTHERS => '0');

                                PAYLOAD_COUNT_R <= 0;

                                IF S_AXIS_TKEEP(0) = '1' THEN
                                    PAYLOAD_MEM_R(0) <= S_AXIS_TDATA;
                                    PAYLOAD_COUNT_R  <= 1;
                                END IF;

                                IF S_AXIS_TLAST = '1' THEN
                                    STATE_R <= ST_PREPARE_PROGRAM;
                                ELSE
                                    BUSY_R  <= '1';
                                    STATE_R <= ST_LOAD_PAYLOAD;
                                END IF;

                            END IF;

                        WHEN ST_LOAD_PAYLOAD =>

                            BUSY_R <= '1';

                            IF S_AXIS_TVALID = '1' THEN

                                OVERFLOW_NOW_V := '0';

                                IF S_AXIS_TKEEP(0) = '1' THEN

                                    IF PAYLOAD_COUNT_R < G_MAX_PAYLOAD_BYTES THEN
                                        PAYLOAD_MEM_R(PAYLOAD_COUNT_R) <= S_AXIS_TDATA;
                                        PAYLOAD_COUNT_R                <= PAYLOAD_COUNT_R + 1;
                                    ELSE
                                        PAYLOAD_OVERFLOW_R <= '1';
                                        ERROR_R            <= '1';
                                        OVERFLOW_NOW_V     := '1';
                                    END IF;

                                END IF;

                                IF S_AXIS_TLAST = '1' THEN

                                    IF PAYLOAD_OVERFLOW_R = '1' OR OVERFLOW_NOW_V = '1' THEN
                                        DONE_R  <= '1';
                                        STATE_R <= ST_DONE;
                                    ELSE
                                        STATE_R <= ST_PREPARE_PROGRAM;
                                    END IF;

                                END IF;

                            END IF;

                        WHEN ST_PREPARE_PROGRAM =>

                            BUSY_R          <= '1';

                            CHIP_ENABLE_R   <= '0';
                            CHIP_LATCH_R    <= '0';
                            CHIP_CLK_R      <= '0';
                            CHIP_DATA_R     <= '0';

                            PAYLOAD_BITS_V  := PAYLOAD_COUNT_R * 8;
                            MIN_SHIFT_A_V   := 8 + PAYLOAD_BITS_V;
                            MIN_SHIFT_B_V   := CHIP_BITS_R + 8;

                            TOTAL_SHIFT_BITS_R <= F_MAX_NATURAL(MIN_SHIFT_A_V, MIN_SHIFT_B_V);

                            BIT_INDEX_R        <= 0;
                            DIV_COUNT_R        <= 0;
                            READBACK_SHIFT_R   <= (OTHERS => '0');
                            READBACK_VALID_R   <= '0';

                            STATE_R            <= ST_SHIFT_LOW;

                        WHEN ST_SHIFT_LOW =>

                            BUSY_R        <= '1';
                            CHIP_ENABLE_R <= '0';
                            CHIP_LATCH_R  <= '0';
                            CHIP_CLK_R    <= '0';

                            TX_BIT_V := '0';

                            IF BIT_INDEX_R < 8 THEN

                                TX_BIT_V := MARKER_BYTE_R(BIT_INDEX_R);

                            ELSIF BIT_INDEX_R < (8 + (PAYLOAD_COUNT_R * 8)) THEN

                                REL_BIT_V     := BIT_INDEX_R - 8;
                                BYTE_INDEX_V  := REL_BIT_V / 8;
                                BIT_IN_BYTE_V := REL_BIT_V MOD 8;

                                IF BYTE_INDEX_V < G_MAX_PAYLOAD_BYTES THEN
                                    TX_BIT_V := PAYLOAD_MEM_R(BYTE_INDEX_V)(BIT_IN_BYTE_V);
                                ELSE
                                    TX_BIT_V := '0';
                                END IF;

                            ELSE

                                TX_BIT_V := '0';

                            END IF;

                            CHIP_DATA_R <= TX_BIT_V;

                            IF DIV_COUNT_R >= SERIAL_DIV_HALF_R - 1 THEN
                                DIV_COUNT_R <= 0;
                                CHIP_CLK_R  <= '1';
                                STATE_R     <= ST_SHIFT_HIGH;
                            ELSE
                                DIV_COUNT_R <= DIV_COUNT_R + 1;
                            END IF;

                        WHEN ST_SHIFT_HIGH =>

                            BUSY_R        <= '1';
                            CHIP_ENABLE_R <= '0';
                            CHIP_LATCH_R  <= '0';
                            CHIP_CLK_R    <= '1';

                            IF DIV_COUNT_R >= SERIAL_DIV_HALF_R - 1 THEN

                                IF BIT_INDEX_R >= CHIP_BITS_R AND BIT_INDEX_R < CHIP_BITS_R + 8 THEN
                                    READBACK_POS_V := BIT_INDEX_R - CHIP_BITS_R;

                                    IF READBACK_POS_V < 8 THEN
                                        READBACK_SHIFT_R(READBACK_POS_V) <= CHIP_Q_SYNC_R;

                                        IF READBACK_POS_V = 7 THEN
                                            READBACK_VALID_R <= '1';
                                        END IF;
                                    END IF;
                                END IF;

                                DIV_COUNT_R <= 0;
                                CHIP_CLK_R  <= '0';

                                IF BIT_INDEX_R + 1 >= TOTAL_SHIFT_BITS_R THEN
                                    STATE_R <= ST_CHECK_RESULT;
                                ELSE
                                    BIT_INDEX_R <= BIT_INDEX_R + 1;
                                    STATE_R     <= ST_SHIFT_LOW;
                                END IF;

                            ELSE
                                DIV_COUNT_R <= DIV_COUNT_R + 1;
                            END IF;

                        WHEN ST_CHECK_RESULT =>

                            BUSY_R        <= '1';
                            CHIP_ENABLE_R <= '0';
                            CHIP_LATCH_R  <= '0';
                            CHIP_CLK_R    <= '0';
                            CHIP_DATA_R   <= '0';

                            DONE_R <= '1';

                            IF READBACK_SHIFT_R = MARKER_BYTE_R THEN
                                SUCCESS_R <= '1';
                                ERROR_R   <= '0';
                            ELSE
                                SUCCESS_R <= '0';
                                ERROR_R   <= '1';
                            END IF;

                            STATE_R <= ST_DONE;

                        WHEN ST_DONE =>

                            BUSY_R        <= '0';
                            CHIP_ENABLE_R <= '1';
                            CHIP_LATCH_R  <= '1';
                            CHIP_CLK_R    <= '0';
                            CHIP_DATA_R   <= '0';

                            STATE_R       <= ST_IDLE;

                        WHEN OTHERS =>

                            STATE_R       <= ST_IDLE;
                            BUSY_R        <= '0';
                            CHIP_ENABLE_R <= '1';
                            CHIP_LATCH_R  <= '1';
                            CHIP_CLK_R    <= '0';
                            CHIP_DATA_R   <= '0';

                    END CASE;

                END IF;

            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE RTL;
