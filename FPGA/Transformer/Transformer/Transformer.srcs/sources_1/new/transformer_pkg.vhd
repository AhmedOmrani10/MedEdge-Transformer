library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package transformer_pkg is
    type matrix_4x8 is array(0 to 3, 0 to 7) of signed(15 downto 0);
    type matrix_4x4 is array(0 to 3, 0 to 3) of signed(15 downto 0);
    type matrix_1x8 is array(0 to 0, 0 to 7) of signed(15 downto 0);
end package transformer_pkg;