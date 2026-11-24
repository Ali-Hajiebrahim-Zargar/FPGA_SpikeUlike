-- SPDX-License-Identifier: MIT
--
-- AXI-Stream payload parser for one physical DAC8568 waveform driver.
--
-- The upstream axis_cmd_packet_router removes the four-byte command header
-- (VERSION, PACK_SEQ, SOURCE_ID, DATA_LENGTH) and forwards only DATA bytes.
-- The AXI-Stream data width is 8 bits.
--
-- Payload formats
-- ===============
--
-- Load one channel (commands 0x00 through 0x07):
--
--   Byte 0      CHANNEL_COMMAND
--               0x00=A, 0x01=B, ... 0x07=H
--   Byte 1      FLAGS
--               bit 0: AUTO_START
--               bit 1: ARM_ONLY
--               bit 2: RESET_PHASE
--               bits 7..3: reserved
--   Byte 2..5   SAMPLE_PERIOD_TICKS, big-endian, based on ACLK
--   Byte 6..    16-bit waveform samples, big-endian
--
-- The waveform length is inferred from TLAST. At least one sample and at
-- most 125 samples are accepted. Each channel has 128 reserved memory words.
--
-- Stop one channel and drive zero (commands 0x08 through 0x0F):
--
--   Byte 0      0x08=A, 0x09=B, ... 0x0F=H, with TLAST asserted
--
-- Start armed channels simultaneously:
--
--   Byte 0      0x10
--   Byte 1      CHANNEL_MASK, bit 0=A through bit 7=H, with TLAST asserted
--
-- Stop selected channels and drive zero:
--
--   Byte 0      0x11
--   Byte 1      CHANNEL_MASK, bit 0=A through bit 7=H, with TLAST asserted
--
-- The waveform RAM is written as each complete 16-bit sample arrives.
-- LOAD_DONE_O is asserted only when the complete packet is valid. A higher
-- level controller should invalidate or stop a channel on LOAD_BEGIN_O and
-- mark it valid again only on LOAD_DONE_O.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axis_dac8568_packet_parser is
    generic (
        G_MAX_SAMPLES : positive := 125
    );
    port (
        ACLK           : in  std_logic;
        ARESETN        : in  std_logic;

        -- 8-bit AXI4-Stream payload input from axis_cmd_packet_router
        S_AXIS_TDATA   : in  std_logic_vector(7 downto 0);
        S_AXIS_TKEEP   : in  std_logic_vector(0 downto 0);
        S_AXIS_TVALID  : in  std_logic;
        S_AXIS_TREADY  : out std_logic;
        S_AXIS_TLAST   : in  std_logic;

        -- Waveform-memory write port
        WR_EN_O        : out std_logic;
        WR_CHANNEL_O   : out std_logic_vector(2 downto 0);
        WR_ADDR_O      : out std_logic_vector(6 downto 0);
        WR_DATA_O      : out std_logic_vector(15 downto 0);

        -- Valid waveform-load events and descriptor values
        LOAD_BEGIN_O   : out std_logic;
        LOAD_DONE_O    : out std_logic;
        LOAD_CHANNEL_O : out std_logic_vector(2 downto 0);
        LOAD_FLAGS_O   : out std_logic_vector(7 downto 0);
        LOAD_SAMPLE_COUNT_O : out std_logic_vector(7 downto 0);
        LOAD_SAMPLE_PERIOD_TICKS_O : out std_logic_vector(31 downto 0);

        -- Short control-command events
        STOP_CHANNEL_VALID_O : out std_logic;
        STOP_CHANNEL_O       : out std_logic_vector(2 downto 0);

        START_MASK_VALID_O   : out std_logic;
        START_MASK_O         : out std_logic_vector(7 downto 0);

        STOP_MASK_VALID_O    : out std_logic;
        STOP_MASK_O          : out std_logic_vector(7 downto 0);

        -- One-cycle error indication
        PACKET_ERROR_O : out std_logic;
        ERROR_CODE_O   : out std_logic_vector(7 downto 0)
    );
end entity axis_dac8568_packet_parser;

