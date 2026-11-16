-- SPDX-License-Identifier: MIT
--
-- Eight-channel waveform scheduler for one physical DAC8568.
--
-- Responsibilities:
--   * Store one descriptor per DAC channel: valid flag, waveform length,
--     sample period, read pointer and run state.
--   * Accept load/start/stop events from axis_dac8568_packet_parser.
--   * Generate independent sample timing for channels A through H.
--   * Read 16-bit samples from dac8568_waveform_memory.
--   * Serialize all channel updates through one shared SPI master.
--   * Write channel input buffers with control code 0000 and pulse LDAC_N so
--     all channels due in one scheduler batch update simultaneously.
--   * Repeat every valid waveform continuously.
--   * Stop selected channels and synchronously drive them to code 0x0000.
--
-- Notes:
--   * SAMPLE_PERIOD_TICKS is measured in CLK_I cycles.
--   * A channel waveform must contain 1 to 125 samples.
--   * The waveform RAM read latency is one clock cycle.
--   * This module does not build the final 32-bit word. Connect its frame
--     fields to dac8568_frame_builder, then connect the resulting FRAME_O to
--     dac8568_spi_master.
--   * ENABLE_I should be asserted only after DAC initialization is complete.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dac8568_channel_scheduler is
    generic (
        G_LDAC_LOW_CYCLES : positive := 10
    );
    port (
        CLK_I       : in  std_logic;
        RESETN_I    : in  std_logic;
        ENABLE_I    : in  std_logic;

        -- Events and descriptors from axis_dac8568_packet_parser
        LOAD_BEGIN_I   : in  std_logic;
        LOAD_DONE_I    : in  std_logic;
        LOAD_CHANNEL_I : in  std_logic_vector(2 downto 0);
        LOAD_FLAGS_I   : in  std_logic_vector(7 downto 0);
        LOAD_SAMPLE_COUNT_I : in  std_logic_vector(7 downto 0);
        LOAD_SAMPLE_PERIOD_TICKS_I : in std_logic_vector(31 downto 0);

        STOP_CHANNEL_VALID_I : in std_logic;
        STOP_CHANNEL_I       : in std_logic_vector(2 downto 0);

        START_MASK_VALID_I : in std_logic;
        START_MASK_I       : in std_logic_vector(7 downto 0);

        STOP_MASK_VALID_I  : in std_logic;
        STOP_MASK_I        : in std_logic_vector(7 downto 0);

        -- Read port to dac8568_waveform_memory
        MEM_RD_EN_O      : out std_logic;
        MEM_RD_CHANNEL_O : out std_logic_vector(2 downto 0);
        MEM_RD_ADDR_O    : out std_logic_vector(6 downto 0);
        MEM_RD_DATA_I    : in  std_logic_vector(15 downto 0);
        MEM_RD_VALID_I   : in  std_logic;

        -- Handshake with the shared dac8568_spi_master
        SPI_BUSY_I   : in  std_logic;
        SPI_DONE_I   : in  std_logic;
        SPI_START_O  : out std_logic;

        -- Fields for dac8568_frame_builder
        FRAME_CONTROL_O : out std_logic_vector(3 downto 0);
        FRAME_ADDRESS_O : out std_logic_vector(3 downto 0);
        FRAME_DATA_O    : out std_logic_vector(15 downto 0);
        FRAME_FEATURE_O : out std_logic_vector(3 downto 0);

        -- Hardware simultaneous-update control
        DAC_LDAC_N_O : out std_logic;

        -- Status
        VALID_MASK_O  : out std_logic_vector(7 downto 0);
        ARMED_MASK_O  : out std_logic_vector(7 downto 0);
        ACTIVE_MASK_O : out std_logic_vector(7 downto 0);
        BUSY_O        : out std_logic;
        SCHEDULE_OVERRUN_O : out std_logic
    );
end entity dac8568_channel_scheduler;

