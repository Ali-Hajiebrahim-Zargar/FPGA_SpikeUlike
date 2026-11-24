LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY AD7266_SPI_SINE_MODEL IS
    GENERIC (
        G_PHASE_STEP              : POSITIVE := 1;
        G_PAIR_PHASE_OFFSET       : NATURAL  := 3;
        G_DOUTB_PHASE_OFFSET      : NATURAL  := 16
    );
    PORT (
        CLK_I                     : IN  STD_LOGIC;
        RST_I                     : IN  STD_LOGIC;

        ADC_CS_I                  : IN  STD_LOGIC;
        ADC_SCLK_I                : IN  STD_LOGIC;
        ADC_A_I                   : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);

        ADC_DOUTA_O               : OUT STD_LOGIC;
        ADC_DOUTB_O               : OUT STD_LOGIC;

        SAMPLE_A_DEBUG_O          : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
        SAMPLE_B_DEBUG_O          : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
        CONVERSION_PULSE_O        : OUT STD_LOGIC
    );
END ENTITY AD7266_SPI_SINE_MODEL;

ARCHITECTURE RTL OF AD7266_SPI_SINE_MODEL IS

    TYPE T_SINE_LUT IS ARRAY (0 TO 63) OF STD_LOGIC_VECTOR(11 DOWNTO 0);

    CONSTANT C_SINE_LUT : T_SINE_LUT := (
        0  => X"800", 1  => X"8B0", 2  => X"95F", 3  => X"A0B",
        4  => X"AB1", 5  => X"B51", 6  => X"BE8", 7  => X"C76",
        8  => X"CF9", 9  => X"D6F", 10 => X"DD9", 11 => X"E33",
        12 => X"E7F", 13 => X"EBA", 14 => X"EE5", 15 => X"EFF",
        16 => X"F08", 17 => X"EFF", 18 => X"EE5", 19 => X"EBA",
        20 => X"E7F", 21 => X"E33", 22 => X"DD9", 23 => X"D6F",
        24 => X"CF9", 25 => X"C76", 26 => X"BE8", 27 => X"B51",
        28 => X"AB1", 29 => X"A0B", 30 => X"95F", 31 => X"8B0",
        32 => X"800", 33 => X"750", 34 => X"6A1", 35 => X"5F5",
        36 => X"54F", 37 => X"4AF", 38 => X"418", 39 => X"38A",
        40 => X"307", 41 => X"291", 42 => X"227", 43 => X"1CD",
        44 => X"181", 45 => X"146", 46 => X"11B", 47 => X"101",
        48 => X"0F8", 49 => X"101", 50 => X"11B", 51 => X"146",
        52 => X"181", 53 => X"1CD", 54 => X"227", 55 => X"291",
        56 => X"307", 57 => X"38A", 58 => X"418", 59 => X"4AF",
        60 => X"54F", 61 => X"5F5", 62 => X"6A1", 63 => X"750"
    );

    SIGNAL CS_D_R                 : STD_LOGIC := '1';
    SIGNAL SCLK_D_R               : STD_LOGIC := '0';

    SIGNAL PHASE_R                : NATURAL RANGE 0 TO 63 := 0;
    SIGNAL BIT_INDEX_R            : NATURAL RANGE 0 TO 15 := 0;

    SIGNAL SHIFT_A_R              : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL SHIFT_B_R              : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');

    SIGNAL DOUTA_R                : STD_LOGIC := '0';
    SIGNAL DOUTB_R                : STD_LOGIC := '0';

    SIGNAL SAMPLE_A_R             : STD_LOGIC_VECTOR(11 DOWNTO 0) := X"800";
    SIGNAL SAMPLE_B_R             : STD_LOGIC_VECTOR(11 DOWNTO 0) := X"800";
    SIGNAL CONVERSION_PULSE_R     : STD_LOGIC := '0';

    FUNCTION WRAP64(VALUE_IN : NATURAL) RETURN NATURAL IS
    BEGIN
        RETURN VALUE_IN MOD 64;
    END FUNCTION;

