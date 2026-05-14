library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.transformer_pkg.all;

entity residual_add is
    port (
        A_in  : in  matrix_16x9;
        B_in  : in  matrix_16x9;
        Y_out : out matrix_16x9
    );
end residual_add;

architecture Behavioral of residual_add is
begin
    process(A_in, B_in)
        variable sum : signed(16 downto 0);
    begin
        for row in 0 to 15 loop
            for col in 0 to 8 loop
                sum := resize(A_in(row,col),17) + resize(B_in(row,col),17);
                if sum > 32767 then
                    Y_out(row,col) <= to_signed(32767,16);
                elsif sum < -32768 then
                    Y_out(row,col) <= to_signed(-32768,16);
                else
                    Y_out(row,col) <= sum(15 downto 0);
                end if;
            end loop;
        end loop;
    end process;
end Behavioral;
