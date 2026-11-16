LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY FPGA_TIMESTAMP_TIMER_16 IS
    GENERIC (
        -- NUMBER OF CLK_I CYCLES PER TIMESTAMP INCREMENT.
        -- EXAMPLE: 100 FOR 1 US TICK WITH 100 MHZ CLOCK.
        G_TICK_DIVIDER : POSITIVE := 100
    );
    PORT (
        CLK_I        : IN  STD_LOGIC;
        RST_I        : IN  STD_LOGIC;
        ENABLE_I     : IN  STD_LOGIC;
        TIME_O       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        TICK_PULSE_O : OUT STD_LOGIC
    );
END ENTITY FPGA_TIMESTAMP_TIMER_16;

ARCHITECTURE RTL OF FPGA_TIMESTAMP_TIMER_16 IS

    SIGNAL R_DIV_COUNTER : INTEGER RANGE 0 TO G_TICK_DIVIDER - 1 := 0;
    SIGNAL R_TIME        : UNSIGNED(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL R_TICK_PULSE  : STD_LOGIC := '0';

BEGIN

    TIME_O       <= STD_LOGIC_VECTOR(R_TIME);
    TICK_PULSE_O <= R_TICK_PULSE;

    P_TIMER : PROCESS (CLK_I)
    BEGIN
        IF RISING_EDGE(CLK_I) THEN
            R_TICK_PULSE <= '0';

            IF RST_I = '1' THEN
                R_DIV_COUNTER <= 0;
                R_TIME        <= (OTHERS => '0');
                R_TICK_PULSE  <= '0';
            ELSE
                IF ENABLE_I = '1' THEN
                    IF R_DIV_COUNTER = G_TICK_DIVIDER - 1 THEN
                        R_DIV_COUNTER <= 0;
                        R_TIME        <= R_TIME + 1;
                        R_TICK_PULSE  <= '1';
                    ELSE
                        R_DIV_COUNTER <= R_DIV_COUNTER + 1;
                    END IF;
                ELSE
                    R_DIV_COUNTER <= 0;
                END IF;
            END IF;
        END IF;
    END PROCESS P_TIMER;

END ARCHITECTURE RTL;
