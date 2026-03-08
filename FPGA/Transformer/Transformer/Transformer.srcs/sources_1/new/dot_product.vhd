library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dot_product is
    generic(
        VEC_SIZE : integer := 8
    );
    port(
        clk    : in  std_logic;
        rst    : in  std_logic;
        start  : in  std_logic;
        A      : in  signed(15 downto 0);
        W      : in  signed(15 downto 0);
        result : out signed(15 downto 0);
        done   : out std_logic
    );
end dot_product;

architecture Behavioral of dot_product is

    signal acc        : signed(31 downto 0) := (others => '0');
    signal count      : integer range 0 to 8 := 0;
    signal busy       : std_logic := '0';
    signal result_reg : signed(15 downto 0) := (others => '0');
    signal done_reg   : std_logic := '0';

begin

    -- connect internal registers to outputs
    result <= result_reg;
    done   <= done_reg;

    process(clk)
    begin
        if rising_edge(clk) then

            -- default: done pulses only 1 cycle
            done_reg <= '0';

            if rst = '1' then
                acc        <= (others => '0');
                count      <= 0;
                busy       <= '0';
                done_reg   <= '0';
                result_reg <= (others => '0');

            elsif start = '1' and busy = '0' then
                acc        <= (others => '0');
                count      <= 0;
                busy       <= '1';
                result_reg <= (others => '0');

            elsif busy = '1' then

                if count < VEC_SIZE then
                    -- DSP48E1 does this in 1 cycle
                    acc   <= acc + (A * W);
                    count <= count + 1;

                else
                    -- shift right 15 to go Q2.30 → Q1.15
                    result_reg <= acc(30 downto 15);
                    done_reg   <= '1';
                    busy       <= '0';
                    count      <= 0;
                    acc        <= (others => '0');

                end if;
            end if;
        end if;
    end process;

end Behavioral;
