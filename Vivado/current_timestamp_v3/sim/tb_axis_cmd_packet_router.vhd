library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_axis_cmd_packet_router is
end entity;

architecture sim of tb_axis_cmd_packet_router is
    signal clk       : std_logic := '0';
    signal resetn    : std_logic := '0';

    signal s_data    : std_logic_vector(7 downto 0) := (others => '0');
    signal s_valid   : std_logic := '0';
    signal s_ready   : std_logic;
    signal s_last    : std_logic := '0';

    signal spike_data  : std_logic_vector(7 downto 0);
    signal spike_valid : std_logic;
    signal spike_last  : std_logic;

    signal hpu_data    : std_logic_vector(7 downto 0);
    signal hpu_valid   : std_logic;
    signal hpu_last    : std_logic;

    signal invalid_id      : std_logic;
    signal bad_version     : std_logic;
    signal short_packet    : std_logic;
    signal length_mismatch : std_logic;

    signal spike_count   : natural := 0;
    signal hpu_count     : natural := 0;
    signal invalid_count : natural := 0;
    signal finished      : std_logic := '0';
begin

    clk <= not clk after 5 ns;

    dut : entity work.AXIS_CMD_PACKET_ROUTER
        port map (
            ACLK => clk,
            ARESETN => resetn,

            S_AXIS_TDATA  => s_data,
            S_AXIS_TKEEP  => "1",
            S_AXIS_TVALID => s_valid,
            S_AXIS_TREADY => s_ready,
            S_AXIS_TLAST  => s_last,

            M_SPIKE_TDATA  => spike_data,
            M_SPIKE_TKEEP  => open,
            M_SPIKE_TVALID => spike_valid,
            M_SPIKE_TREADY => '1',
            M_SPIKE_TLAST  => spike_last,

            M_DAC1_TDATA => open,
            M_DAC1_TKEEP => open,
            M_DAC1_TVALID => open,
            M_DAC1_TREADY => '1',
            M_DAC1_TLAST => open,

            M_DAC2_TDATA => open,
            M_DAC2_TKEEP => open,
            M_DAC2_TVALID => open,
            M_DAC2_TREADY => '1',
            M_DAC2_TLAST => open,

            M_DAC3_TDATA => open,
            M_DAC3_TKEEP => open,
            M_DAC3_TVALID => open,
            M_DAC3_TREADY => '1',
            M_DAC3_TLAST => open,

            M_DAC4_TDATA => open,
            M_DAC4_TKEEP => open,
            M_DAC4_TVALID => open,
            M_DAC4_TREADY => '1',
            M_DAC4_TLAST => open,

            M_ADC1_TDATA => open,
            M_ADC1_TKEEP => open,
            M_ADC1_TVALID => open,
            M_ADC1_TREADY => '1',
            M_ADC1_TLAST => open,

            M_ADC2_TDATA => open,
            M_ADC2_TKEEP => open,
            M_ADC2_TVALID => open,
            M_ADC2_TREADY => '1',
            M_ADC2_TLAST => open,

            M_ADC3_TDATA => open,
            M_ADC3_TKEEP => open,
            M_ADC3_TVALID => open,
            M_ADC3_TREADY => '1',
            M_ADC3_TLAST => open,

            M_ADC4_TDATA => open,
            M_ADC4_TKEEP => open,
            M_ADC4_TVALID => open,
            M_ADC4_TREADY => '1',
            M_ADC4_TLAST => open,

            M_HPU_TDATA  => hpu_data,
            M_HPU_TKEEP  => open,
            M_HPU_TVALID => hpu_valid,
            M_HPU_TREADY => '1',
            M_HPU_TLAST  => hpu_last,

            CURRENT_ROUTE => open,
            PACKET_DONE => open,
            INVALID_ID => invalid_id,
            BAD_VERSION => bad_version,
            SHORT_PACKET => short_packet,
            LENGTH_MISMATCH => length_mismatch
        );

    monitor : process(clk)
    begin
        if rising_edge(clk) then
            if resetn = '1' then

                if spike_valid = '1' then
                    assert spike_count < 422
                        report "Unexpected extra Spike byte"
                        severity failure;

                    assert spike_data =
                        std_logic_vector(to_unsigned(spike_count mod 256, 8))
                        report "Spike data mismatch"
                        severity failure;

                    if spike_count = 421 then
                        assert spike_last = '1'
                            report "Missing Spike TLAST"
                            severity failure;
                    else
                        assert spike_last = '0'
                            report "Early Spike TLAST"
                            severity failure;
                    end if;

                    spike_count <= spike_count + 1;
                end if;

                if hpu_valid = '1' then
                    assert hpu_count = 0
                        report "Unexpected extra HPU byte"
                        severity failure;

                    assert hpu_data = x"A5" and hpu_last = '1'
                        report "Legacy HPU packet mismatch"
                        severity failure;

                    hpu_count <= hpu_count + 1;
                end if;

                if invalid_id = '1' then
                    invalid_count <= invalid_count + 1;
                end if;

                assert bad_version = '0'
                    report "Unexpected BAD_VERSION"
                    severity failure;

                assert short_packet = '0'
                    report "Unexpected SHORT_PACKET"
                    severity failure;

                assert length_mismatch = '0'
                    report "Unexpected LENGTH_MISMATCH"
                    severity failure;

            end if;
        end if;
    end process;

    stimulus : process

        procedure push_byte(
            constant value : in std_logic_vector(7 downto 0);
            constant final_byte : in boolean := false
        ) is
        begin
            s_data <= value;
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
            s_last <= '0';
        end procedure;

    begin
        wait until falling_edge(clk);
        resetn <= '1';
        wait until falling_edge(clk);

        -- Test 1: Legacy v1 HPU, one payload byte.
        push_byte(x"01");
        push_byte(x"10");
        push_byte(x"09");
        push_byte(x"00");
        push_byte(x"A5", true);

        -- Test 2: Extended v2 Spike, 422 payload bytes.
        -- Length minus one = 421 = 0x01A5.
        push_byte(x"02");
        push_byte(x"20");
        push_byte(x"00");
        push_byte(x"01");
        push_byte(x"A5");

        for i in 0 to 421 loop
            push_byte(
                std_logic_vector(to_unsigned(i mod 256, 8)),
                i = 421
            );
        end loop;

        -- Test 3: Extended v2 must reject HPU.
        push_byte(x"02");
        push_byte(x"30");
        push_byte(x"09");
        push_byte(x"00");
        push_byte(x"00");
        push_byte(x"5A", true);

        wait for 100 ns;

        assert spike_count = 422
            report "Expected exactly 422 Spike bytes"
            severity failure;

        assert hpu_count = 1
            report "Expected exactly one legacy HPU byte"
            severity failure;

        assert invalid_count = 1
            report "Expected one rejected v2 non-Spike command"
            severity failure;

        report "TB_PASS_ROUTER: legacy v1, Spike v2 422 bytes, invalid v2 route"
            severity note;

        finished <= '1';
        wait;
    end process;

    watchdog : process
    begin
        wait for 20 us;
        assert finished = '1'
            report "TESTBENCH TIMEOUT"
            severity failure;
        wait;
    end process;

end architecture;