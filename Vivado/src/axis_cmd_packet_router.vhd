-- AXIS_CMD_PACKET_ROUTER
-- Packet format, byte based, one packet per AXI4-Stream frame:
--   BYTE 0 : VERSION      expected 0x01 by default
--   BYTE 1 : PACKET_SEQ   ignored by this block, forwarded to no target
--   BYTE 2 : SOURCE_ID    0x00 Spikeulike, 0x01..0x04 DAC1..DAC4, 0x05..0x08 ADC1..ADC4, 0x09 HPU
--   BYTE 3 : DATA_LENGTH  encoded as payload_length_minus_1, so 0x00 means 1 byte, 0xFF means 256 bytes
--   BYTE 4.. : DATA       only this DATA part is routed to the selected output
--
-- Notes:
--   * Input AXI4-Stream is 8-bit. If your DMA is 32/64-bit, put AXIS Data Width Converter before this block.
--   * TKEEP is accepted and generated as 1-bit. Invalid input TKEEP='0' bytes are consumed but not forwarded.
--   * The router sends exactly DATA_LENGTH+1 payload bytes to the selected target.
--   * If the incoming stream is longer than DATA_LENGTH+1, extra bytes are dropped until TLAST.
--   * If TLAST comes early, SHORT_PACKET pulses for one clock.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY AXIS_CMD_PACKET_ROUTER IS
    GENERIC (
        G_VERSION_VALUE      : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"01";

        G_ID_SPIKEULIKE     : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"00";
        G_ID_DAC1           : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"01";
        G_ID_DAC2           : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"02";
        G_ID_DAC3           : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"03";
        G_ID_DAC4           : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"04";
        G_ID_ADC1           : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"05";
        G_ID_ADC2           : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"06";
        G_ID_ADC3           : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"07";
        G_ID_ADC4           : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"08";
        G_ID_HPU            : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"09"
    );
    PORT (
        ACLK                : IN  STD_LOGIC;
        ARESETN             : IN  STD_LOGIC;

        S_AXIS_TDATA        : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        S_AXIS_TKEEP        : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
        S_AXIS_TVALID       : IN  STD_LOGIC;
        S_AXIS_TREADY       : OUT STD_LOGIC;
        S_AXIS_TLAST        : IN  STD_LOGIC;

        M_SPIKE_TDATA       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        M_SPIKE_TKEEP       : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        M_SPIKE_TVALID      : OUT STD_LOGIC;
        M_SPIKE_TREADY      : IN  STD_LOGIC;
        M_SPIKE_TLAST       : OUT STD_LOGIC;

        M_DAC1_TDATA        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        M_DAC1_TKEEP        : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        M_DAC1_TVALID       : OUT STD_LOGIC;
        M_DAC1_TREADY       : IN  STD_LOGIC;
        M_DAC1_TLAST        : OUT STD_LOGIC;

        M_DAC2_TDATA        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        M_DAC2_TKEEP        : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        M_DAC2_TVALID       : OUT STD_LOGIC;
        M_DAC2_TREADY       : IN  STD_LOGIC;
        M_DAC2_TLAST        : OUT STD_LOGIC;

        M_DAC3_TDATA        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        M_DAC3_TKEEP        : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        M_DAC3_TVALID       : OUT STD_LOGIC;
        M_DAC3_TREADY       : IN  STD_LOGIC;
        M_DAC3_TLAST        : OUT STD_LOGIC;

        M_DAC4_TDATA        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        M_DAC4_TKEEP        : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        M_DAC4_TVALID       : OUT STD_LOGIC;
        M_DAC4_TREADY       : IN  STD_LOGIC;
        M_DAC4_TLAST        : OUT STD_LOGIC;

        M_ADC1_TDATA        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        M_ADC1_TKEEP        : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        M_ADC1_TVALID       : OUT STD_LOGIC;
        M_ADC1_TREADY       : IN  STD_LOGIC;
        M_ADC1_TLAST        : OUT STD_LOGIC;

        M_ADC2_TDATA        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        M_ADC2_TKEEP        : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        M_ADC2_TVALID       : OUT STD_LOGIC;
        M_ADC2_TREADY       : IN  STD_LOGIC;
        M_ADC2_TLAST        : OUT STD_LOGIC;

        M_ADC3_TDATA        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        M_ADC3_TKEEP        : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        M_ADC3_TVALID       : OUT STD_LOGIC;
        M_ADC3_TREADY       : IN  STD_LOGIC;
        M_ADC3_TLAST        : OUT STD_LOGIC;

        M_ADC4_TDATA        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        M_ADC4_TKEEP        : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        M_ADC4_TVALID       : OUT STD_LOGIC;
        M_ADC4_TREADY       : IN  STD_LOGIC;
        M_ADC4_TLAST        : OUT STD_LOGIC;

        M_HPU_TDATA         : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        M_HPU_TKEEP         : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        M_HPU_TVALID        : OUT STD_LOGIC;
        M_HPU_TREADY        : IN  STD_LOGIC;
        M_HPU_TLAST         : OUT STD_LOGIC;

        CURRENT_ROUTE       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        PACKET_DONE         : OUT STD_LOGIC;
        INVALID_ID          : OUT STD_LOGIC;
        BAD_VERSION         : OUT STD_LOGIC;
        SHORT_PACKET        : OUT STD_LOGIC;
        LENGTH_MISMATCH     : OUT STD_LOGIC
    );
