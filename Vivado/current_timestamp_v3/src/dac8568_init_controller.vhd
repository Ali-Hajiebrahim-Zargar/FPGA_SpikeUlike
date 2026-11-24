-- SPDX-License-Identifier: MIT
--
-- DAC8568A initialization controller
--
-- Intended hardware configuration:
--   * DAC8568A
--   * AVDD = 3.3 V
--   * External reference = 1.8 V
--   * Internal reference must remain disabled
--   * All eight channels power up and are initialized to zero code
--
-- Initialization sequence:
--   1) Wait G_POWERUP_DELAY_US after RESETN_I is released.
--   2) Software reset                    : 0x07000000
--   3) Disable internal reference        : 0x08000000
--   4) Power up all eight DAC channels   : 0x040000FF
--   5) Configure CLR code as zero scale  : 0x05000000
--   6) Write zero to all channels/update : 0x03F00000
--
-- The module interfaces directly with dac8568_spi_master through a simple
-- START/FRAME/BUSY/DONE handshake.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dac8568_init_controller is
    generic (
        G_CLK_FREQ_HZ       : positive := 100_000_000;
        G_POWERUP_DELAY_US  : positive := 100
    );
    port (
        CLK_I         : in  std_logic;
        RESETN_I      : in  std_logic;

        -- Interface to dac8568_spi_master
        SPI_BUSY_I    : in  std_logic;
        SPI_DONE_I    : in  std_logic;
        SPI_START_O   : out std_logic;
        SPI_FRAME_O   : out std_logic_vector(31 downto 0);

        -- Initialization status
        INIT_BUSY_O   : out std_logic;
        INIT_DONE_O   : out std_logic;
        INIT_ERROR_O  : out std_logic;

        -- Safe inactive levels during initialization
        DAC_LDAC_N_O  : out std_logic;
        DAC_CLR_N_O   : out std_logic
    );
end entity dac8568_init_controller;

architecture rtl of dac8568_init_controller is

    function max_nat(a : natural; b : natural) return natural is
    begin
        if a > b then
            return a;
        else
            return b;
        end if;
    end function;

    constant C_POWERUP_DELAY_CYCLES : natural :=
        max_nat(1, (G_CLK_FREQ_HZ / 1_000_000) * G_POWERUP_DELAY_US);

    constant C_FRAME_SOFTWARE_RESET       : std_logic_vector(31 downto 0) := x"07000000";
    constant C_FRAME_DISABLE_INT_REF      : std_logic_vector(31 downto 0) := x"08000000";
    constant C_FRAME_POWER_UP_ALL         : std_logic_vector(31 downto 0) := x"040000FF";
    constant C_FRAME_CLEAR_CODE_ZERO      : std_logic_vector(31 downto 0) := x"05000000";
    constant C_FRAME_ZERO_ALL_AND_UPDATE  : std_logic_vector(31 downto 0) := x"03F00000";

    type t_state is (
        ST_POWERUP_WAIT,
        ST_REQUEST_FRAME,
        ST_WAIT_FRAME_DONE,
        ST_COMPLETE,
        ST_ERROR
    );

    signal state_r          : t_state := ST_POWERUP_WAIT;
    signal delay_count_r    : natural range 0 to C_POWERUP_DELAY_CYCLES - 1 := 0;
    signal command_index_r  : integer range 0 to 4 := 0;

    signal spi_start_r      : std_logic := '0';
    signal spi_frame_r      : std_logic_vector(31 downto 0) := (others => '0');
    signal init_busy_r      : std_logic := '1';
    signal init_done_r      : std_logic := '0';
    signal init_error_r     : std_logic := '0';

    function command_frame(index_value : integer) return std_logic_vector is
    begin
        case index_value is
            when 0 => return C_FRAME_SOFTWARE_RESET;
            when 1 => return C_FRAME_DISABLE_INT_REF;
            when 2 => return C_FRAME_POWER_UP_ALL;
            when 3 => return C_FRAME_CLEAR_CODE_ZERO;
            when 4 => return C_FRAME_ZERO_ALL_AND_UPDATE;
            when others => return (31 downto 0 => '0');
        end case;
    end function;

begin

    assert (G_CLK_FREQ_HZ mod 1_000_000) = 0
        report "dac8568_init_controller: G_CLK_FREQ_HZ must be an integer multiple of 1 MHz"
        severity failure;

    SPI_START_O  <= spi_start_r;
    SPI_FRAME_O  <= spi_frame_r;
    INIT_BUSY_O  <= init_busy_r;
    INIT_DONE_O  <= init_done_r;
    INIT_ERROR_O <= init_error_r;

    -- Keep the active-low asynchronous pins inactive during initialization.
    -- Later, the top-level waveform driver may combine these signals with its
    -- own LDAC pulse generator and stop/clear control logic.
    DAC_LDAC_N_O <= '1';
    DAC_CLR_N_O  <= '1';

    process (CLK_I)
    begin
        if rising_edge(CLK_I) then
            spi_start_r <= '0';

            if RESETN_I = '0' then
                state_r         <= ST_POWERUP_WAIT;
                delay_count_r   <= 0;
                command_index_r <= 0;
                spi_frame_r     <= (others => '0');
                init_busy_r     <= '1';
                init_done_r     <= '0';
                init_error_r    <= '0';

            else
                case state_r is

                    when ST_POWERUP_WAIT =>
                        init_busy_r <= '1';
                        init_done_r <= '0';

                        if delay_count_r = C_POWERUP_DELAY_CYCLES - 1 then
                            delay_count_r   <= 0;
                            command_index_r <= 0;
                            state_r         <= ST_REQUEST_FRAME;
                        else
                            delay_count_r <= delay_count_r + 1;
                        end if;

                    when ST_REQUEST_FRAME =>
                        init_busy_r <= '1';

                        if SPI_BUSY_I = '0' then
                            spi_frame_r <= command_frame(command_index_r);
                            spi_start_r <= '1';
                            state_r     <= ST_WAIT_FRAME_DONE;
                        end if;

                    when ST_WAIT_FRAME_DONE =>
                        init_busy_r <= '1';

                        if SPI_DONE_I = '1' then
                            if command_index_r = 4 then
                                state_r <= ST_COMPLETE;
                            else
                                command_index_r <= command_index_r + 1;
                                state_r         <= ST_REQUEST_FRAME;
                            end if;
                        end if;

                    when ST_COMPLETE =>
                        init_busy_r  <= '0';
                        init_done_r  <= '1';
                        init_error_r <= '0';

                    when ST_ERROR =>
                        init_busy_r  <= '0';
                        init_done_r  <= '0';
                        init_error_r <= '1';

                end case;
            end if;
        end if;
    end process;

end architecture rtl;
