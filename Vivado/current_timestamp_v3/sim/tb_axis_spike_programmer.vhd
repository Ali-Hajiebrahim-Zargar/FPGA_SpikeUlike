library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_axis_spike_programmer is
end entity;

architecture sim of tb_axis_spike_programmer is

    constant C_CHIP_BITS     : natural := 3371;
    constant C_PAYLOAD_BYTES : natural := 422;
    constant C_TOTAL_CLOCKS  : natural := C_CHIP_BITS + 8;
    constant C_MARKER        : std_logic_vector(7 downto 0) := x"C5";

    signal clk           : std_logic := '0';
    signal resetn        : std_logic := '0';

    signal s_data        : std_logic_vector(7 downto 0) := (others => '0');
    signal s_valid       : std_logic := '0';
    signal s_ready       : std_logic;
    signal s_last        : std_logic := '0';

    signal chip_enable   : std_logic;
    signal chip_clk      : std_logic;
    signal chip_data     : std_logic;
    signal chip_latch    : std_logic;
    signal chip_q        : std_logic := '0';
    signal success_led   : std_logic;

    signal clock_count   : natural := 0;
    signal finished      : std_logic := '0';

begin

    clk <= not clk after 5 ns;

    dut : entity work.AXIS_SPIKE_PROGRAMMER
        generic map (
            G_CHIP_BITS_DEFAULT => C_CHIP_BITS,
            G_SERIAL_CLK_HZ     => 10000000
        )
        port map (
            ACLK          => clk,
            ARESETN       => resetn,

            S_AXIS_TDATA  => s_data,
            S_AXIS_TVALID => s_valid,
            S_AXIS_TREADY => s_ready,
            S_AXIS_TLAST  => s_last,
            S_AXIS_TKEEP  => "1",

            S_AXI_AWADDR  => (others => '0'),
            S_AXI_AWPROT  => (others => '0'),
            S_AXI_AWVALID => '0',
            S_AXI_AWREADY => open,

            S_AXI_WDATA   => (others => '0'),
            S_AXI_WSTRB   => (others => '0'),
            S_AXI_WVALID  => '0',
            S_AXI_WREADY  => open,

            S_AXI_BRESP   => open,
            S_AXI_BVALID  => open,
            S_AXI_BREADY  => '0',

            S_AXI_ARADDR  => (others => '0'),
            S_AXI_ARPROT  => (others => '0'),
            S_AXI_ARVALID => '0',
            S_AXI_ARREADY => open,

            S_AXI_RDATA   => open,
            S_AXI_RRESP   => open,
            S_AXI_RVALID  => open,
            S_AXI_RREADY  => '0',

            CHIP_ENABLE_O => chip_enable,
            CHIP_CLK_O    => chip_clk,
            CHIP_DATA_O   => chip_data,
            CHIP_LATCH_O  => chip_latch,
            CHIP_Q_I      => chip_q,

            SUCCESS_LED_O => success_led
        );

    -- Serial bit checker and 3371-bit chip readback model.
    serial_monitor : process(chip_clk)
        variable idx          : natural := 0;
        variable byte_idx     : natural;
        variable bit_idx      : natural;
        variable expected     : std_logic;
        variable data_byte    : std_logic_vector(7 downto 0);
        variable shift_reg    : std_logic_vector(C_CHIP_BITS-1 downto 0)
                                := (others => '0');
    begin
        if rising_edge(chip_clk) then

            assert idx < C_TOTAL_CLOCKS
                report "Too many serial clock pulses"
                severity failure;

            assert chip_enable = '0' and chip_latch = '0'
                report "Invalid CHIP_ENABLE or CHIP_LATCH during shifting"
                severity failure;

            if idx < 8 then
                expected := C_MARKER(idx);
            else
                byte_idx := (idx - 8) / 8;
                bit_idx  := (idx - 8) mod 8;

                assert byte_idx < C_PAYLOAD_BYTES
                    report "Payload byte index overflow"
                    severity failure;

                data_byte := std_logic_vector(
                    to_unsigned(byte_idx mod 256, 8)
                );

                expected := data_byte(bit_idx);
            end if;

            assert chip_data = expected
                report "Serial data mismatch at clock " &
                       integer'image(idx)
                severity failure;

            -- Model the chip as a 3371-bit shift register.
            chip_q <= shift_reg(C_CHIP_BITS-1);

            shift_reg := shift_reg(C_CHIP_BITS-2 downto 0)
                         & chip_data;

            idx := idx + 1;
            clock_count <= idx;

        end if;
    end process;

    stimulus : process

        procedure push_byte(
            constant value : in std_logic_vector(7 downto 0);
            constant final_byte : in boolean
        ) is
        begin
            wait until falling_edge(clk);

            s_data  <= value;
            s_valid <= '1';

            if final_byte then
                s_last <= '1';
            else
                s_last <= '0';
            end if;

            loop
                wait until rising_edge(clk);
                exit when s_ready = '1';
            end loop;

            wait until falling_edge(clk);

            s_valid <= '0';
            s_last  <= '0';
        end procedure;

    begin

        wait until falling_edge(clk);
        resetn <= '1';

        -- Send 422 payload bytes with a deterministic pattern.
        for i in 0 to C_PAYLOAD_BYTES-1 loop
            push_byte(
                std_logic_vector(to_unsigned(i mod 256, 8)),
                i = C_PAYLOAD_BYTES-1
            );
        end loop;

        -- Wait for programming cycle to start and finish.
        wait until chip_latch = '0';
        wait until chip_latch = '1';

        wait for 200 ns;

        assert clock_count = C_TOTAL_CLOCKS
            report "Serial clock count mismatch. Actual=" &
                   integer'image(clock_count)
            severity failure;

        assert success_led = '1'
            report "Marker readback verification failed"
            severity failure;

        report "TB_PASS_SPIKE_3371: 422 bytes, 3379 clocks, serial data and readback OK"
            severity note;

        finished <= '1';
        wait;

    end process;

    watchdog : process
    begin
        wait for 1 ms;

        assert finished = '1'
            report "SPIKE TESTBENCH TIMEOUT"
            severity failure;

        wait;
    end process;

end architecture;