-- SPDX-License-Identifier: MIT
--
-- DAC8568 32-bit SPI transmitter
--
-- Timing model:
--   * SCLK idles HIGH.
--   * SYNC_N is asserted LOW before the first falling edge.
--   * DIN is transmitted MSB first (DB31 first).
--   * The DAC8568 samples DIN on each falling edge of SCLK.
--   * Exactly 32 falling edges are generated for every accepted START_I pulse.
--   * SYNC_N returns HIGH after the final falling edge and remains HIGH for
--     at least G_SYNC_HIGH_CYCLES clock cycles.
--
-- Default clocking:
--   CLK_I = 100 MHz
--   SCLK  = 25 MHz
--
-- This module only transmits a prepared 32-bit frame. Frame construction,
-- initialization commands, waveform memory, scheduling, LDAC and CLR control
-- are implemented in higher-level modules.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dac8568_spi_master is
    generic (
        G_CLK_FREQ_HZ        : positive := 100_000_000;
        G_SCLK_FREQ_HZ       : positive := 25_000_000;
        G_SYNC_HIGH_CYCLES   : positive := 8
    );
    port (
        CLK_I       : in  std_logic;
        RESETN_I    : in  std_logic;

        START_I     : in  std_logic;
        FRAME_I     : in  std_logic_vector(31 downto 0);

        BUSY_O      : out std_logic;
        DONE_O      : out std_logic;

        DAC_SYNC_N_O : out std_logic;
        DAC_SCLK_O   : out std_logic;
        DAC_DIN_O    : out std_logic
    );
end entity dac8568_spi_master;

architecture rtl of dac8568_spi_master is

    constant C_HALF_PERIOD_CYCLES : positive :=
        G_CLK_FREQ_HZ / (2 * G_SCLK_FREQ_HZ);

    type t_state is (
        ST_IDLE,
        ST_WAIT_FIRST_FALL,
        ST_WAIT_RISE,
        ST_WAIT_NEXT_FALL,
        ST_SYNC_HIGH_HOLD
    );

    signal state_r          : t_state := ST_IDLE;
    signal frame_r          : std_logic_vector(31 downto 0) := (others => '0');
    signal bit_index_r      : integer range 0 to 31 := 31;
    signal half_count_r     : natural range 0 to C_HALF_PERIOD_CYCLES - 1 := 0;
    signal sync_hold_count_r: natural range 0 to G_SYNC_HIGH_CYCLES - 1 := 0;

    signal busy_r           : std_logic := '0';
    signal done_r           : std_logic := '0';
    signal sync_n_r         : std_logic := '1';
    signal sclk_r           : std_logic := '1';
    signal din_r            : std_logic := '0';

begin

    -- The selected clock frequencies must produce an integer half-period.
    assert G_CLK_FREQ_HZ >= (2 * G_SCLK_FREQ_HZ)
        report "dac8568_spi_master: G_SCLK_FREQ_HZ is too high for CLK_I"
        severity failure;

    assert (G_CLK_FREQ_HZ mod (2 * G_SCLK_FREQ_HZ)) = 0
        report "dac8568_spi_master: CLK/SCLK ratio must provide an integer half-period"
        severity failure;

    BUSY_O       <= busy_r;
    DONE_O       <= done_r;
    DAC_SYNC_N_O <= sync_n_r;
    DAC_SCLK_O   <= sclk_r;
    DAC_DIN_O    <= din_r;

    process (CLK_I)
    begin
        if rising_edge(CLK_I) then
            done_r <= '0';

            if RESETN_I = '0' then
                state_r           <= ST_IDLE;
                frame_r           <= (others => '0');
                bit_index_r       <= 31;
                half_count_r      <= 0;
                sync_hold_count_r <= 0;
                busy_r            <= '0';
                done_r            <= '0';
                sync_n_r          <= '1';
                sclk_r            <= '1';
                din_r             <= '0';

            else
                case state_r is

                    when ST_IDLE =>
                        busy_r   <= '0';
                        sync_n_r <= '1';
                        sclk_r   <= '1';

                        if START_I = '1' then
                            frame_r      <= FRAME_I;
                            bit_index_r  <= 31;
                            din_r        <= FRAME_I(31);
                            sync_n_r     <= '0';
                            busy_r       <= '1';
                            half_count_r <= C_HALF_PERIOD_CYCLES - 1;
                            state_r      <= ST_WAIT_FIRST_FALL;
                        end if;

                    -- Keep SYNC_N low and DIN stable before the first
                    -- falling SCLK edge.
                    when ST_WAIT_FIRST_FALL =>
                        if half_count_r = 0 then
                            sclk_r       <= '0';
                            half_count_r <= C_HALF_PERIOD_CYCLES - 1;
                            state_r      <= ST_WAIT_RISE;
                        else
                            half_count_r <= half_count_r - 1;
                        end if;

                    -- The current bit has already been sampled by the DAC
                    -- on the preceding falling edge. Return SCLK high and
                    -- prepare the next bit while SCLK is high.
                    when ST_WAIT_RISE =>
                        if half_count_r = 0 then
                            sclk_r <= '1';

                            if bit_index_r = 0 then
                                -- The 32nd falling edge has completed.
                                -- Raising SYNC_N here gives one complete
                                -- low half-period after that falling edge.
                                sync_n_r          <= '1';
                                done_r            <= '1';
                                sync_hold_count_r <= G_SYNC_HIGH_CYCLES - 1;
                                state_r           <= ST_SYNC_HIGH_HOLD;
                            else
                                bit_index_r  <= bit_index_r - 1;
                                din_r        <= frame_r(bit_index_r - 1);
                                half_count_r <= C_HALF_PERIOD_CYCLES - 1;
                                state_r      <= ST_WAIT_NEXT_FALL;
                            end if;
                        else
                            half_count_r <= half_count_r - 1;
                        end if;

                    -- DIN remains stable during the high half-period.
                    when ST_WAIT_NEXT_FALL =>
                        if half_count_r = 0 then
                            sclk_r       <= '0';
                            half_count_r <= C_HALF_PERIOD_CYCLES - 1;
                            state_r      <= ST_WAIT_RISE;
                        else
                            half_count_r <= half_count_r - 1;
                        end if;

                    -- Enforce the minimum SYNC_N high interval between
                    -- consecutive 32-bit frames.
                    when ST_SYNC_HIGH_HOLD =>
                        busy_r   <= '1';
                        sync_n_r <= '1';
                        sclk_r   <= '1';

                        if sync_hold_count_r = 0 then
                            busy_r  <= '0';
                            state_r <= ST_IDLE;
                        else
                            sync_hold_count_r <= sync_hold_count_r - 1;
                        end if;

                end case;
            end if;
        end if;
    end process;

end architecture rtl;