END ENTITY AXIS_CMD_PACKET_ROUTER;

ARCHITECTURE RTL OF AXIS_CMD_PACKET_ROUTER IS

    ATTRIBUTE X_INTERFACE_INFO : STRING;
    ATTRIBUTE X_INTERFACE_PARAMETER : STRING;

    ATTRIBUTE X_INTERFACE_INFO OF ACLK    : SIGNAL IS "xilinx.com:signal:clock:1.0 ACLK CLK";
    ATTRIBUTE X_INTERFACE_PARAMETER OF ACLK : SIGNAL IS "ASSOCIATED_BUSIF S_AXIS:M_SPIKE:M_DAC1:M_DAC2:M_DAC3:M_DAC4:M_ADC1:M_ADC2:M_ADC3:M_ADC4:M_HPU, ASSOCIATED_RESET ARESETN";
    ATTRIBUTE X_INTERFACE_INFO OF ARESETN : SIGNAL IS "xilinx.com:signal:reset:1.0 ARESETN RST";
    ATTRIBUTE X_INTERFACE_PARAMETER OF ARESETN : SIGNAL IS "POLARITY ACTIVE_LOW";

    ATTRIBUTE X_INTERFACE_INFO OF S_AXIS_TDATA  : SIGNAL IS "xilinx.com:interface:axis:1.0 S_AXIS TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXIS_TKEEP  : SIGNAL IS "xilinx.com:interface:axis:1.0 S_AXIS TKEEP";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXIS_TVALID : SIGNAL IS "xilinx.com:interface:axis:1.0 S_AXIS TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXIS_TREADY : SIGNAL IS "xilinx.com:interface:axis:1.0 S_AXIS TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF S_AXIS_TLAST  : SIGNAL IS "xilinx.com:interface:axis:1.0 S_AXIS TLAST";

    ATTRIBUTE X_INTERFACE_INFO OF M_SPIKE_TDATA  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_SPIKE TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF M_SPIKE_TKEEP  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_SPIKE TKEEP";
    ATTRIBUTE X_INTERFACE_INFO OF M_SPIKE_TVALID : SIGNAL IS "xilinx.com:interface:axis:1.0 M_SPIKE TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF M_SPIKE_TREADY : SIGNAL IS "xilinx.com:interface:axis:1.0 M_SPIKE TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF M_SPIKE_TLAST  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_SPIKE TLAST";

    ATTRIBUTE X_INTERFACE_INFO OF M_DAC1_TDATA  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_DAC1 TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF M_DAC1_TKEEP  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_DAC1 TKEEP";
    ATTRIBUTE X_INTERFACE_INFO OF M_DAC1_TVALID : SIGNAL IS "xilinx.com:interface:axis:1.0 M_DAC1 TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF M_DAC1_TREADY : SIGNAL IS "xilinx.com:interface:axis:1.0 M_DAC1 TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF M_DAC1_TLAST  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_DAC1 TLAST";

    ATTRIBUTE X_INTERFACE_INFO OF M_DAC2_TDATA  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_DAC2 TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF M_DAC2_TKEEP  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_DAC2 TKEEP";
    ATTRIBUTE X_INTERFACE_INFO OF M_DAC2_TVALID : SIGNAL IS "xilinx.com:interface:axis:1.0 M_DAC2 TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF M_DAC2_TREADY : SIGNAL IS "xilinx.com:interface:axis:1.0 M_DAC2 TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF M_DAC2_TLAST  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_DAC2 TLAST";

    ATTRIBUTE X_INTERFACE_INFO OF M_DAC3_TDATA  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_DAC3 TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF M_DAC3_TKEEP  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_DAC3 TKEEP";
    ATTRIBUTE X_INTERFACE_INFO OF M_DAC3_TVALID : SIGNAL IS "xilinx.com:interface:axis:1.0 M_DAC3 TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF M_DAC3_TREADY : SIGNAL IS "xilinx.com:interface:axis:1.0 M_DAC3 TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF M_DAC3_TLAST  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_DAC3 TLAST";

    ATTRIBUTE X_INTERFACE_INFO OF M_DAC4_TDATA  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_DAC4 TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF M_DAC4_TKEEP  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_DAC4 TKEEP";
    ATTRIBUTE X_INTERFACE_INFO OF M_DAC4_TVALID : SIGNAL IS "xilinx.com:interface:axis:1.0 M_DAC4 TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF M_DAC4_TREADY : SIGNAL IS "xilinx.com:interface:axis:1.0 M_DAC4 TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF M_DAC4_TLAST  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_DAC4 TLAST";

    ATTRIBUTE X_INTERFACE_INFO OF M_ADC1_TDATA  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_ADC1 TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF M_ADC1_TKEEP  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_ADC1 TKEEP";
    ATTRIBUTE X_INTERFACE_INFO OF M_ADC1_TVALID : SIGNAL IS "xilinx.com:interface:axis:1.0 M_ADC1 TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF M_ADC1_TREADY : SIGNAL IS "xilinx.com:interface:axis:1.0 M_ADC1 TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF M_ADC1_TLAST  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_ADC1 TLAST";

    ATTRIBUTE X_INTERFACE_INFO OF M_ADC2_TDATA  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_ADC2 TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF M_ADC2_TKEEP  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_ADC2 TKEEP";
    ATTRIBUTE X_INTERFACE_INFO OF M_ADC2_TVALID : SIGNAL IS "xilinx.com:interface:axis:1.0 M_ADC2 TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF M_ADC2_TREADY : SIGNAL IS "xilinx.com:interface:axis:1.0 M_ADC2 TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF M_ADC2_TLAST  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_ADC2 TLAST";

    ATTRIBUTE X_INTERFACE_INFO OF M_ADC3_TDATA  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_ADC3 TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF M_ADC3_TKEEP  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_ADC3 TKEEP";
    ATTRIBUTE X_INTERFACE_INFO OF M_ADC3_TVALID : SIGNAL IS "xilinx.com:interface:axis:1.0 M_ADC3 TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF M_ADC3_TREADY : SIGNAL IS "xilinx.com:interface:axis:1.0 M_ADC3 TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF M_ADC3_TLAST  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_ADC3 TLAST";

    ATTRIBUTE X_INTERFACE_INFO OF M_ADC4_TDATA  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_ADC4 TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF M_ADC4_TKEEP  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_ADC4 TKEEP";
    ATTRIBUTE X_INTERFACE_INFO OF M_ADC4_TVALID : SIGNAL IS "xilinx.com:interface:axis:1.0 M_ADC4 TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF M_ADC4_TREADY : SIGNAL IS "xilinx.com:interface:axis:1.0 M_ADC4 TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF M_ADC4_TLAST  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_ADC4 TLAST";

    ATTRIBUTE X_INTERFACE_INFO OF M_HPU_TDATA   : SIGNAL IS "xilinx.com:interface:axis:1.0 M_HPU TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF M_HPU_TKEEP   : SIGNAL IS "xilinx.com:interface:axis:1.0 M_HPU TKEEP";
    ATTRIBUTE X_INTERFACE_INFO OF M_HPU_TVALID  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_HPU TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF M_HPU_TREADY  : SIGNAL IS "xilinx.com:interface:axis:1.0 M_HPU TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF M_HPU_TLAST   : SIGNAL IS "xilinx.com:interface:axis:1.0 M_HPU TLAST";

    TYPE STATE_T IS (ST_VERSION, ST_SEQ, ST_SOURCE, ST_LENGTH, ST_PAYLOAD, ST_DROP);
    TYPE ROUTE_T IS (RT_NONE, RT_SPIKE, RT_DAC1, RT_DAC2, RT_DAC3, RT_DAC4, RT_ADC1, RT_ADC2, RT_ADC3, RT_ADC4, RT_HPU);

    SIGNAL STATE_R              : STATE_T := ST_VERSION;
    SIGNAL STATE_N              : STATE_T := ST_VERSION;

    SIGNAL ROUTE_R              : ROUTE_T := RT_NONE;
    SIGNAL ROUTE_N              : ROUTE_T := RT_NONE;

    SIGNAL PAYLOAD_LAST_INDEX_R : UNSIGNED(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL PAYLOAD_LAST_INDEX_N : UNSIGNED(7 DOWNTO 0) := (OTHERS => '0');

    SIGNAL PAYLOAD_COUNT_R      : UNSIGNED(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL PAYLOAD_COUNT_N      : UNSIGNED(7 DOWNTO 0) := (OTHERS => '0');

    SIGNAL PACKET_DONE_R        : STD_LOGIC := '0';
    SIGNAL PACKET_DONE_N        : STD_LOGIC := '0';
    SIGNAL INVALID_ID_R         : STD_LOGIC := '0';
    SIGNAL INVALID_ID_N         : STD_LOGIC := '0';
    SIGNAL BAD_VERSION_R        : STD_LOGIC := '0';
    SIGNAL BAD_VERSION_N        : STD_LOGIC := '0';
    SIGNAL SHORT_PACKET_R       : STD_LOGIC := '0';
    SIGNAL SHORT_PACKET_N       : STD_LOGIC := '0';
    SIGNAL LENGTH_MISMATCH_R    : STD_LOGIC := '0';
    SIGNAL LENGTH_MISMATCH_N    : STD_LOGIC := '0';

    FUNCTION DECODE_ID(ID_VALUE : STD_LOGIC_VECTOR(7 DOWNTO 0)) RETURN ROUTE_T IS
    BEGIN
        IF ID_VALUE = G_ID_SPIKEULIKE THEN
            RETURN RT_SPIKE;
        ELSIF ID_VALUE = G_ID_DAC1 THEN
            RETURN RT_DAC1;
        ELSIF ID_VALUE = G_ID_DAC2 THEN
            RETURN RT_DAC2;
        ELSIF ID_VALUE = G_ID_DAC3 THEN
            RETURN RT_DAC3;
        ELSIF ID_VALUE = G_ID_DAC4 THEN
            RETURN RT_DAC4;
        ELSIF ID_VALUE = G_ID_ADC1 THEN
            RETURN RT_ADC1;
        ELSIF ID_VALUE = G_ID_ADC2 THEN
            RETURN RT_ADC2;
        ELSIF ID_VALUE = G_ID_ADC3 THEN
            RETURN RT_ADC3;
        ELSIF ID_VALUE = G_ID_ADC4 THEN
            RETURN RT_ADC4;
        ELSIF ID_VALUE = G_ID_HPU THEN
            RETURN RT_HPU;
        ELSE
            RETURN RT_NONE;
        END IF;
    END FUNCTION;

    FUNCTION ROUTE_CODE(ROUTE_VALUE : ROUTE_T) RETURN STD_LOGIC_VECTOR IS
    BEGIN
        CASE ROUTE_VALUE IS
            WHEN RT_SPIKE => RETURN X"0";
            WHEN RT_DAC1  => RETURN X"1";
            WHEN RT_DAC2  => RETURN X"2";
            WHEN RT_DAC3  => RETURN X"3";
            WHEN RT_DAC4  => RETURN X"4";
            WHEN RT_ADC1  => RETURN X"5";
            WHEN RT_ADC2  => RETURN X"6";
            WHEN RT_ADC3  => RETURN X"7";
            WHEN RT_ADC4  => RETURN X"8";
            WHEN RT_HPU   => RETURN X"9";
            WHEN OTHERS   => RETURN X"F";
        END CASE;
    END FUNCTION;

BEGIN

    PROCESS (STATE_R, ROUTE_R, PAYLOAD_LAST_INDEX_R, PAYLOAD_COUNT_R, S_AXIS_TDATA, S_AXIS_TKEEP, S_AXIS_TVALID, S_AXIS_TLAST, M_SPIKE_TREADY, M_DAC1_TREADY, M_DAC2_TREADY, M_DAC3_TREADY, M_DAC4_TREADY, M_ADC1_TREADY, M_ADC2_TREADY, M_ADC3_TREADY, M_ADC4_TREADY, M_HPU_TREADY)
        VARIABLE SELECTED_READY_V : STD_LOGIC;
        VARIABLE ACCEPT_V         : STD_LOGIC;
        VARIABLE ROUTE_TEMP_V     : ROUTE_T;
        VARIABLE LAST_PAYLOAD_V   : STD_LOGIC;
        VARIABLE FORWARD_VALID_V  : STD_LOGIC;
        VARIABLE FORWARD_LAST_V   : STD_LOGIC;
    BEGIN
        STATE_N              <= STATE_R;
        ROUTE_N              <= ROUTE_R;
        PAYLOAD_LAST_INDEX_N <= PAYLOAD_LAST_INDEX_R;
        PAYLOAD_COUNT_N      <= PAYLOAD_COUNT_R;

        PACKET_DONE_N        <= '0';
        INVALID_ID_N         <= '0';
        BAD_VERSION_N        <= '0';
        SHORT_PACKET_N       <= '0';
        LENGTH_MISMATCH_N    <= '0';

        S_AXIS_TREADY        <= '0';

        M_SPIKE_TDATA        <= S_AXIS_TDATA;
        M_DAC1_TDATA         <= S_AXIS_TDATA;
        M_DAC2_TDATA         <= S_AXIS_TDATA;
        M_DAC3_TDATA         <= S_AXIS_TDATA;
        M_DAC4_TDATA         <= S_AXIS_TDATA;
        M_ADC1_TDATA         <= S_AXIS_TDATA;
        M_ADC2_TDATA         <= S_AXIS_TDATA;
        M_ADC3_TDATA         <= S_AXIS_TDATA;
        M_ADC4_TDATA         <= S_AXIS_TDATA;
        M_HPU_TDATA          <= S_AXIS_TDATA;

        M_SPIKE_TKEEP        <= "1";
        M_DAC1_TKEEP         <= "1";
        M_DAC2_TKEEP         <= "1";
        M_DAC3_TKEEP         <= "1";
        M_DAC4_TKEEP         <= "1";
        M_ADC1_TKEEP         <= "1";
        M_ADC2_TKEEP         <= "1";
        M_ADC3_TKEEP         <= "1";
        M_ADC4_TKEEP         <= "1";
        M_HPU_TKEEP          <= "1";

        M_SPIKE_TVALID       <= '0';
        M_DAC1_TVALID        <= '0';
        M_DAC2_TVALID        <= '0';
        M_DAC3_TVALID        <= '0';
        M_DAC4_TVALID        <= '0';
        M_ADC1_TVALID        <= '0';
        M_ADC2_TVALID        <= '0';
        M_ADC3_TVALID        <= '0';
        M_ADC4_TVALID        <= '0';
        M_HPU_TVALID         <= '0';

        M_SPIKE_TLAST        <= '0';
        M_DAC1_TLAST         <= '0';
        M_DAC2_TLAST         <= '0';
        M_DAC3_TLAST         <= '0';
        M_DAC4_TLAST         <= '0';
        M_ADC1_TLAST         <= '0';
        M_ADC2_TLAST         <= '0';
        M_ADC3_TLAST         <= '0';
        M_ADC4_TLAST         <= '0';
        M_HPU_TLAST          <= '0';

        SELECTED_READY_V     := '1';
        ACCEPT_V             := '0';
        ROUTE_TEMP_V         := ROUTE_R;
        LAST_PAYLOAD_V       := '0';
        FORWARD_VALID_V      := '0';
        FORWARD_LAST_V       := '0';

        CASE ROUTE_R IS
            WHEN RT_SPIKE => SELECTED_READY_V := M_SPIKE_TREADY;
            WHEN RT_DAC1  => SELECTED_READY_V := M_DAC1_TREADY;
            WHEN RT_DAC2  => SELECTED_READY_V := M_DAC2_TREADY;
            WHEN RT_DAC3  => SELECTED_READY_V := M_DAC3_TREADY;
            WHEN RT_DAC4  => SELECTED_READY_V := M_DAC4_TREADY;
            WHEN RT_ADC1  => SELECTED_READY_V := M_ADC1_TREADY;
            WHEN RT_ADC2  => SELECTED_READY_V := M_ADC2_TREADY;
            WHEN RT_ADC3  => SELECTED_READY_V := M_ADC3_TREADY;
            WHEN RT_ADC4  => SELECTED_READY_V := M_ADC4_TREADY;
            WHEN RT_HPU   => SELECTED_READY_V := M_HPU_TREADY;
            WHEN OTHERS   => SELECTED_READY_V := '1';
        END CASE;

        IF PAYLOAD_COUNT_R = PAYLOAD_LAST_INDEX_R THEN
            LAST_PAYLOAD_V := '1';
        END IF;

        CASE STATE_R IS

            WHEN ST_VERSION =>
                S_AXIS_TREADY <= '1';
                ACCEPT_V      := S_AXIS_TVALID;

                IF ACCEPT_V = '1' THEN
                    ROUTE_N              <= RT_NONE;
                    PAYLOAD_COUNT_N      <= (OTHERS => '0');
                    PAYLOAD_LAST_INDEX_N <= (OTHERS => '0');

                    IF S_AXIS_TDATA /= G_VERSION_VALUE THEN
                        BAD_VERSION_N <= '1';
                        IF S_AXIS_TLAST = '1' THEN
                            STATE_N <= ST_VERSION;
                        ELSE
                            STATE_N <= ST_DROP;
                        END IF;
                    ELSIF S_AXIS_TLAST = '1' THEN
                        SHORT_PACKET_N <= '1';
                        STATE_N        <= ST_VERSION;
                    ELSE
                        STATE_N <= ST_SEQ;
                    END IF;
                END IF;

            WHEN ST_SEQ =>
                S_AXIS_TREADY <= '1';
                ACCEPT_V      := S_AXIS_TVALID;

                IF ACCEPT_V = '1' THEN
                    IF S_AXIS_TLAST = '1' THEN
                        SHORT_PACKET_N <= '1';
                        STATE_N        <= ST_VERSION;
                    ELSE
                        STATE_N <= ST_SOURCE;
                    END IF;
                END IF;

            WHEN ST_SOURCE =>
                S_AXIS_TREADY <= '1';
                ACCEPT_V      := S_AXIS_TVALID;

                IF ACCEPT_V = '1' THEN
                    ROUTE_TEMP_V := DECODE_ID(S_AXIS_TDATA);
                    ROUTE_N      <= ROUTE_TEMP_V;

                    IF ROUTE_TEMP_V = RT_NONE THEN
                        INVALID_ID_N <= '1';
                        IF S_AXIS_TLAST = '1' THEN
                            STATE_N <= ST_VERSION;
                        ELSE
                            STATE_N <= ST_DROP;
                        END IF;
                    ELSIF S_AXIS_TLAST = '1' THEN
                        SHORT_PACKET_N <= '1';
                        STATE_N        <= ST_VERSION;
                    ELSE
                        STATE_N <= ST_LENGTH;
                    END IF;
                END IF;

            WHEN ST_LENGTH =>
                S_AXIS_TREADY <= '1';
                ACCEPT_V      := S_AXIS_TVALID;

                IF ACCEPT_V = '1' THEN
                    PAYLOAD_LAST_INDEX_N <= UNSIGNED(S_AXIS_TDATA);
                    PAYLOAD_COUNT_N      <= (OTHERS => '0');

                    IF S_AXIS_TLAST = '1' THEN
                        SHORT_PACKET_N <= '1';
                        STATE_N        <= ST_VERSION;
                    ELSE
                        STATE_N <= ST_PAYLOAD;
                    END IF;
                END IF;

            WHEN ST_PAYLOAD =>
                S_AXIS_TREADY <= SELECTED_READY_V;
                ACCEPT_V      := S_AXIS_TVALID AND SELECTED_READY_V;

                FORWARD_VALID_V := S_AXIS_TVALID AND S_AXIS_TKEEP(0);
                FORWARD_LAST_V  := LAST_PAYLOAD_V OR S_AXIS_TLAST;

                CASE ROUTE_R IS
                    WHEN RT_SPIKE =>
                        M_SPIKE_TVALID <= FORWARD_VALID_V;
                        M_SPIKE_TLAST  <= FORWARD_LAST_V;
                    WHEN RT_DAC1 =>
                        M_DAC1_TVALID  <= FORWARD_VALID_V;
                        M_DAC1_TLAST   <= FORWARD_LAST_V;
                    WHEN RT_DAC2 =>
                        M_DAC2_TVALID  <= FORWARD_VALID_V;
                        M_DAC2_TLAST   <= FORWARD_LAST_V;
                    WHEN RT_DAC3 =>
                        M_DAC3_TVALID  <= FORWARD_VALID_V;
                        M_DAC3_TLAST   <= FORWARD_LAST_V;
                    WHEN RT_DAC4 =>
                        M_DAC4_TVALID  <= FORWARD_VALID_V;
                        M_DAC4_TLAST   <= FORWARD_LAST_V;
                    WHEN RT_ADC1 =>
                        M_ADC1_TVALID  <= FORWARD_VALID_V;
                        M_ADC1_TLAST   <= FORWARD_LAST_V;
                    WHEN RT_ADC2 =>
                        M_ADC2_TVALID  <= FORWARD_VALID_V;
                        M_ADC2_TLAST   <= FORWARD_LAST_V;
                    WHEN RT_ADC3 =>
                        M_ADC3_TVALID  <= FORWARD_VALID_V;
                        M_ADC3_TLAST   <= FORWARD_LAST_V;
                    WHEN RT_ADC4 =>
                        M_ADC4_TVALID  <= FORWARD_VALID_V;
                        M_ADC4_TLAST   <= FORWARD_LAST_V;
                    WHEN RT_HPU =>
                        M_HPU_TVALID   <= FORWARD_VALID_V;
                        M_HPU_TLAST    <= FORWARD_LAST_V;
                    WHEN OTHERS =>
                        NULL;
                END CASE;

                IF ACCEPT_V = '1' THEN
                    IF LAST_PAYLOAD_V = '1' THEN
                        PACKET_DONE_N <= '1';
                        ROUTE_N       <= RT_NONE;
                        PAYLOAD_COUNT_N <= (OTHERS => '0');

                        IF S_AXIS_TLAST = '1' THEN
                            STATE_N <= ST_VERSION;
                        ELSE
                            LENGTH_MISMATCH_N <= '1';
                            STATE_N           <= ST_DROP;
                        END IF;
                    ELSE
                        PAYLOAD_COUNT_N <= PAYLOAD_COUNT_R + 1;

                        IF S_AXIS_TLAST = '1' THEN
                            SHORT_PACKET_N  <= '1';
                            PACKET_DONE_N   <= '1';
                            STATE_N         <= ST_VERSION;
                            ROUTE_N         <= RT_NONE;
                            PAYLOAD_COUNT_N <= (OTHERS => '0');
                        END IF;
                    END IF;
                END IF;

            WHEN ST_DROP =>
                S_AXIS_TREADY <= '1';
                ACCEPT_V      := S_AXIS_TVALID;

                IF ACCEPT_V = '1' AND S_AXIS_TLAST = '1' THEN
                    STATE_N              <= ST_VERSION;
                    ROUTE_N              <= RT_NONE;
                    PAYLOAD_COUNT_N      <= (OTHERS => '0');
                    PAYLOAD_LAST_INDEX_N <= (OTHERS => '0');
                END IF;

        END CASE;
    END PROCESS;

    PROCESS (ACLK)
    BEGIN
        IF RISING_EDGE(ACLK) THEN
            IF ARESETN = '0' THEN
                STATE_R              <= ST_VERSION;
                ROUTE_R              <= RT_NONE;
                PAYLOAD_LAST_INDEX_R <= (OTHERS => '0');
                PAYLOAD_COUNT_R      <= (OTHERS => '0');
                PACKET_DONE_R        <= '0';
                INVALID_ID_R         <= '0';
                BAD_VERSION_R        <= '0';
                SHORT_PACKET_R       <= '0';
                LENGTH_MISMATCH_R    <= '0';
            ELSE
                STATE_R              <= STATE_N;
                ROUTE_R              <= ROUTE_N;
                PAYLOAD_LAST_INDEX_R <= PAYLOAD_LAST_INDEX_N;
                PAYLOAD_COUNT_R      <= PAYLOAD_COUNT_N;
                PACKET_DONE_R        <= PACKET_DONE_N;
                INVALID_ID_R         <= INVALID_ID_N;
                BAD_VERSION_R        <= BAD_VERSION_N;
                SHORT_PACKET_R       <= SHORT_PACKET_N;
                LENGTH_MISMATCH_R    <= LENGTH_MISMATCH_N;
            END IF;
        END IF;
    END PROCESS;

    CURRENT_ROUTE   <= ROUTE_CODE(ROUTE_R);
    PACKET_DONE     <= PACKET_DONE_R;
    INVALID_ID      <= INVALID_ID_R;
    BAD_VERSION     <= BAD_VERSION_R;
    SHORT_PACKET    <= SHORT_PACKET_R;
    LENGTH_MISMATCH <= LENGTH_MISMATCH_R;

END ARCHITECTURE RTL;
