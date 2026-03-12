library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.transformer_pkg.all;

entity attention_output is
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        start   : in  std_logic;
        Attn    : in  matrix_4x4;
        V_mat   : in  matrix_4x8;
        O_mat   : out matrix_4x8;
        done    : out std_logic
    );
end attention_output;

architecture Behavioral of attention_output is

    signal O_reg     : matrix_4x8 := (others => (others => (others => '0')));
    signal acc       : signed(31 downto 0) := (others => '0');

    type state_t is (IDLE, COMPUTE, OUTPUT);
    signal state     : state_t := IDLE;

    signal comp_row  : integer range 0 to 4 := 0;
    signal comp_col  : integer range 0 to 8 := 0;
    signal elem_cnt  : integer range 0 to 4 := 0;
    signal done_reg  : std_logic := '0';

begin

    done  <= done_reg;
    O_mat <= O_reg;

    process(clk)
    begin
        if rising_edge(clk) then

            done_reg <= '0';

            if rst = '1' then
                state    <= IDLE;
                comp_row <= 0;
                comp_col <= 0;
                elem_cnt <= 0;
                acc      <= (others => '0');
                O_reg    <= (others => (others => (others => '0')));

            else
                case state is

                    when IDLE =>
                        if start = '1' then
                            state    <= COMPUTE;
                            comp_row <= 0;
                            comp_col <= 0;
                            elem_cnt <= 0;
                            acc      <= (others => '0');
                        end if;

                    when COMPUTE =>
                        -- O[comp_row][comp_col] += Attn[comp_row][k] * V[k][comp_col]
                        if elem_cnt < 4 then
                            acc      <= acc + (Attn(comp_row, elem_cnt) *
                                        V_mat(elem_cnt, comp_col));
                            elem_cnt <= elem_cnt + 1;
                        else
                            -- Store result: take bits [30:15] for Q1.15
                            O_reg(comp_row, comp_col) <= acc(30 downto 15);

                            acc      <= (others => '0');
                            elem_cnt <= 0;

                            if comp_col < 7 then
                                comp_col <= comp_col + 1;
                            elsif comp_row < 3 then
                                comp_col <= 0;
                                comp_row <= comp_row + 1;
                            else
                                state <= OUTPUT;
                            end if;
                        end if;

                    when OUTPUT =>
                        done_reg <= '1';
                        state    <= IDLE;

                    when others =>
                        state <= IDLE;

                end case;
            end if;
        end if;
    end process;

end Behavioral;