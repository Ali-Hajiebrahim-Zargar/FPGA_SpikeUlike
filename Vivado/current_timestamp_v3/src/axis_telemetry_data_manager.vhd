LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY AXIS_TELEMETRY_DATA_MANAGER IS
    GENERIC (
        G_VERSION           : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"03";
        G_MAX_PAYLOAD_BYTES : POSITIVE := 256;
        G_HPU_SOURCE_ID     : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"09"
    );
    PORT (
        CLK_I : IN STD_LOGIC;
        RST_I : IN STD_LOGIC;

        TIME_I : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

        S_DAC1_TDATA_I  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        S_DAC1_TVALID_I : IN  STD_LOGIC;
        S_DAC1_TREADY_O : OUT STD_LOGIC;
        S_DAC1_TLAST_I  : IN  STD_LOGIC;

        S_DAC2_TDATA_I  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        S_DAC2_TVALID_I : IN  STD_LOGIC;
        S_DAC2_TREADY_O : OUT STD_LOGIC;
        S_DAC2_TLAST_I  : IN  STD_LOGIC;

        S_DAC3_TDATA_I  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        S_DAC3_TVALID_I : IN  STD_LOGIC;
        S_DAC3_TREADY_O : OUT STD_LOGIC;
        S_DAC3_TLAST_I  : IN  STD_LOGIC;

        S_DAC4_TDATA_I  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        S_DAC4_TVALID_I : IN  STD_LOGIC;
        S_DAC4_TREADY_O : OUT STD_LOGIC;
        S_DAC4_TLAST_I  : IN  STD_LOGIC;

        S_ADC1_TDATA_I  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        S_ADC1_TVALID_I : IN  STD_LOGIC;
        S_ADC1_TREADY_O : OUT STD_LOGIC;
        S_ADC1_TLAST_I  : IN  STD_LOGIC;

        S_ADC2_TDATA_I  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        S_ADC2_TVALID_I : IN  STD_LOGIC;
        S_ADC2_TREADY_O : OUT STD_LOGIC;
        S_ADC2_TLAST_I  : IN  STD_LOGIC;

        S_ADC3_TDATA_I  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        S_ADC3_TVALID_I : IN  STD_LOGIC;
        S_ADC3_TREADY_O : OUT STD_LOGIC;
        S_ADC3_TLAST_I  : IN  STD_LOGIC;

        S_ADC4_TDATA_I  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        S_ADC4_TVALID_I : IN  STD_LOGIC;
        S_ADC4_TREADY_O : OUT STD_LOGIC;
        S_ADC4_TLAST_I  : IN  STD_LOGIC;

        S_HPU_TDATA_I  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        S_HPU_TVALID_I : IN  STD_LOGIC;
        S_HPU_TREADY_O : OUT STD_LOGIC;
        S_HPU_TLAST_I  : IN  STD_LOGIC;

        M_AXIS_TDATA_O  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        M_AXIS_TVALID_O : OUT STD_LOGIC;
        M_AXIS_TREADY_I : IN  STD_LOGIC;
        M_AXIS_TLAST_O  : OUT STD_LOGIC;

        ACTIVE_SOURCE_O : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        PACKET_SENT_O   : OUT STD_LOGIC;
        OVERFLOW_O      : OUT STD_LOGIC
    );


END ENTITY AXIS_TELEMETRY_DATA_MANAGER;