architecture rtl of dac8568_channel_scheduler is

    type t_u7_array is array (0 to 7) of unsigned(6 downto 0);
    type t_u8_array is array (0 to 7) of unsigned(7 downto 0);
    type t_u32_array is array (0 to 7) of unsigned(31 downto 0);

    type t_batch_kind is (
        BATCH_ZERO,
        BATCH_START,
        BATCH_UPDATE
    );

    type t_state is (
        ST_IDLE,
        ST_SELECT_CHANNEL,
        ST_ISSUE_MEMORY_READ,
        ST_WAIT_MEMORY_READ,
        ST_FRAME_READY,
        ST_WAIT_SPI_DONE,
        ST_WAIT_SPI_IDLE,
        ST_LDAC_LOW
    );

    signal state_r      : t_state := ST_IDLE;
    signal batch_kind_r : t_batch_kind := BATCH_ZERO;

    signal valid_mask_r  : std_logic_vector(7 downto 0) := (others => '0');
    signal armed_mask_r  : std_logic_vector(7 downto 0) := (others => '0');
    signal active_mask_r : std_logic_vector(7 downto 0) := (others => '0');

    signal due_pending_r   : std_logic_vector(7 downto 0) := (others => '0');
    signal start_pending_r : std_logic_vector(7 downto 0) := (others => '0');
    signal zero_pending_r  : std_logic_vector(7 downto 0) := (others => '0');

    signal service_mask_r : std_logic_vector(7 downto 0) := (others => '0');
    signal batch_mask_r   : std_logic_vector(7 downto 0) := (others => '0');
    signal current_channel_r : integer range 0 to 7 := 0;

    signal waveform_length_r : t_u8_array := (others => (others => '0'));
    signal sample_period_r   : t_u32_array := (others => (others => '0'));
    signal sample_timer_r    : t_u32_array := (others => (others => '0'));
    signal read_pointer_r    : t_u7_array := (others => (others => '0'));

    signal mem_rd_en_r      : std_logic := '0';
    signal mem_rd_channel_r : std_logic_vector(2 downto 0) := (others => '0');
    signal mem_rd_addr_r    : std_logic_vector(6 downto 0) := (others => '0');

    signal spi_start_r : std_logic := '0';

    signal frame_control_r : std_logic_vector(3 downto 0) := (others => '0');
    signal frame_address_r : std_logic_vector(3 downto 0) := (others => '0');
    signal frame_data_r    : std_logic_vector(15 downto 0) := (others => '0');
    signal frame_feature_r : std_logic_vector(3 downto 0) := (others => '0');

    signal ldac_n_r       : std_logic := '1';
    signal ldac_count_r   : natural range 0 to G_LDAC_LOW_CYCLES - 1 := 0;
    signal overrun_r      : std_logic := '0';

    function first_set_index(mask_value : std_logic_vector(7 downto 0))
        return integer is
    begin
        for index_value in 0 to 7 loop
            if mask_value(index_value) = '1' then
                return index_value;
            end if;
        end loop;
        return 0;
    end function;

    function period_minus_one(period_value : unsigned(31 downto 0))
        return unsigned is
    begin
        if period_value = 0 then
            return (31 downto 0 => '0');
        else
            return period_value - 1;
        end if;
    end function;