architecture rtl of axis_dac8568_packet_parser is

    -- Error codes
    constant C_ERR_INVALID_COMMAND : std_logic_vector(7 downto 0) := x"01";
    constant C_ERR_BAD_LENGTH      : std_logic_vector(7 downto 0) := x"02";
    constant C_ERR_INVALID_TKEEP   : std_logic_vector(7 downto 0) := x"03";
    constant C_ERR_ZERO_PERIOD     : std_logic_vector(7 downto 0) := x"04";
    constant C_ERR_ODD_SAMPLE_BYTE : std_logic_vector(7 downto 0) := x"05";
    constant C_ERR_TOO_MANY_SAMPLES: std_logic_vector(7 downto 0) := x"06";
    constant C_ERR_INVALID_FLAGS   : std_logic_vector(7 downto 0) := x"07";

    type t_state is (
        ST_COMMAND,
        ST_LOAD_FLAGS,
        ST_LOAD_PERIOD_B3,
        ST_LOAD_PERIOD_B2,
        ST_LOAD_PERIOD_B1,
        ST_LOAD_PERIOD_B0,
        ST_LOAD_SAMPLE_HIGH,
        ST_LOAD_SAMPLE_LOW,
        ST_START_MASK,
        ST_STOP_MASK,
        ST_DROP
    );

    signal state_r : t_state := ST_COMMAND;

    signal load_channel_r : std_logic_vector(2 downto 0) := (others => '0');
    signal load_flags_r   : std_logic_vector(7 downto 0) := (others => '0');
    signal sample_period_r: std_logic_vector(31 downto 0) := (others => '0');
    signal sample_high_r  : std_logic_vector(7 downto 0) := (others => '0');
    signal sample_count_r : natural range 0 to G_MAX_SAMPLES := 0;

    signal wr_en_r      : std_logic := '0';
    signal wr_channel_r : std_logic_vector(2 downto 0) := (others => '0');
    signal wr_addr_r    : std_logic_vector(6 downto 0) := (others => '0');
    signal wr_data_r    : std_logic_vector(15 downto 0) := (others => '0');

    signal load_begin_r : std_logic := '0';
    signal load_done_r  : std_logic := '0';
    signal load_sample_count_r : std_logic_vector(7 downto 0) := (others => '0');

    signal stop_channel_valid_r : std_logic := '0';
    signal stop_channel_r       : std_logic_vector(2 downto 0) := (others => '0');
    signal start_mask_valid_r   : std_logic := '0';
    signal start_mask_r         : std_logic_vector(7 downto 0) := (others => '0');
    signal stop_mask_valid_r    : std_logic := '0';
    signal stop_mask_r          : std_logic_vector(7 downto 0) := (others => '0');

    signal packet_error_r : std_logic := '0';
    signal error_code_r   : std_logic_vector(7 downto 0) := (others => '0');

    attribute X_INTERFACE_INFO : string;
    attribute X_INTERFACE_PARAMETER : string;

    attribute X_INTERFACE_INFO of ACLK : signal is
        "xilinx.com:signal:clock:1.0 ACLK CLK";
    attribute X_INTERFACE_PARAMETER of ACLK : signal is
        "ASSOCIATED_BUSIF S_AXIS, ASSOCIATED_RESET ARESETN";

    attribute X_INTERFACE_INFO of ARESETN : signal is
        "xilinx.com:signal:reset:1.0 ARESETN RST";
    attribute X_INTERFACE_PARAMETER of ARESETN : signal is
        "POLARITY ACTIVE_LOW";

    attribute X_INTERFACE_INFO of S_AXIS_TDATA : signal is
        "xilinx.com:interface:axis:1.0 S_AXIS TDATA";
    attribute X_INTERFACE_INFO of S_AXIS_TKEEP : signal is
        "xilinx.com:interface:axis:1.0 S_AXIS TKEEP";
    attribute X_INTERFACE_INFO of S_AXIS_TVALID : signal is
        "xilinx.com:interface:axis:1.0 S_AXIS TVALID";
    attribute X_INTERFACE_INFO of S_AXIS_TREADY : signal is
        "xilinx.com:interface:axis:1.0 S_AXIS TREADY";
    attribute X_INTERFACE_INFO of S_AXIS_TLAST : signal is
        "xilinx.com:interface:axis:1.0 S_AXIS TLAST";