ARCHITECTURE RTL OF AXIS_TELEMETRY_DATA_MANAGER IS

    ATTRIBUTE X_INTERFACE_INFO : STRING;
    ATTRIBUTE X_INTERFACE_PARAMETER : STRING;

    ATTRIBUTE X_INTERFACE_INFO OF CLK_I : SIGNAL IS "xilinx.com:signal:clock:1.0 CLK_I CLK";
    ATTRIBUTE X_INTERFACE_PARAMETER OF CLK_I : SIGNAL IS "XIL_INTERFACENAME CLK_I, ASSOCIATED_BUSIF M_AXIS_O:S_ADC1_I:S_ADC2_I:S_ADC3_I:S_ADC4_I:S_DAC1_I:S_DAC2_I:S_DAC3_I:S_DAC4_I:S_HPU_I, ASSOCIATED_RESET RST_I, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0";

    ATTRIBUTE X_INTERFACE_INFO OF RST_I : SIGNAL IS "xilinx.com:signal:reset:1.0 RST_I RST";
    ATTRIBUTE X_INTERFACE_PARAMETER OF RST_I : SIGNAL IS "XIL_INTERFACENAME RST_I, POLARITY ACTIVE_HIGH";

    ATTRIBUTE X_INTERFACE_INFO OF S_DAC1_TDATA_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_DAC1_I TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF S_DAC1_TVALID_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_DAC1_I TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF S_DAC1_TREADY_O : SIGNAL IS "xilinx.com:interface:axis:1.0 S_DAC1_I TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF S_DAC1_TLAST_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_DAC1_I TLAST";
    ATTRIBUTE X_INTERFACE_INFO OF S_DAC2_TDATA_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_DAC2_I TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF S_DAC2_TVALID_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_DAC2_I TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF S_DAC2_TREADY_O : SIGNAL IS "xilinx.com:interface:axis:1.0 S_DAC2_I TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF S_DAC2_TLAST_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_DAC2_I TLAST";
    ATTRIBUTE X_INTERFACE_INFO OF S_DAC3_TDATA_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_DAC3_I TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF S_DAC3_TVALID_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_DAC3_I TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF S_DAC3_TREADY_O : SIGNAL IS "xilinx.com:interface:axis:1.0 S_DAC3_I TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF S_DAC3_TLAST_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_DAC3_I TLAST";
    ATTRIBUTE X_INTERFACE_INFO OF S_DAC4_TDATA_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_DAC4_I TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF S_DAC4_TVALID_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_DAC4_I TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF S_DAC4_TREADY_O : SIGNAL IS "xilinx.com:interface:axis:1.0 S_DAC4_I TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF S_DAC4_TLAST_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_DAC4_I TLAST";
    ATTRIBUTE X_INTERFACE_INFO OF S_ADC1_TDATA_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_ADC1_I TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF S_ADC1_TVALID_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_ADC1_I TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF S_ADC1_TREADY_O : SIGNAL IS "xilinx.com:interface:axis:1.0 S_ADC1_I TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF S_ADC1_TLAST_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_ADC1_I TLAST";
    ATTRIBUTE X_INTERFACE_INFO OF S_ADC2_TDATA_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_ADC2_I TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF S_ADC2_TVALID_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_ADC2_I TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF S_ADC2_TREADY_O : SIGNAL IS "xilinx.com:interface:axis:1.0 S_ADC2_I TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF S_ADC2_TLAST_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_ADC2_I TLAST";
    ATTRIBUTE X_INTERFACE_INFO OF S_ADC3_TDATA_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_ADC3_I TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF S_ADC3_TVALID_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_ADC3_I TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF S_ADC3_TREADY_O : SIGNAL IS "xilinx.com:interface:axis:1.0 S_ADC3_I TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF S_ADC3_TLAST_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_ADC3_I TLAST";
    ATTRIBUTE X_INTERFACE_INFO OF S_ADC4_TDATA_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_ADC4_I TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF S_ADC4_TVALID_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_ADC4_I TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF S_ADC4_TREADY_O : SIGNAL IS "xilinx.com:interface:axis:1.0 S_ADC4_I TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF S_ADC4_TLAST_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_ADC4_I TLAST";
    ATTRIBUTE X_INTERFACE_INFO OF S_HPU_TDATA_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_HPU_I TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF S_HPU_TVALID_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_HPU_I TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF S_HPU_TREADY_O : SIGNAL IS "xilinx.com:interface:axis:1.0 S_HPU_I TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF S_HPU_TLAST_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_HPU_I TLAST";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXIS_TDATA_O : SIGNAL IS "xilinx.com:interface:axis:1.0 M_AXIS_O TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXIS_TVALID_O : SIGNAL IS "xilinx.com:interface:axis:1.0 M_AXIS_O TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXIS_TREADY_I : SIGNAL IS "xilinx.com:interface:axis:1.0 M_AXIS_O TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXIS_TLAST_O : SIGNAL IS "xilinx.com:interface:axis:1.0 M_AXIS_O TLAST";

    CONSTANT C_NUM_SOURCES : INTEGER := 9;

    CONSTANT C_DAC1 : INTEGER := 0;
    CONSTANT C_DAC2 : INTEGER := 1;
    CONSTANT C_DAC3 : INTEGER := 2;
    CONSTANT C_DAC4 : INTEGER := 3;
    CONSTANT C_ADC1 : INTEGER := 4;
    CONSTANT C_ADC2 : INTEGER := 5;
    CONSTANT C_ADC3 : INTEGER := 6;
    CONSTANT C_ADC4 : INTEGER := 7;
    CONSTANT C_HPU  : INTEGER := 8;

    TYPE T_STATE IS (ST_IDLE, ST_HEADER, ST_PAYLOAD, ST_CLEAR);

    TYPE T_BYTE_ARRAY IS ARRAY (0 TO C_NUM_SOURCES - 1) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    TYPE T_FLAG_ARRAY IS ARRAY (0 TO C_NUM_SOURCES - 1) OF STD_LOGIC;
    TYPE T_COUNT_ARRAY IS ARRAY (0 TO C_NUM_SOURCES - 1) OF INTEGER RANGE 0 TO G_MAX_PAYLOAD_BYTES;
    TYPE T_TIME_ARRAY IS ARRAY (0 TO C_NUM_SOURCES - 1) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
    TYPE T_SOURCE_ID_ARRAY IS ARRAY (0 TO C_NUM_SOURCES - 1) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    TYPE T_PAYLOAD_MEMORY IS ARRAY (0 TO C_NUM_SOURCES - 1, 0 TO G_MAX_PAYLOAD_BYTES - 1) OF STD_LOGIC_VECTOR(7 DOWNTO 0);

    CONSTANT C_SOURCE_ID : T_SOURCE_ID_ARRAY := (
        C_DAC1 => X"01",
        C_DAC2 => X"02",
        C_DAC3 => X"03",
        C_DAC4 => X"04",
        C_ADC1 => X"05",
        C_ADC2 => X"06",
        C_ADC3 => X"07",
        C_ADC4 => X"08",
        C_HPU  => G_HPU_SOURCE_ID
    );

    SIGNAL W_SRC_TDATA  : T_BYTE_ARRAY;
    SIGNAL W_SRC_TVALID : T_FLAG_ARRAY;
    SIGNAL W_SRC_TLAST  : T_FLAG_ARRAY;
    SIGNAL R_SRC_TREADY : T_FLAG_ARRAY := (OTHERS => '0');

    SIGNAL R_PAYLOAD_BUFFER : T_PAYLOAD_MEMORY;
    SIGNAL R_WRITE_COUNT    : T_COUNT_ARRAY := (OTHERS => 0);
    SIGNAL R_PACKET_LENGTH  : T_COUNT_ARRAY := (OTHERS => 0);
    SIGNAL R_PACKET_TIME    : T_TIME_ARRAY := (OTHERS => (OTHERS => '0'));
    SIGNAL R_PACKET_VALID   : T_FLAG_ARRAY := (OTHERS => '0');
    SIGNAL R_PACKET_CLEAR   : T_FLAG_ARRAY := (OTHERS => '0');
    SIGNAL R_DROP_ACTIVE    : T_FLAG_ARRAY := (OTHERS => '0');

    SIGNAL R_STATE         : T_STATE := ST_IDLE;
    SIGNAL R_RR_POINTER    : INTEGER RANGE 0 TO C_NUM_SOURCES - 1 := 0;
    SIGNAL R_ACTIVE_SOURCE : INTEGER RANGE 0 TO C_NUM_SOURCES - 1 := 0;
    SIGNAL R_ACTIVE_LENGTH : INTEGER RANGE 0 TO G_MAX_PAYLOAD_BYTES := 0;
    SIGNAL R_ACTIVE_TIME   : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL R_TEL_SEQ       : UNSIGNED(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL R_HEADER_INDEX  : INTEGER RANGE 0 TO 7 := 0;
    SIGNAL R_PAYLOAD_INDEX : INTEGER RANGE 0 TO G_MAX_PAYLOAD_BYTES - 1 := 0;

    SIGNAL R_M_AXIS_TDATA  : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL R_M_AXIS_TVALID : STD_LOGIC := '0';
    SIGNAL R_M_AXIS_TLAST  : STD_LOGIC := '0';

    SIGNAL R_PACKET_SENT : STD_LOGIC := '0';
    SIGNAL R_OVERFLOW    : STD_LOGIC := '0';

BEGIN

    ASSERT G_MAX_PAYLOAD_BYTES <= 256
        REPORT "G_MAX_PAYLOAD_BYTES MUST BE <= 256 BECAUSE DATA_LENGTH IS 8 BITS AND USES DATA_BYTES - 1."
        SEVERITY FAILURE;

    W_SRC_TDATA(C_DAC1)  <= S_DAC1_TDATA_I;
    W_SRC_TVALID(C_DAC1) <= S_DAC1_TVALID_I;
    W_SRC_TLAST(C_DAC1)  <= S_DAC1_TLAST_I;

    W_SRC_TDATA(C_DAC2)  <= S_DAC2_TDATA_I;
    W_SRC_TVALID(C_DAC2) <= S_DAC2_TVALID_I;
    W_SRC_TLAST(C_DAC2)  <= S_DAC2_TLAST_I;

    W_SRC_TDATA(C_DAC3)  <= S_DAC3_TDATA_I;
    W_SRC_TVALID(C_DAC3) <= S_DAC3_TVALID_I;
    W_SRC_TLAST(C_DAC3)  <= S_DAC3_TLAST_I;

    W_SRC_TDATA(C_DAC4)  <= S_DAC4_TDATA_I;
    W_SRC_TVALID(C_DAC4) <= S_DAC4_TVALID_I;
    W_SRC_TLAST(C_DAC4)  <= S_DAC4_TLAST_I;

    W_SRC_TDATA(C_ADC1)  <= S_ADC1_TDATA_I;
    W_SRC_TVALID(C_ADC1) <= S_ADC1_TVALID_I;
    W_SRC_TLAST(C_ADC1)  <= S_ADC1_TLAST_I;

    W_SRC_TDATA(C_ADC2)  <= S_ADC2_TDATA_I;
    W_SRC_TVALID(C_ADC2) <= S_ADC2_TVALID_I;
    W_SRC_TLAST(C_ADC2)  <= S_ADC2_TLAST_I;

    W_SRC_TDATA(C_ADC3)  <= S_ADC3_TDATA_I;
    W_SRC_TVALID(C_ADC3) <= S_ADC3_TVALID_I;
    W_SRC_TLAST(C_ADC3)  <= S_ADC3_TLAST_I;

    W_SRC_TDATA(C_ADC4)  <= S_ADC4_TDATA_I;
    W_SRC_TVALID(C_ADC4) <= S_ADC4_TVALID_I;
    W_SRC_TLAST(C_ADC4)  <= S_ADC4_TLAST_I;

    W_SRC_TDATA(C_HPU)  <= S_HPU_TDATA_I;
    W_SRC_TVALID(C_HPU) <= S_HPU_TVALID_I;
    W_SRC_TLAST(C_HPU)  <= S_HPU_TLAST_I;

    S_DAC1_TREADY_O <= R_SRC_TREADY(C_DAC1);
    S_DAC2_TREADY_O <= R_SRC_TREADY(C_DAC2);
    S_DAC3_TREADY_O <= R_SRC_TREADY(C_DAC3);
    S_DAC4_TREADY_O <= R_SRC_TREADY(C_DAC4);
    S_ADC1_TREADY_O <= R_SRC_TREADY(C_ADC1);
    S_ADC2_TREADY_O <= R_SRC_TREADY(C_ADC2);
    S_ADC3_TREADY_O <= R_SRC_TREADY(C_ADC3);
    S_ADC4_TREADY_O <= R_SRC_TREADY(C_ADC4);
    S_HPU_TREADY_O  <= R_SRC_TREADY(C_HPU);

    M_AXIS_TDATA_O  <= R_M_AXIS_TDATA;
    M_AXIS_TVALID_O <= R_M_AXIS_TVALID;
    M_AXIS_TLAST_O  <= R_M_AXIS_TLAST;

    ACTIVE_SOURCE_O <= C_SOURCE_ID(R_ACTIVE_SOURCE);
    PACKET_SENT_O   <= R_PACKET_SENT;
    OVERFLOW_O      <= R_OVERFLOW;

    P_READY_COMB : PROCESS (R_PACKET_VALID)
    BEGIN
        FOR I IN 0 TO C_NUM_SOURCES - 1 LOOP
            IF R_PACKET_VALID(I) = '0' THEN
                R_SRC_TREADY(I) <= '1';
            ELSE
                R_SRC_TREADY(I) <= '0';
            END IF;
        END LOOP;
    END PROCESS P_READY_COMB;

    P_CAPTURE_INPUTS : PROCESS (CLK_I)
        VARIABLE V_NEW_COUNT : INTEGER RANGE 0 TO G_MAX_PAYLOAD_BYTES;
    BEGIN
        IF RISING_EDGE(CLK_I) THEN
            IF RST_I = '1' THEN
                R_WRITE_COUNT  <= (OTHERS => 0);
                R_PACKET_LENGTH <= (OTHERS => 0);
                R_PACKET_TIME   <= (OTHERS => (OTHERS => '0'));
                R_PACKET_VALID  <= (OTHERS => '0');
                R_DROP_ACTIVE   <= (OTHERS => '0');
                R_OVERFLOW      <= '0';
            ELSE
                FOR I IN 0 TO C_NUM_SOURCES - 1 LOOP
                    IF R_PACKET_CLEAR(I) = '1' THEN
                        R_PACKET_VALID(I) <= '0';
                    END IF;

                    IF W_SRC_TVALID(I) = '1' AND R_SRC_TREADY(I) = '1' THEN
                        IF R_DROP_ACTIVE(I) = '1' THEN
                            IF W_SRC_TLAST(I) = '1' THEN
                                R_DROP_ACTIVE(I)  <= '0';
                                R_WRITE_COUNT(I)  <= 0;
                            END IF;
                        ELSE
                            IF R_WRITE_COUNT(I) < G_MAX_PAYLOAD_BYTES THEN
                                R_PAYLOAD_BUFFER(I, R_WRITE_COUNT(I)) <= W_SRC_TDATA(I);
                                V_NEW_COUNT := R_WRITE_COUNT(I) + 1;

                                IF W_SRC_TLAST(I) = '1' THEN
                                    R_PACKET_LENGTH(I) <= V_NEW_COUNT;
                                    R_PACKET_TIME(I)   <= TIME_I;
                                    R_PACKET_VALID(I)  <= '1';
                                    R_WRITE_COUNT(I)   <= 0;
                                ELSE
                                    R_WRITE_COUNT(I) <= V_NEW_COUNT;
                                END IF;
                            ELSE
                                R_DROP_ACTIVE(I) <= '1';
                                R_WRITE_COUNT(I) <= 0;
                                R_OVERFLOW       <= '1';
                            END IF;
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        END IF;
    END PROCESS P_CAPTURE_INPUTS;

    P_FRAME_OUTPUT : PROCESS (CLK_I)
        VARIABLE V_FOUND : BOOLEAN;
        VARIABLE V_CAND  : INTEGER RANGE 0 TO C_NUM_SOURCES - 1;
        VARIABLE V_IDX   : INTEGER RANGE 0 TO C_NUM_SOURCES - 1;
    BEGIN
        IF RISING_EDGE(CLK_I) THEN
            R_PACKET_SENT <= '0';

            IF RST_I = '1' THEN
                R_STATE         <= ST_IDLE;
                R_RR_POINTER    <= 0;
                R_ACTIVE_SOURCE <= 0;
                R_ACTIVE_LENGTH <= 0;
                R_ACTIVE_TIME   <= (OTHERS => '0');
                R_TEL_SEQ       <= (OTHERS => '0');
                R_HEADER_INDEX  <= 0;
                R_PAYLOAD_INDEX <= 0;
                R_M_AXIS_TDATA  <= (OTHERS => '0');
                R_M_AXIS_TVALID <= '0';
                R_M_AXIS_TLAST  <= '0';
                R_PACKET_CLEAR   <= (OTHERS => '0');
            ELSE
                IF R_M_AXIS_TVALID = '1' AND M_AXIS_TREADY_I = '0' THEN
                    NULL;
                ELSE
                    R_M_AXIS_TVALID <= '0';
                    R_M_AXIS_TLAST  <= '0';

                    CASE R_STATE IS
                        WHEN ST_IDLE =>
                            V_FOUND := FALSE;
                            V_CAND  := 0;

                            FOR I IN 0 TO C_NUM_SOURCES - 1 LOOP
                                V_IDX := (R_RR_POINTER + I) MOD C_NUM_SOURCES;
                                IF R_PACKET_VALID(V_IDX) = '1' THEN
                                    V_FOUND := TRUE;
                                    V_CAND  := V_IDX;
                                    EXIT;
                                END IF;
                            END LOOP;

                            IF V_FOUND = TRUE THEN
                                R_ACTIVE_SOURCE <= V_CAND;
                                R_ACTIVE_LENGTH <= R_PACKET_LENGTH(V_CAND);
                                R_ACTIVE_TIME   <= R_PACKET_TIME(V_CAND);
                                R_HEADER_INDEX  <= 1;
                                R_PAYLOAD_INDEX <= 0;
                                R_M_AXIS_TDATA  <= G_VERSION;
                                R_M_AXIS_TVALID <= '1';
                                R_STATE         <= ST_HEADER;
                            END IF;

                        WHEN ST_HEADER =>
                            R_M_AXIS_TVALID <= '1';

                            CASE R_HEADER_INDEX IS
                                WHEN 1 =>
                                    R_M_AXIS_TDATA <= STD_LOGIC_VECTOR(R_TEL_SEQ);
                                    R_HEADER_INDEX <= 2;
                                WHEN 2 =>
                                    R_M_AXIS_TDATA <= R_ACTIVE_TIME(31 DOWNTO 24);
                                    R_HEADER_INDEX <= 3;
                                WHEN 3 =>
                                    R_M_AXIS_TDATA <= R_ACTIVE_TIME(23 DOWNTO 16);
                                    R_HEADER_INDEX <= 4;
                                WHEN 4 =>
                                    R_M_AXIS_TDATA <= R_ACTIVE_TIME(15 DOWNTO 8);
                                    R_HEADER_INDEX <= 5;
                                WHEN 5 =>
                                    R_M_AXIS_TDATA <= R_ACTIVE_TIME(7 DOWNTO 0);
                                    R_HEADER_INDEX <= 6;
                                WHEN 6 =>
                                    R_M_AXIS_TDATA <= C_SOURCE_ID(R_ACTIVE_SOURCE);
                                    R_HEADER_INDEX <= 7;
                                WHEN OTHERS =>
                                    R_M_AXIS_TDATA  <= STD_LOGIC_VECTOR(TO_UNSIGNED(R_ACTIVE_LENGTH - 1, 8));
                                    R_PAYLOAD_INDEX <= 0;
                                    R_STATE         <= ST_PAYLOAD;
                            END CASE;

                        WHEN ST_PAYLOAD =>
                            R_M_AXIS_TVALID <= '1';
                            R_M_AXIS_TDATA  <= R_PAYLOAD_BUFFER(R_ACTIVE_SOURCE, R_PAYLOAD_INDEX);

                            IF R_PAYLOAD_INDEX = R_ACTIVE_LENGTH - 1 THEN
                                R_M_AXIS_TLAST <= '1';
                                R_PACKET_CLEAR(R_ACTIVE_SOURCE) <= '1';
                                R_PACKET_SENT <= '1';
                                R_TEL_SEQ <= R_TEL_SEQ + 1;

                                IF R_ACTIVE_SOURCE = C_NUM_SOURCES - 1 THEN
                                    R_RR_POINTER <= 0;
                                ELSE
                                    R_RR_POINTER <= R_ACTIVE_SOURCE + 1;
                                END IF;

                                R_STATE <= ST_CLEAR;
                            ELSE
                                R_PAYLOAD_INDEX <= R_PAYLOAD_INDEX + 1;
                            END IF;

                        WHEN ST_CLEAR =>
                            R_PACKET_CLEAR <= (OTHERS => '0');
                            R_STATE        <= ST_IDLE;
                    END CASE;
                END IF;
            END IF;
        END IF;
    END PROCESS P_FRAME_OUTPUT;

END ARCHITECTURE RTL;
