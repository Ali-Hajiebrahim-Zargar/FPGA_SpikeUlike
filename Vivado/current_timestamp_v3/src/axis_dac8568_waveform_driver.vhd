-- SPDX-License-Identifier: MIT
--
-- Complete AXI-Stream waveform driver for one physical DAC8568A.
--
-- Hardware assumptions:
--   * ACLK = 100 MHz by default
--   * DAC8568A, AVDD = 3.3 V
--   * External reference = 1.8 V
--   * Internal reference remains disabled
--   * One independent SPI interface per physical DAC
--
-- Input payload formats are parsed by axis_dac8568_packet_parser:
--   0x00..0x07 : load channel A..H
--   0x08..0x0F : stop one channel and drive it to zero
--   0x10 mask  : start selected valid channels together
--   0x11 mask  : stop selected channels and drive them to zero
--
-- This entity is intended to be instantiated four times in the Vivado Block
-- Design and connected to M_DAC1 through M_DAC4 of axis_cmd_packet_router_0.

library ieee;
use ieee.std_logic_1164.all;

entity axis_dac8568_waveform_driver is
    generic (
        G_CLK_FREQ_HZ       : positive := 100_000_000;
        G_SCLK_FREQ_HZ      : positive := 25_000_000;
        G_MAX_SAMPLES       : positive := 125;
        G_POWERUP_DELAY_US  : positive := 100;
        G_SYNC_HIGH_CYCLES  : positive := 8;
        G_LDAC_LOW_CYCLES   : positive := 10
    );
    port (
        ACLK          : in  std_logic;
        ARESETN       : in  std_logic;

        -- AXI4-Stream payload input from axis_cmd_packet_router_0.
        S_AXIS_TDATA  : in  std_logic_vector(7 downto 0);
        S_AXIS_TKEEP  : in  std_logic_vector(0 downto 0);
        S_AXIS_TVALID : in  std_logic;
        S_AXIS_TREADY : out std_logic;
        S_AXIS_TLAST  : in  std_logic;

        -- Physical DAC8568 interface.
        DAC_SYNC_N_O  : out std_logic;
        DAC_SCLK_O    : out std_logic;
        DAC_DIN_O     : out std_logic;
        DAC_LDAC_N_O  : out std_logic;
        DAC_CLR_N_O   : out std_logic;

        -- Status and debug outputs.
        INIT_DONE_O          : out std_logic;
        INIT_ERROR_O         : out std_logic;
        VALID_MASK_O         : out std_logic_vector(7 downto 0);
        ARMED_MASK_O         : out std_logic_vector(7 downto 0);
        ACTIVE_MASK_O        : out std_logic_vector(7 downto 0);
        DRIVER_BUSY_O        : out std_logic;
        PACKET_ERROR_O       : out std_logic;
        PACKET_ERROR_CODE_O  : out std_logic_vector(7 downto 0);
        SCHEDULE_OVERRUN_O   : out std_logic
    );
end entity axis_dac8568_waveform_driver;

