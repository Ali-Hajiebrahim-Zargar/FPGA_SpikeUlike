-- SPDX-License-Identifier: MIT
--
-- Waveform memory for one physical DAC8568.
--
-- Organization:
--   * 8 independent DAC channels: A through H
--   * 128 words reserved for each channel
--   * 16 bits per word
--   * Total capacity: 8 x 128 x 16 = 16384 bits
--
-- Address mapping:
--   memory_address = CHANNEL & SAMPLE_ADDRESS
--
--   CHANNEL = 000 -> DAC channel A
--   CHANNEL = 001 -> DAC channel B
--   ...
--   CHANNEL = 111 -> DAC channel H
--
-- The memory has one synchronous write port and one synchronous read port.
-- Read data and RD_VALID_O are produced one CLK_I cycle after RD_EN_I.
--
-- The RAM contents are intentionally not cleared by RESETN_I. Channel-valid
-- flags and waveform lengths are maintained by the higher-level packet parser
-- and controller. Avoiding a full-memory reset permits block-RAM inference.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dac8568_waveform_memory is
    port (
        CLK_I        : in  std_logic;
        RESETN_I     : in  std_logic;

        -- Synchronous write port
        WR_EN_I      : in  std_logic;
        WR_CHANNEL_I : in  std_logic_vector(2 downto 0);
        WR_ADDR_I    : in  std_logic_vector(6 downto 0);
        WR_DATA_I    : in  std_logic_vector(15 downto 0);

        -- Synchronous read port
        RD_EN_I      : in  std_logic;
        RD_CHANNEL_I : in  std_logic_vector(2 downto 0);
        RD_ADDR_I    : in  std_logic_vector(6 downto 0);
        RD_DATA_O    : out std_logic_vector(15 downto 0);
        RD_VALID_O   : out std_logic
    );
end entity dac8568_waveform_memory;

architecture rtl of dac8568_waveform_memory is

    constant C_TOTAL_WORDS : positive := 8 * 128;

    type t_waveform_ram is array (0 to C_TOTAL_WORDS - 1)
        of std_logic_vector(15 downto 0);

    signal waveform_ram : t_waveform_ram;

    attribute ram_style : string;
    attribute ram_style of waveform_ram : signal is "block";

    signal rd_data_r  : std_logic_vector(15 downto 0) := (others => '0');
    signal rd_valid_r : std_logic := '0';

begin

    RD_DATA_O  <= rd_data_r;
    RD_VALID_O <= rd_valid_r;

    -- Port A: waveform loading from the AXI-Stream packet parser.
    process (CLK_I)
        variable wr_index_v : integer range 0 to C_TOTAL_WORDS - 1;
    begin
        if rising_edge(CLK_I) then
            if WR_EN_I = '1' then
                wr_index_v := (to_integer(unsigned(WR_CHANNEL_I)) * 128) +
                              to_integer(unsigned(WR_ADDR_I));
                waveform_ram(wr_index_v) <= WR_DATA_I;
            end if;
        end if;
    end process;

    -- Port B: waveform playback reads. The read latency is one clock cycle.
    process (CLK_I)
        variable rd_index_v : integer range 0 to C_TOTAL_WORDS - 1;
    begin
        if rising_edge(CLK_I) then
            if RESETN_I = '0' then
                rd_data_r  <= (others => '0');
                rd_valid_r <= '0';
            else
                rd_valid_r <= RD_EN_I;

                if RD_EN_I = '1' then
                    rd_index_v := (to_integer(unsigned(RD_CHANNEL_I)) * 128) +
                              to_integer(unsigned(RD_ADDR_I));
                    rd_data_r <= waveform_ram(rd_index_v);
                end if;
            end if;
        end if;
    end process;

end architecture rtl;
