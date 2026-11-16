LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY AD7266_AXIS_DRIVER IS
    GENERIC (
        G_SPI_DIV_HALF      : POSITIVE := 4;
        G_ACQ_CYCLES        : NATURAL  := 16;
        G_CHANNEL_COUNT     : POSITIVE := 6
    );
    PORT (
        CLK_I               : IN  STD_LOGIC;
        RST_I               : IN  STD_LOGIC;

        S_CMD_TDATA_I       : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        S_CMD_TVALID_I      : IN  STD_LOGIC;
        S_CMD_TREADY_O      : OUT STD_LOGIC;
        S_CMD_TLAST_I       : IN  STD_LOGIC;

        M_AXIS_TDATA_O      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        M_AXIS_TVALID_O     : OUT STD_LOGIC;
        M_AXIS_TREADY_I     : IN  STD_LOGIC;
        M_AXIS_TLAST_O      : OUT STD_LOGIC;

        ADC_CS_O            : OUT STD_LOGIC;
        ADC_SCLK_O          : OUT STD_LOGIC;
        ADC_A_O             : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        ADC_DOUTA_I         : IN  STD_LOGIC;
        ADC_DOUTB_I         : IN  STD_LOGIC;

        ACTIVE_MASK_O       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        BUSY_O              : OUT STD_LOGIC;
        SAMPLE_VALID_PULSE_O: OUT STD_LOGIC
    );


END ENTITY AD7266_AXIS_DRIVER;

ARCHITECTURE RTL OF AD7266_AXIS_DRIVER IS
    ATTRIBUTE X_INTERFACE_INFO : STRING;
    ATTRIBUTE X_INTERFACE_PARAMETER : STRING;

    ATTRIBUTE X_INTERFACE_INFO OF CLK_I : SIGNAL IS "xilinx.com:signal:clock:1.0 CLK_I CLK";
    ATTRIBUTE X_INTERFACE_PARAMETER OF CLK_I : SIGNAL IS "XIL_INTERFACENAME CLK_I, ASSOCIATED_BUSIF S_CMD_I:M_AXIS_O, ASSOCIATED_RESET RST_I, FREQ_HZ 100000000";

    ATTRIBUTE X_INTERFACE_INFO OF RST_I : SIGNAL IS "xilinx.com:signal:reset:1.0 RST_I RST";
    ATTRIBUTE X_INTERFACE_PARAMETER OF RST_I : SIGNAL IS "XIL_INTERFACENAME RST_I, POLARITY ACTIVE_HIGH";

    ATTRIBUTE X_INTERFACE_INFO OF S_CMD_TDATA_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_CMD_I TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF S_CMD_TVALID_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_CMD_I TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF S_CMD_TREADY_O : SIGNAL IS "xilinx.com:interface:axis:1.0 S_CMD_I TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF S_CMD_TLAST_I : SIGNAL IS "xilinx.com:interface:axis:1.0 S_CMD_I TLAST";

    ATTRIBUTE X_INTERFACE_INFO OF M_AXIS_TDATA_O : SIGNAL IS "xilinx.com:interface:axis:1.0 M_AXIS_O TDATA";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXIS_TVALID_O : SIGNAL IS "xilinx.com:interface:axis:1.0 M_AXIS_O TVALID";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXIS_TREADY_I : SIGNAL IS "xilinx.com:interface:axis:1.0 M_AXIS_O TREADY";
    ATTRIBUTE X_INTERFACE_INFO OF M_AXIS_TLAST_O : SIGNAL IS "xilinx.com:interface:axis:1.0 M_AXIS_O TLAST";

    TYPE T_STATE IS (
        ST_IDLE,
        ST_ACQUIRE,
        ST_SCLK_LOW,
        ST_SCLK_HIGH,
        ST_PACKET_PREP,
        ST_SEND
    );

    TYPE T_PACKET_ARRAY IS ARRAY (0 TO 5) OF STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL STATE_R              : T_STATE := ST_IDLE;

    SIGNAL MASK_R               : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL CMD_FIRST_BYTE_R     : STD_LOGIC := '1';

    SIGNAL PAIR_IDX_R           : NATURAL RANGE 0 TO 5 := 0;
    SIGNAL CURRENT_PAIR_R       : NATURAL RANGE 0 TO 5 := 0;

    SIGNAL ACQ_COUNT_R          : NATURAL := 0;
    SIGNAL DIV_COUNT_R          : NATURAL RANGE 0 TO G_SPI_DIV_HALF - 1 := 0;
    SIGNAL BIT_COUNT_R          : NATURAL RANGE 0 TO 16 := 0;

    SIGNAL ADC_CS_R             : STD_LOGIC := '1';
    SIGNAL ADC_SCLK_R           : STD_LOGIC := '0';
    SIGNAL ADC_A_R              : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');

    SIGNAL SHIFT_A_R            : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL SHIFT_B_R            : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL SAMPLE_A_R           : STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => '0');
    SIGNAL SAMPLE_B_R           : STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => '0');

    SIGNAL PACKET_R             : T_PACKET_ARRAY := (OTHERS => (OTHERS => '0'));
    SIGNAL SEND_INDEX_R         : NATURAL RANGE 0 TO 5 := 0;

    SIGNAL M_TVALID_R           : STD_LOGIC := '0';
    SIGNAL M_TDATA_R            : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL M_TLAST_R            : STD_LOGIC := '0';

    SIGNAL SAMPLE_PULSE_R       : STD_LOGIC := '0';

    FUNCTION MASK_BIT_FOR_PAIR(PAIR : NATURAL) RETURN NATURAL IS
    BEGIN
        RETURN 7 - PAIR;
    END FUNCTION;

    FUNCTION CHANNEL_A_FOR_PAIR(PAIR : NATURAL) RETURN STD_LOGIC_VECTOR IS
    BEGIN
        RETURN STD_LOGIC_VECTOR(TO_UNSIGNED(PAIR + 1, 8));
    END FUNCTION;

    FUNCTION CHANNEL_B_FOR_PAIR(PAIR : NATURAL) RETURN STD_LOGIC_VECTOR IS
    BEGIN
        RETURN STD_LOGIC_VECTOR(TO_UNSIGNED(PAIR + 7, 8));
    END FUNCTION;

    FUNCTION NEXT_ENABLED_PAIR(
        MASK_IN     : STD_LOGIC_VECTOR(7 DOWNTO 0);
        START_PAIR  : NATURAL
    ) RETURN NATURAL IS
        VARIABLE IDX_V : NATURAL RANGE 0 TO 5;
    BEGIN
        FOR OFFSET IN 0 TO 5 LOOP
            IDX_V := (START_PAIR + OFFSET) MOD 6;
            IF MASK_IN(MASK_BIT_FOR_PAIR(IDX_V)) = '1' THEN
                RETURN IDX_V;
            END IF;
        END LOOP;

        RETURN START_PAIR;
    END FUNCTION;

    FUNCTION ANY_ENABLED(MASK_IN : STD_LOGIC_VECTOR(7 DOWNTO 0)) RETURN BOOLEAN IS
    BEGIN
        RETURN (MASK_IN(7 DOWNTO 2) /= "000000");
    END FUNCTION;