begin

    assert G_MAX_SAMPLES <= 128
        report "axis_dac8568_packet_parser: G_MAX_SAMPLES must not exceed 128"
        severity failure;

    -- The parser has no internal operation that needs to stall the byte stream.
    S_AXIS_TREADY <= ARESETN;

    WR_EN_O      <= wr_en_r;
    WR_CHANNEL_O <= wr_channel_r;
    WR_ADDR_O    <= wr_addr_r;
    WR_DATA_O    <= wr_data_r;

    LOAD_BEGIN_O   <= load_begin_r;
    LOAD_DONE_O    <= load_done_r;
    LOAD_CHANNEL_O <= load_channel_r;
    LOAD_FLAGS_O   <= load_flags_r;
    LOAD_SAMPLE_COUNT_O <= load_sample_count_r;
    LOAD_SAMPLE_PERIOD_TICKS_O <= sample_period_r;

    STOP_CHANNEL_VALID_O <= stop_channel_valid_r;
    STOP_CHANNEL_O       <= stop_channel_r;
    START_MASK_VALID_O   <= start_mask_valid_r;
    START_MASK_O         <= start_mask_r;
    STOP_MASK_VALID_O    <= stop_mask_valid_r;
    STOP_MASK_O          <= stop_mask_r;

    PACKET_ERROR_O <= packet_error_r;
    ERROR_CODE_O   <= error_code_r;

    process (ACLK)
        variable command_value_v : integer range 0 to 255;
        variable final_count_v   : natural range 1 to G_MAX_SAMPLES;
    begin
        if rising_edge(ACLK) then
            -- Default all event outputs to one-clock pulses.
            wr_en_r                <= '0';
            load_begin_r           <= '0';
            load_done_r            <= '0';
            stop_channel_valid_r   <= '0';
            start_mask_valid_r     <= '0';
            stop_mask_valid_r      <= '0';
            packet_error_r         <= '0';

            if ARESETN = '0' then
                state_r              <= ST_COMMAND;
                load_channel_r       <= (others => '0');
                load_flags_r         <= (others => '0');
                sample_period_r      <= (others => '0');
                sample_high_r        <= (others => '0');
                sample_count_r       <= 0;
                wr_channel_r         <= (others => '0');
                wr_addr_r            <= (others => '0');
                wr_data_r            <= (others => '0');
                load_sample_count_r  <= (others => '0');
                stop_channel_r       <= (others => '0');
                start_mask_r         <= (others => '0');
                stop_mask_r          <= (others => '0');
                error_code_r         <= (others => '0');

            elsif S_AXIS_TVALID = '1' and S_AXIS_TREADY = '1' then

                if S_AXIS_TKEEP(0) = '0' then
                    packet_error_r <= '1';
                    error_code_r   <= C_ERR_INVALID_TKEEP;

                    if S_AXIS_TLAST = '1' then
                        state_r <= ST_COMMAND;
                    else
                        state_r <= ST_DROP;
                    end if;

                else
                    case state_r is

                        when ST_COMMAND =>
                            command_value_v := to_integer(unsigned(S_AXIS_TDATA));

                            if command_value_v <= 7 then
                                load_channel_r      <= S_AXIS_TDATA(2 downto 0);
                                wr_channel_r        <= S_AXIS_TDATA(2 downto 0);
                                load_flags_r        <= (others => '0');
                                sample_period_r     <= (others => '0');
                                sample_count_r      <= 0;
                                load_sample_count_r <= (others => '0');
                                load_begin_r        <= '1';

                                if S_AXIS_TLAST = '1' then
                                    packet_error_r <= '1';
                                    error_code_r   <= C_ERR_BAD_LENGTH;
                                    state_r        <= ST_COMMAND;
                                else
                                    state_r <= ST_LOAD_FLAGS;
                                end if;

                            elsif command_value_v >= 8 and command_value_v <= 15 then
                                stop_channel_r <= std_logic_vector(
                                    to_unsigned(command_value_v - 8, 3));

                                if S_AXIS_TLAST = '1' then
                                    stop_channel_valid_r <= '1';
                                    state_r              <= ST_COMMAND;
                                else
                                    packet_error_r <= '1';
                                    error_code_r   <= C_ERR_BAD_LENGTH;
                                    state_r        <= ST_DROP;
                                end if;

                            elsif S_AXIS_TDATA = x"10" then
                                if S_AXIS_TLAST = '1' then
                                    packet_error_r <= '1';
                                    error_code_r   <= C_ERR_BAD_LENGTH;
                                    state_r        <= ST_COMMAND;
                                else
                                    state_r <= ST_START_MASK;
                                end if;

                            elsif S_AXIS_TDATA = x"11" then
                                if S_AXIS_TLAST = '1' then
                                    packet_error_r <= '1';
                                    error_code_r   <= C_ERR_BAD_LENGTH;
                                    state_r        <= ST_COMMAND;
                                else
                                    state_r <= ST_STOP_MASK;
                                end if;

                            else
                                packet_error_r <= '1';
                                error_code_r   <= C_ERR_INVALID_COMMAND;

                                if S_AXIS_TLAST = '1' then
                                    state_r <= ST_COMMAND;
                                else
                                    state_r <= ST_DROP;
                                end if;
                            end if;

                        when ST_LOAD_FLAGS =>
                            load_flags_r <= S_AXIS_TDATA;

                            if S_AXIS_TLAST = '1' then
                                packet_error_r <= '1';
                                error_code_r   <= C_ERR_BAD_LENGTH;
                                state_r        <= ST_COMMAND;
                            else
                                state_r <= ST_LOAD_PERIOD_B3;
                            end if;

                        when ST_LOAD_PERIOD_B3 =>
                            sample_period_r(31 downto 24) <= S_AXIS_TDATA;

                            if S_AXIS_TLAST = '1' then
                                packet_error_r <= '1';
                                error_code_r   <= C_ERR_BAD_LENGTH;
                                state_r        <= ST_COMMAND;
                            else
                                state_r <= ST_LOAD_PERIOD_B2;
                            end if;

                        when ST_LOAD_PERIOD_B2 =>
                            sample_period_r(23 downto 16) <= S_AXIS_TDATA;

                            if S_AXIS_TLAST = '1' then
                                packet_error_r <= '1';
                                error_code_r   <= C_ERR_BAD_LENGTH;
                                state_r        <= ST_COMMAND;
                            else
                                state_r <= ST_LOAD_PERIOD_B1;
                            end if;

                        when ST_LOAD_PERIOD_B1 =>
                            sample_period_r(15 downto 8) <= S_AXIS_TDATA;

                            if S_AXIS_TLAST = '1' then
                                packet_error_r <= '1';
                                error_code_r   <= C_ERR_BAD_LENGTH;
                                state_r        <= ST_COMMAND;
                            else
                                state_r <= ST_LOAD_PERIOD_B0;
                            end if;

                        when ST_LOAD_PERIOD_B0 =>
                            sample_period_r(7 downto 0) <= S_AXIS_TDATA;

                            if S_AXIS_TLAST = '1' then
                                packet_error_r <= '1';
                                error_code_r   <= C_ERR_BAD_LENGTH;
                                state_r        <= ST_COMMAND;
                            else
                                state_r <= ST_LOAD_SAMPLE_HIGH;
                            end if;

                        when ST_LOAD_SAMPLE_HIGH =>
                            if sample_count_r = G_MAX_SAMPLES then
                                packet_error_r <= '1';
                                error_code_r   <= C_ERR_TOO_MANY_SAMPLES;

                                if S_AXIS_TLAST = '1' then
                                    state_r <= ST_COMMAND;
                                else
                                    state_r <= ST_DROP;
                                end if;
                            else
                                sample_high_r <= S_AXIS_TDATA;

                                if S_AXIS_TLAST = '1' then
                                    packet_error_r <= '1';
                                    error_code_r   <= C_ERR_ODD_SAMPLE_BYTE;
                                    state_r        <= ST_COMMAND;
                                else
                                    state_r <= ST_LOAD_SAMPLE_LOW;
                                end if;
                            end if;

                        when ST_LOAD_SAMPLE_LOW =>
                            -- Complete one big-endian 16-bit sample and write it.
                            wr_en_r      <= '1';
                            wr_channel_r <= load_channel_r;
                            wr_addr_r    <= std_logic_vector(to_unsigned(sample_count_r, 7));
                            wr_data_r    <= sample_high_r & S_AXIS_TDATA;

                            final_count_v := sample_count_r + 1;
                            sample_count_r <= final_count_v;

                            if S_AXIS_TLAST = '1' then
                                if sample_period_r = x"00000000" then
                                    packet_error_r <= '1';
                                    error_code_r   <= C_ERR_ZERO_PERIOD;
                                elsif load_flags_r(1 downto 0) = "11" then
                                    packet_error_r <= '1';
                                    error_code_r   <= C_ERR_INVALID_FLAGS;
                                else
                                    load_sample_count_r <= std_logic_vector(
                                        to_unsigned(final_count_v, 8));
                                    load_done_r <= '1';
                                end if;

                                state_r <= ST_COMMAND;
                            else
                                state_r <= ST_LOAD_SAMPLE_HIGH;
                            end if;

                        when ST_START_MASK =>
                            start_mask_r <= S_AXIS_TDATA;

                            if S_AXIS_TLAST = '1' then
                                start_mask_valid_r <= '1';
                                state_r            <= ST_COMMAND;
                            else
                                packet_error_r <= '1';
                                error_code_r   <= C_ERR_BAD_LENGTH;
                                state_r        <= ST_DROP;
                            end if;

                        when ST_STOP_MASK =>
                            stop_mask_r <= S_AXIS_TDATA;

                            if S_AXIS_TLAST = '1' then
                                stop_mask_valid_r <= '1';
                                state_r           <= ST_COMMAND;
                            else
                                packet_error_r <= '1';
                                error_code_r   <= C_ERR_BAD_LENGTH;
                                state_r        <= ST_DROP;
                            end if;

                        when ST_DROP =>
                            if S_AXIS_TLAST = '1' then
                                state_r <= ST_COMMAND;
                            end if;

                    end case;
                end if;
            end if;
        end if;
    end process;

end architecture rtl;
