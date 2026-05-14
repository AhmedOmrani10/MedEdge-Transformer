library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package transformer_pkg is

    -- d_model=9, n_tokens=16, d_ff=22
    type matrix_16x9  is array(0 to 15, 0 to 8)  of signed(15 downto 0);
    type matrix_16x16 is array(0 to 15, 0 to 15) of signed(15 downto 0);
    type matrix_16x22 is array(0 to 15, 0 to 21) of signed(15 downto 0);
    type matrix_1x9   is array(0 to 0,  0 to 8)  of signed(15 downto 0);

end package transformer_pkg;