architecture rtl of axis_dac8568_waveform_driver is

    -- Parser to waveform-memory write port.
    signal mem_wr_en      : std_logic;
    signal mem_wr_channel : std_logic_vector(2 downto 0);
    signal mem_wr_addr    : std_logic_vector(6 downto 0);
    signal mem_wr_data    : std_logic_vector(15 downto 0);

    -- Parser load events and descriptors.
    signal load_begin       : std_logic;
    signal load_done        : std_logic;
    signal load_channel     : std_logic_vector(2 downto 0);
    signal load_flags       : std_logic_vector(7 downto 0);
    signal load_sample_count: std_logic_vector(7 downto 0);
    signal load_sample_period_ticks : std_logic_vector(31 downto 0);

    -- Parser short control events.
    signal stop_channel_valid : std_logic;
    signal stop_channel       : std_logic_vector(2 downto 0);
    signal start_mask_valid   : std_logic;
    signal start_mask         : std_logic_vector(7 downto 0);
    signal stop_mask_valid    : std_logic;
    signal stop_mask          : std_logic_vector(7 downto 0);

    signal packet_error      : std_logic;
    signal packet_error_code : std_logic_vector(7 downto 0);

    -- Scheduler to waveform-memory read port.
    signal mem_rd_en      : std_logic;
    signal mem_rd_channel : std_logic_vector(2 downto 0);
    signal mem_rd_addr    : std_logic_vector(6 downto 0);
    signal mem_rd_data    : std_logic_vector(15 downto 0);
    signal mem_rd_valid   : std_logic;

    -- Scheduler frame fields.
    signal sched_frame_control : std_logic_vector(3 downto 0);
    signal sched_frame_address : std_logic_vector(3 downto 0);
    signal sched_frame_data    : std_logic_vector(15 downto 0);
    signal sched_frame_feature : std_logic_vector(3 downto 0);
    signal sched_frame         : std_logic_vector(31 downto 0);

    signal sched_spi_start : std_logic;
    signal sched_ldac_n    : std_logic;
    signal sched_busy      : std_logic;

    signal valid_mask      : std_logic_vector(7 downto 0);
    signal armed_mask      : std_logic_vector(7 downto 0);
    signal active_mask     : std_logic_vector(7 downto 0);
    signal schedule_overrun: std_logic;

    -- Initialization controller.
    signal init_spi_start : std_logic;
    signal init_spi_frame : std_logic_vector(31 downto 0);
    signal init_busy      : std_logic;
    signal init_done      : std_logic;
    signal init_error     : std_logic;
    signal init_ldac_n    : std_logic;
    signal init_clr_n     : std_logic;

    -- Shared SPI master and arbitration.
    signal spi_start_mux : std_logic;
    signal spi_frame_mux : std_logic_vector(31 downto 0);
    signal spi_busy      : std_logic;
    signal spi_done      : std_logic;

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

    -- Initialization owns the SPI master until it has completed. The waveform
    -- scheduler is enabled only after INIT_DONE is asserted.
    spi_start_mux <= init_spi_start when init_done = '0' else sched_spi_start;
    spi_frame_mux <= init_spi_frame when init_done = '0' else sched_frame;

    DAC_LDAC_N_O <= init_ldac_n when init_done = '0' else sched_ldac_n;
    DAC_CLR_N_O  <= init_clr_n;

    INIT_DONE_O         <= init_done;
    INIT_ERROR_O        <= init_error;
    VALID_MASK_O        <= valid_mask;
    ARMED_MASK_O        <= armed_mask;
    ACTIVE_MASK_O       <= active_mask;
    PACKET_ERROR_O      <= packet_error;
    PACKET_ERROR_CODE_O <= packet_error_code;
    SCHEDULE_OVERRUN_O  <= schedule_overrun;

    DRIVER_BUSY_O <= init_busy or sched_busy or spi_busy;

    u_packet_parser : entity work.axis_dac8568_packet_parser
        generic map (
            G_MAX_SAMPLES => G_MAX_SAMPLES
        )
        port map (
            ACLK          => ACLK,
            ARESETN       => ARESETN,

            S_AXIS_TDATA  => S_AXIS_TDATA,
            S_AXIS_TKEEP  => S_AXIS_TKEEP,
            S_AXIS_TVALID => S_AXIS_TVALID,
            S_AXIS_TREADY => S_AXIS_TREADY,
            S_AXIS_TLAST  => S_AXIS_TLAST,

            WR_EN_O      => mem_wr_en,
            WR_CHANNEL_O => mem_wr_channel,
            WR_ADDR_O    => mem_wr_addr,
            WR_DATA_O    => mem_wr_data,

            LOAD_BEGIN_O               => load_begin,
            LOAD_DONE_O                => load_done,
            LOAD_CHANNEL_O             => load_channel,
            LOAD_FLAGS_O               => load_flags,
            LOAD_SAMPLE_COUNT_O        => load_sample_count,
            LOAD_SAMPLE_PERIOD_TICKS_O => load_sample_period_ticks,

            STOP_CHANNEL_VALID_O => stop_channel_valid,
            STOP_CHANNEL_O       => stop_channel,

            START_MASK_VALID_O => start_mask_valid,
            START_MASK_O       => start_mask,

            STOP_MASK_VALID_O => stop_mask_valid,
            STOP_MASK_O       => stop_mask,

            PACKET_ERROR_O => packet_error,
            ERROR_CODE_O   => packet_error_code
        );

    u_waveform_memory : entity work.dac8568_waveform_memory
        port map (
            CLK_I    => ACLK,
            RESETN_I => ARESETN,

            WR_EN_I      => mem_wr_en,
            WR_CHANNEL_I => mem_wr_channel,
            WR_ADDR_I    => mem_wr_addr,
            WR_DATA_I    => mem_wr_data,

            RD_EN_I      => mem_rd_en,
            RD_CHANNEL_I => mem_rd_channel,
            RD_ADDR_I    => mem_rd_addr,
            RD_DATA_O    => mem_rd_data,
            RD_VALID_O   => mem_rd_valid
        );

    u_channel_scheduler : entity work.dac8568_channel_scheduler
        generic map (
            G_LDAC_LOW_CYCLES => G_LDAC_LOW_CYCLES
        )
        port map (
            CLK_I    => ACLK,
            RESETN_I => ARESETN,
            ENABLE_I => init_done,

            LOAD_BEGIN_I               => load_begin,
            LOAD_DONE_I                => load_done,
            LOAD_CHANNEL_I             => load_channel,
            LOAD_FLAGS_I               => load_flags,
            LOAD_SAMPLE_COUNT_I        => load_sample_count,
            LOAD_SAMPLE_PERIOD_TICKS_I => load_sample_period_ticks,

            STOP_CHANNEL_VALID_I => stop_channel_valid,
            STOP_CHANNEL_I       => stop_channel,

            START_MASK_VALID_I => start_mask_valid,
            START_MASK_I       => start_mask,

            STOP_MASK_VALID_I => stop_mask_valid,
            STOP_MASK_I       => stop_mask,

            MEM_RD_EN_O      => mem_rd_en,
            MEM_RD_CHANNEL_O => mem_rd_channel,
            MEM_RD_ADDR_O    => mem_rd_addr,
            MEM_RD_DATA_I    => mem_rd_data,
            MEM_RD_VALID_I   => mem_rd_valid,

            SPI_BUSY_I  => spi_busy,
            SPI_DONE_I  => spi_done,
            SPI_START_O => sched_spi_start,

            FRAME_CONTROL_O => sched_frame_control,
            FRAME_ADDRESS_O => sched_frame_address,
            FRAME_DATA_O    => sched_frame_data,
            FRAME_FEATURE_O => sched_frame_feature,

            DAC_LDAC_N_O => sched_ldac_n,

            VALID_MASK_O  => valid_mask,
            ARMED_MASK_O  => armed_mask,
            ACTIVE_MASK_O => active_mask,
            BUSY_O        => sched_busy,
            SCHEDULE_OVERRUN_O => schedule_overrun
        );

    u_frame_builder : entity work.dac8568_frame_builder
        port map (
            CONTROL_I => sched_frame_control,
            ADDRESS_I => sched_frame_address,
            DATA_I    => sched_frame_data,
            FEATURE_I => sched_frame_feature,
            FRAME_O   => sched_frame
        );

    u_init_controller : entity work.dac8568_init_controller
        generic map (
            G_CLK_FREQ_HZ      => G_CLK_FREQ_HZ,
            G_POWERUP_DELAY_US => G_POWERUP_DELAY_US
        )
        port map (
            CLK_I    => ACLK,
            RESETN_I => ARESETN,

            SPI_BUSY_I  => spi_busy,
            SPI_DONE_I  => spi_done,
            SPI_START_O => init_spi_start,
            SPI_FRAME_O => init_spi_frame,

            INIT_BUSY_O  => init_busy,
            INIT_DONE_O  => init_done,
            INIT_ERROR_O => init_error,

            DAC_LDAC_N_O => init_ldac_n,
            DAC_CLR_N_O  => init_clr_n
        );

    u_spi_master : entity work.dac8568_spi_master
        generic map (
            G_CLK_FREQ_HZ      => G_CLK_FREQ_HZ,
            G_SCLK_FREQ_HZ     => G_SCLK_FREQ_HZ,
            G_SYNC_HIGH_CYCLES => G_SYNC_HIGH_CYCLES
        )
        port map (
            CLK_I    => ACLK,
            RESETN_I => ARESETN,

            START_I => spi_start_mux,
            FRAME_I => spi_frame_mux,

            BUSY_O => spi_busy,
            DONE_O => spi_done,

            DAC_SYNC_N_O => DAC_SYNC_N_O,
            DAC_SCLK_O   => DAC_SCLK_O,
            DAC_DIN_O    => DAC_DIN_O
        );

end architecture rtl;