BEGIN

    ADC_DOUTA_O        <= DOUTA_R;
    ADC_DOUTB_O        <= DOUTB_R;
    SAMPLE_A_DEBUG_O   <= SAMPLE_A_R;
    SAMPLE_B_DEBUG_O   <= SAMPLE_B_R;
    CONVERSION_PULSE_O <= CONVERSION_PULSE_R;

    P_SPI_MODEL : PROCESS (CLK_I)
        VARIABLE V_PAIR_INDEX : NATURAL RANGE 0 TO 7;
        VARIABLE V_A_INDEX    : NATURAL RANGE 0 TO 63;
        VARIABLE V_B_INDEX    : NATURAL RANGE 0 TO 63;
        VARIABLE V_SAMPLE_A   : STD_LOGIC_VECTOR(11 DOWNTO 0);
        VARIABLE V_SAMPLE_B   : STD_LOGIC_VECTOR(11 DOWNTO 0);
        VARIABLE V_NEXT_BIT   : NATURAL RANGE 0 TO 15;
    BEGIN
        IF RISING_EDGE(CLK_I) THEN
            IF RST_I = '1' THEN
                CS_D_R             <= '1';
                SCLK_D_R           <= '0';
                PHASE_R            <= 0;
                BIT_INDEX_R        <= 0;
                SHIFT_A_R          <= (OTHERS => '0');
                SHIFT_B_R          <= (OTHERS => '0');
                DOUTA_R            <= '0';
                DOUTB_R            <= '0';
                SAMPLE_A_R         <= X"800";
                SAMPLE_B_R         <= X"800";
                CONVERSION_PULSE_R <= '0';
            ELSE
                CONVERSION_PULSE_R <= '0';

                CS_D_R   <= ADC_CS_I;
                SCLK_D_R <= ADC_SCLK_I;

                IF ADC_CS_I = '1' THEN
                    DOUTA_R     <= '0';
                    DOUTB_R     <= '0';
                    BIT_INDEX_R <= 0;

                    IF CS_D_R = '0' THEN
                        PHASE_R <= WRAP64(PHASE_R + G_PHASE_STEP);
                    END IF;
                ELSE
                    IF CS_D_R = '1' THEN
                        V_PAIR_INDEX := TO_INTEGER(UNSIGNED(ADC_A_I));
                        V_A_INDEX    := WRAP64(PHASE_R + (V_PAIR_INDEX * G_PAIR_PHASE_OFFSET));
                        V_B_INDEX    := WRAP64(PHASE_R + G_DOUTB_PHASE_OFFSET + (V_PAIR_INDEX * G_PAIR_PHASE_OFFSET));
                        V_SAMPLE_A   := C_SINE_LUT(V_A_INDEX);
                        V_SAMPLE_B   := C_SINE_LUT(V_B_INDEX);

                        SAMPLE_A_R         <= V_SAMPLE_A;
                        SAMPLE_B_R         <= V_SAMPLE_B;
                        SHIFT_A_R          <= "00" & V_SAMPLE_A & "00";
                        SHIFT_B_R          <= "00" & V_SAMPLE_B & "00";
                        BIT_INDEX_R        <= 0;
                        DOUTA_R            <= '0';
                        DOUTB_R            <= '0';
                        CONVERSION_PULSE_R <= '1';
                    ELSIF SCLK_D_R = '1' AND ADC_SCLK_I = '0' THEN
                        IF BIT_INDEX_R < 15 THEN
                            V_NEXT_BIT  := BIT_INDEX_R + 1;
                            BIT_INDEX_R <= V_NEXT_BIT;
                            DOUTA_R     <= SHIFT_A_R(15 - V_NEXT_BIT);
                            DOUTB_R     <= SHIFT_B_R(15 - V_NEXT_BIT);
                        ELSE
                            DOUTA_R <= '0';
                            DOUTB_R <= '0';
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS P_SPI_MODEL;

END ARCHITECTURE RTL;
