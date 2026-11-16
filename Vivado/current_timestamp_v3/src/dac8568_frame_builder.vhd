library ieee;
use ieee.std_logic_1164.all;

-- Builds one 32-bit DAC8568 serial frame.
--
-- Frame format:
--   DB31..DB28 : prefix bits, fixed to 0000
--   DB27..DB24 : control bits
--   DB23..DB20 : DAC channel/address bits
--   DB19..DB4  : 16-bit DAC data
--   DB3..DB0   : feature bits
--
-- Common control values:
--   0000 : write selected DAC input register only
--   0010 : write selected input register and update all DAC registers
--   0011 : write selected input register and update the selected DAC register
entity dac8568_frame_builder is
    port (
        CONTROL_I : in  std_logic_vector(3 downto 0);
        ADDRESS_I : in  std_logic_vector(3 downto 0);
        DATA_I    : in  std_logic_vector(15 downto 0);
        FEATURE_I : in  std_logic_vector(3 downto 0);
        FRAME_O   : out std_logic_vector(31 downto 0)
    );
end entity dac8568_frame_builder;

architecture rtl of dac8568_frame_builder is
begin
    FRAME_O <= "0000" & CONTROL_I & ADDRESS_I & DATA_I & FEATURE_I;
end architecture rtl;