BEGIN

    S_CMD_TREADY_O       <= '1';

    M_AXIS_TDATA_O       <= M_TDATA_R;
    M_AXIS_TVALID_O      <= M_TVALID_R;
    M_AXIS_TLAST_O       <= M_TLAST_R;

    ADC_CS_O             <= ADC_CS_R;
    ADC_SCLK_O           <= ADC_SCLK_R;
    ADC_A_O              <= ADC_A_R;

    ACTIVE_MASK_O        <= MASK_R;
    BUSY_O               <= '0' WHEN STATE_R = ST_IDLE ELSE '1';
    SAMPLE_VALID_PULSE_O <= SAMPLE_PULSE_R;

    PROCESS (CLK_I)
        VARIABLE NEXT_PAIR_V : NATURAL RANGE 0 TO 5;
    BEGIN
        IF RISING_EDGE(CLK_I) THEN
            IF RST_I = '1' THEN
                STATE_R          <= ST_IDLE;
                MASK_R           <= (OTHERS => '0');
                CMD_FIRST_BYTE_R <= '1';
                PAIR_IDX_R       <= 0;
                CURRENT_PAIR_R   <= 0;
                ACQ_COUNT_R      <= 0;
                DIV_COUNT_R      <= 0;
                BIT_COUNT_R      <= 0;
                ADC_CS_R         <= '1';
                ADC_SCLK_R       <= '0';
                ADC_A_R          <= (OTHERS => '0');
                SHIFT_A_R        <= (OTHERS => '0');
                SHIFT_B_R        <= (OTHERS => '0');
                SAMPLE_A_R       <= (OTHERS => '0');
                SAMPLE_B_R       <= (OTHERS => '0');
                PACKET_R         <= (OTHERS => (OTHERS => '0'));
                SEND_INDEX_R     <= 0;
                M_TVALID_R       <= '0';
                M_TDATA_R        <= (OTHERS => '0');
                M_TLAST_R        <= '0';
                SAMPLE_PULSE_R   <= '0';
            ELSE
                SAMPLE_PULSE_R <= '0';

                IF S_CMD_TVALID_I = '1' THEN
                    IF CMD_FIRST_BYTE_R = '1' THEN
                        MASK_R <= S_CMD_TDATA_I AND X"FC";
                    END IF;

                    IF S_CMD_TLAST_I = '1' THEN
                        CMD_FIRST_BYTE_R <= '1';
                    ELSE
                        CMD_FIRST_BYTE_R <= '0';
                    END IF;
                END IF;

                CASE STATE_R IS
                    WHEN ST_IDLE =>
                        ADC_CS_R    <= '1';
                        ADC_SCLK_R  <= '0';
                        M_TVALID_R  <= '0';
                        M_TLAST_R   <= '0';
                        DIV_COUNT_R <= 0;
                        BIT_COUNT_R <= 0;

                        IF ANY_ENABLED(MASK_R) THEN
                            NEXT_PAIR_V    := NEXT_ENABLED_PAIR(MASK_R, PAIR_IDX_R);
                            CURRENT_PAIR_R <= NEXT_PAIR_V;
                            ADC_A_R        <= STD_LOGIC_VECTOR(TO_UNSIGNED(NEXT_PAIR_V, 3));
                            ACQ_COUNT_R    <= 0;
                            STATE_R        <= ST_ACQUIRE;
                        END IF;

                    WHEN ST_ACQUIRE =>
                        ADC_CS_R   <= '1';
                        ADC_SCLK_R <= '0';

                        IF ACQ_COUNT_R >= G_ACQ_CYCLES THEN
                            ADC_CS_R    <= '0';
                            DIV_COUNT_R <= 0;
                            BIT_COUNT_R <= 0;
                            SHIFT_A_R   <= (OTHERS => '0');
                            SHIFT_B_R   <= (OTHERS => '0');
                            STATE_R     <= ST_SCLK_LOW;
                        ELSE
                            ACQ_COUNT_R <= ACQ_COUNT_R + 1;
                        END IF;

                    WHEN ST_SCLK_LOW =>
                        ADC_SCLK_R <= '0';

                        IF DIV_COUNT_R = G_SPI_DIV_HALF - 1 THEN
                            DIV_COUNT_R <= 0;
                            ADC_SCLK_R  <= '1';
                            SHIFT_A_R   <= SHIFT_A_R(14 DOWNTO 0) & ADC_DOUTA_I;
                            SHIFT_B_R   <= SHIFT_B_R(14 DOWNTO 0) & ADC_DOUTB_I;
                            STATE_R     <= ST_SCLK_HIGH;
                        ELSE
                            DIV_COUNT_R <= DIV_COUNT_R + 1;
                        END IF;

                    WHEN ST_SCLK_HIGH =>
                        ADC_SCLK_R <= '1';

                        IF DIV_COUNT_R = G_SPI_DIV_HALF - 1 THEN
                            DIV_COUNT_R <= 0;
                            ADC_SCLK_R  <= '0';

                            IF BIT_COUNT_R = 15 THEN
                                ADC_CS_R       <= '1';
                                SAMPLE_A_R     <= SHIFT_A_R(13 DOWNTO 2);
                                SAMPLE_B_R     <= SHIFT_B_R(13 DOWNTO 2);
                                SAMPLE_PULSE_R <= '1';
                                STATE_R        <= ST_PACKET_PREP;
                            ELSE
                                BIT_COUNT_R <= BIT_COUNT_R + 1;
                                STATE_R     <= ST_SCLK_LOW;
                            END IF;
                        ELSE
                            DIV_COUNT_R <= DIV_COUNT_R + 1;
                        END IF;

                    WHEN ST_PACKET_PREP =>
                        PACKET_R(0)  <= CHANNEL_A_FOR_PAIR(CURRENT_PAIR_R);
                        PACKET_R(1)  <= "0000" & SAMPLE_A_R(11 DOWNTO 8);
                        PACKET_R(2)  <= SAMPLE_A_R(7 DOWNTO 0);
                        PACKET_R(3)  <= CHANNEL_B_FOR_PAIR(CURRENT_PAIR_R);
                        PACKET_R(4)  <= "0000" & SAMPLE_B_R(11 DOWNTO 8);
                        PACKET_R(5)  <= SAMPLE_B_R(7 DOWNTO 0);

                        SEND_INDEX_R <= 0;
                        M_TDATA_R    <= CHANNEL_A_FOR_PAIR(CURRENT_PAIR_R);
                        M_TVALID_R   <= '1';
                        M_TLAST_R    <= '0';
                        STATE_R      <= ST_SEND;

                    WHEN ST_SEND =>
                        IF M_TVALID_R = '1' AND M_AXIS_TREADY_I = '1' THEN
                            IF SEND_INDEX_R = 5 THEN
                                M_TVALID_R <= '0';
                                M_TLAST_R  <= '0';
                                PAIR_IDX_R <= (CURRENT_PAIR_R + 1) MOD 6;
                                STATE_R    <= ST_IDLE;
                            ELSE
                                SEND_INDEX_R <= SEND_INDEX_R + 1;
                                M_TDATA_R    <= PACKET_R(SEND_INDEX_R + 1);
                                IF SEND_INDEX_R = 4 THEN
                                    M_TLAST_R <= '1';
                                ELSE
                                    M_TLAST_R <= '0';
                                END IF;
                            END IF;
                        END IF;

                    WHEN OTHERS =>
                        STATE_R <= ST_IDLE;
                END CASE;
            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE RTL;