begin

    MEM_RD_EN_O      <= mem_rd_en_r;
    MEM_RD_CHANNEL_O <= mem_rd_channel_r;
    MEM_RD_ADDR_O    <= mem_rd_addr_r;

    SPI_START_O <= spi_start_r;

    FRAME_CONTROL_O <= frame_control_r;
    FRAME_ADDRESS_O <= frame_address_r;
    FRAME_DATA_O    <= frame_data_r;
    FRAME_FEATURE_O <= frame_feature_r;

    DAC_LDAC_N_O <= ldac_n_r;

    VALID_MASK_O  <= valid_mask_r;
    ARMED_MASK_O  <= armed_mask_r;
    ACTIVE_MASK_O <= active_mask_r;
    SCHEDULE_OVERRUN_O <= overrun_r;

    BUSY_O <= '1' when
        state_r /= ST_IDLE or
        due_pending_r /= x"00" or
        start_pending_r /= x"00" or
        zero_pending_r /= x"00"
        else '0';

    process (CLK_I)
        variable v_state      : t_state;
        variable v_batch_kind : t_batch_kind;

        variable v_valid_mask  : std_logic_vector(7 downto 0);
        variable v_armed_mask  : std_logic_vector(7 downto 0);
        variable v_active_mask : std_logic_vector(7 downto 0);

        variable v_due_pending   : std_logic_vector(7 downto 0);
        variable v_start_pending : std_logic_vector(7 downto 0);
        variable v_zero_pending  : std_logic_vector(7 downto 0);

        variable v_service_mask : std_logic_vector(7 downto 0);
        variable v_batch_mask   : std_logic_vector(7 downto 0);
        variable v_current_channel : integer range 0 to 7;

        variable v_waveform_length : t_u8_array;
        variable v_sample_period   : t_u32_array;
        variable v_sample_timer    : t_u32_array;
        variable v_read_pointer    : t_u7_array;

        variable v_ldac_count : natural range 0 to G_LDAC_LOW_CYCLES - 1;

        variable channel_index_v : integer range 0 to 7;
        variable stop_event_mask_v  : std_logic_vector(7 downto 0);
        variable start_event_mask_v : std_logic_vector(7 downto 0);
        variable remaining_mask_v   : std_logic_vector(7 downto 0);
        variable effective_start_mask_v : std_logic_vector(7 downto 0);
        variable next_pointer_value_v : integer range 0 to 128;
    begin
        if rising_edge(CLK_I) then
            -- One-clock output pulses.
            mem_rd_en_r <= '0';
            spi_start_r <= '0';
            overrun_r   <= '0';

            if RESETN_I = '0' then
                state_r      <= ST_IDLE;
                batch_kind_r <= BATCH_ZERO;

                valid_mask_r  <= (others => '0');
                armed_mask_r  <= (others => '0');
                active_mask_r <= (others => '0');

                due_pending_r   <= (others => '0');
                start_pending_r <= (others => '0');
                zero_pending_r  <= (others => '0');

                service_mask_r <= (others => '0');
                batch_mask_r   <= (others => '0');
                current_channel_r <= 0;

                waveform_length_r <= (others => (others => '0'));
                sample_period_r   <= (others => (others => '0'));
                sample_timer_r    <= (others => (others => '0'));
                read_pointer_r    <= (others => (others => '0'));

                mem_rd_channel_r <= (others => '0');
                mem_rd_addr_r    <= (others => '0');

                frame_control_r <= (others => '0');
                frame_address_r <= (others => '0');
                frame_data_r    <= (others => '0');
                frame_feature_r <= (others => '0');

                ldac_n_r     <= '1';
                ldac_count_r <= 0;

            else
                -- Copy persistent state into variables. All persistent values
                -- are written back exactly once at the end of this clock.
                v_state      := state_r;
                v_batch_kind := batch_kind_r;

                v_valid_mask  := valid_mask_r;
                v_armed_mask  := armed_mask_r;
                v_active_mask := active_mask_r;

                v_due_pending   := due_pending_r;
                v_start_pending := start_pending_r;
                v_zero_pending  := zero_pending_r;

                v_service_mask := service_mask_r;
                v_batch_mask   := batch_mask_r;
                v_current_channel := current_channel_r;

                v_waveform_length := waveform_length_r;
                v_sample_period   := sample_period_r;
                v_sample_timer    := sample_timer_r;
                v_read_pointer    := read_pointer_r;

                v_ldac_count := ldac_count_r;

                -- A new waveform load invalidates and stops the old waveform
                -- for that channel while the parser writes new RAM contents.
                if LOAD_BEGIN_I = '1' then
                    channel_index_v := to_integer(unsigned(LOAD_CHANNEL_I));
                    v_valid_mask(channel_index_v)  := '0';
                    v_armed_mask(channel_index_v)  := '0';
                    v_active_mask(channel_index_v) := '0';
                    v_due_pending(channel_index_v)   := '0';
                    v_start_pending(channel_index_v) := '0';
                    v_read_pointer(channel_index_v)  := (others => '0');
                    v_sample_timer(channel_index_v)  := (others => '0');
                end if;

                -- Save the complete descriptor only after the parser has
                -- accepted a valid packet through TLAST.
                if LOAD_DONE_I = '1' then
                    channel_index_v := to_integer(unsigned(LOAD_CHANNEL_I));

                    v_waveform_length(channel_index_v) :=
                        unsigned(LOAD_SAMPLE_COUNT_I);
                    v_sample_period(channel_index_v) :=
                        unsigned(LOAD_SAMPLE_PERIOD_TICKS_I);
                    v_read_pointer(channel_index_v) := (others => '0');
                    v_sample_timer(channel_index_v) := (others => '0');

                    v_valid_mask(channel_index_v)  := '1';
                    v_active_mask(channel_index_v) := '0';
                    v_due_pending(channel_index_v) := '0';
                    v_zero_pending(channel_index_v) := '0';

                    if LOAD_FLAGS_I(0) = '1' then
                        -- AUTO_START
                        v_armed_mask(channel_index_v)  := '0';
                        v_start_pending(channel_index_v) := '1';
                    elsif LOAD_FLAGS_I(1) = '1' then
                        -- ARM_ONLY
                        v_armed_mask(channel_index_v)  := '1';
                        v_start_pending(channel_index_v) := '0';
                    else
                        -- Loaded and valid, but waiting for an explicit
                        -- START_MASK command.
                        v_armed_mask(channel_index_v)  := '0';
                        v_start_pending(channel_index_v) := '0';
                    end if;
                end if;

                -- Collect individual and masked stop requests into one mask.
                stop_event_mask_v := (others => '0');

                if STOP_CHANNEL_VALID_I = '1' then
                    channel_index_v := to_integer(unsigned(STOP_CHANNEL_I));
                    stop_event_mask_v(channel_index_v) := '1';
                end if;

                if STOP_MASK_VALID_I = '1' then
                    stop_event_mask_v := stop_event_mask_v or STOP_MASK_I;
                end if;

                if stop_event_mask_v /= x"00" then
                    for index_value in 0 to 7 loop
                        if stop_event_mask_v(index_value) = '1' then
                            v_active_mask(index_value) := '0';
                            v_armed_mask(index_value)  := '0';
                            v_due_pending(index_value)   := '0';
                            v_start_pending(index_value) := '0';
                            v_zero_pending(index_value)  := '1';
                            v_read_pointer(index_value)  := (others => '0');
                            v_sample_timer(index_value)  := (others => '0');
                        end if;
                    end loop;
                end if;

                -- START_MASK restarts every selected channel that contains a
                -- valid waveform. All selected first samples share one LDAC.
                if START_MASK_VALID_I = '1' then
                    start_event_mask_v := START_MASK_I and v_valid_mask;

                    for index_value in 0 to 7 loop
                        if start_event_mask_v(index_value) = '1' then
                            v_active_mask(index_value) := '0';
                            v_armed_mask(index_value)  := '0';
                            v_due_pending(index_value) := '0';
                            v_zero_pending(index_value) := '0';
                            v_start_pending(index_value) := '1';
                            v_read_pointer(index_value) := (others => '0');
                            v_sample_timer(index_value) := (others => '0');
                        end if;
                    end loop;
                end if;

                -- Independent channel timing. The timer is reloaded when an
                -- update becomes due, so long SPI service times do not cause
                -- cumulative phase drift. A second expiry while already
                -- pending indicates that the requested rate is unsustainable.
                if ENABLE_I = '1' then
                    for index_value in 0 to 7 loop
                        if v_active_mask(index_value) = '1' then
                            if v_sample_timer(index_value) = 0 then
                                if v_due_pending(index_value) = '1' then
                                    overrun_r <= '1';
                                else
                                    v_due_pending(index_value) := '1';
                                end if;

                                v_sample_timer(index_value) :=
                                    period_minus_one(v_sample_period(index_value));
                            else
                                v_sample_timer(index_value) :=
                                    v_sample_timer(index_value) - 1;
                            end if;
                        end if;
                    end loop;
                end if;

                -- Scheduler and shared-SPI state machine.
                case v_state is

                    when ST_IDLE =>
                        ldac_n_r <= '1';

                        if ENABLE_I = '1' then
                            -- Zero requests have the highest priority.
                            if v_zero_pending /= x"00" then
                                v_batch_kind := BATCH_ZERO;
                                v_batch_mask := v_zero_pending;
                                v_service_mask := v_zero_pending;
                                v_zero_pending := (others => '0');
                                v_state := ST_SELECT_CHANNEL;

                            elsif v_start_pending /= x"00" then
                                v_batch_kind := BATCH_START;
                                v_batch_mask := v_start_pending;
                                v_service_mask := v_start_pending;
                                v_start_pending := (others => '0');
                                v_state := ST_SELECT_CHANNEL;

                            elsif v_due_pending /= x"00" then
                                v_batch_kind := BATCH_UPDATE;
                                v_batch_mask := v_due_pending;
                                v_service_mask := v_due_pending;
                                v_due_pending := (others => '0');
                                v_state := ST_SELECT_CHANNEL;
                            end if;
                        end if;

                    when ST_SELECT_CHANNEL =>
                        if v_service_mask = x"00" then
                            v_state := ST_WAIT_SPI_IDLE;
                        else
                            channel_index_v := first_set_index(v_service_mask);
                            v_current_channel := channel_index_v;

                            if v_batch_kind = BATCH_ZERO then
                                -- Write zero into the selected DAC input buffer.
                                frame_control_r <= "0000";
                                frame_address_r <= std_logic_vector(
                                    to_unsigned(channel_index_v, 4));
                                frame_data_r    <= x"0000";
                                frame_feature_r <= "0000";
                                v_state := ST_FRAME_READY;
                            else
                                -- Register the address first; RD_EN is issued
                                -- in the following state for synchronous RAM.
                                mem_rd_channel_r <= std_logic_vector(
                                    to_unsigned(channel_index_v, 3));
                                mem_rd_addr_r <= std_logic_vector(
                                    v_read_pointer(channel_index_v));
                                v_state := ST_ISSUE_MEMORY_READ;
                            end if;
                        end if;

                    when ST_ISSUE_MEMORY_READ =>
                        mem_rd_en_r <= '1';
                        v_state := ST_WAIT_MEMORY_READ;

                    when ST_WAIT_MEMORY_READ =>
                        if MEM_RD_VALID_I = '1' then
                            frame_control_r <= "0000";
                            frame_address_r <= std_logic_vector(
                                to_unsigned(v_current_channel, 4));
                            frame_data_r    <= MEM_RD_DATA_I;
                            frame_feature_r <= "0000";
                            v_state := ST_FRAME_READY;
                        end if;

                    when ST_FRAME_READY =>
                        if SPI_BUSY_I = '0' then
                            spi_start_r <= '1';
                            v_state := ST_WAIT_SPI_DONE;
                        end if;

                    when ST_WAIT_SPI_DONE =>
                        if SPI_DONE_I = '1' then
                            -- Advance the waveform pointer after its sample
                            -- has been accepted by the SPI transmitter.
                            if v_batch_kind /= BATCH_ZERO then
                                next_pointer_value_v :=
                                    to_integer(v_read_pointer(v_current_channel)) + 1;

                                if next_pointer_value_v >=
                                    to_integer(v_waveform_length(v_current_channel)) then
                                    v_read_pointer(v_current_channel) :=
                                        (others => '0');
                                else
                                    v_read_pointer(v_current_channel) :=
                                        to_unsigned(next_pointer_value_v, 7);
                                end if;
                            end if;

                            remaining_mask_v := v_service_mask;
                            remaining_mask_v(v_current_channel) := '0';
                            v_service_mask := remaining_mask_v;

                            if remaining_mask_v = x"00" then
                                v_state := ST_WAIT_SPI_IDLE;
                            else
                                v_state := ST_SELECT_CHANNEL;
                            end if;
                        end if;

                    when ST_WAIT_SPI_IDLE =>
                        -- The SPI master keeps BUSY high during its mandatory
                        -- SYNC-high hold interval. Waiting here also guarantees
                        -- sufficient delay from the final SCLK edge to LDAC.
                        if SPI_BUSY_I = '0' then
                            ldac_n_r <= '0';
                            v_ldac_count := G_LDAC_LOW_CYCLES - 1;
                            v_state := ST_LDAC_LOW;
                        end if;

                    when ST_LDAC_LOW =>
                        ldac_n_r <= '0';

                        if v_ldac_count = 0 then
                            ldac_n_r <= '1';

                            if v_batch_kind = BATCH_START then
                                -- Do not reactivate a channel that was stopped
                                -- or invalidated while its start batch was in
                                -- progress.
                                effective_start_mask_v :=
                                    v_batch_mask and v_valid_mask and
                                    not v_zero_pending;

                                for index_value in 0 to 7 loop
                                    if effective_start_mask_v(index_value) = '1' then
                                        v_active_mask(index_value) := '1';
                                        v_armed_mask(index_value)  := '0';
                                        v_sample_timer(index_value) :=
                                            period_minus_one(
                                                v_sample_period(index_value));
                                    end if;
                                end loop;
                            end if;

                            v_batch_mask   := (others => '0');
                            v_service_mask := (others => '0');
                            v_state := ST_IDLE;
                        else
                            v_ldac_count := v_ldac_count - 1;
                        end if;

                end case;

                -- Write back persistent variable state.
                state_r      <= v_state;
                batch_kind_r <= v_batch_kind;

                valid_mask_r  <= v_valid_mask;
                armed_mask_r  <= v_armed_mask;
                active_mask_r <= v_active_mask;

                due_pending_r   <= v_due_pending;
                start_pending_r <= v_start_pending;
                zero_pending_r  <= v_zero_pending;

                service_mask_r <= v_service_mask;
                batch_mask_r   <= v_batch_mask;
                current_channel_r <= v_current_channel;

                waveform_length_r <= v_waveform_length;
                sample_period_r   <= v_sample_period;
                sample_timer_r    <= v_sample_timer;
                read_pointer_r    <= v_read_pointer;

                ldac_count_r <= v_ldac_count;
            end if;
        end if;
    end process;

end architecture rtl;
