library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.transformer_pkg.all;

entity attention_output is
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        start : in  std_logic;
        Attn  : in  matrix_16x16;
        V_mat : in  matrix_16x9;
        O_mat : out matrix_16x9;
        done  : out std_logic
    );
end attention_output;

architecture Behavioral of attention_output is

    signal O_reg    : matrix_16x9 := (others => (others => (others => '0')));
    signal acc      : signed(39 downto 0) := (others => '0');
    signal done_reg : std_logic := '0';

    type state_t is (IDLE, COMPUTE, STORE);
    signal state  : state_t := IDLE;
    signal row_i  : integer range 0 to 16 := 0;
    signal col_j  : integer range 0 to 9  := 0;
    signal elem_k : integer range 0 to 16 := 0;

begin
    O_mat <= O_reg;
    done  <= done_reg;

    process(clk)
        variable raw : integer;
    begin
        if rising_edge(clk) then
            done_reg <= '0';
            if rst = '1' then
                state  <= IDLE;
                row_i  <= 0; col_j <= 0; elem_k <= 0;
                acc    <= (others => '0');
                O_reg  <= (others => (others => (others => '0')));
            else
                case state is
                    when IDLE =>
                        if start = '1' then
                            state  <= COMPUTE;
                            row_i  <= 0; col_j <= 0; elem_k <= 0;
                            acc    <= (others => '0');
                        end if;

                    when COMPUTE =>
                        -- O[row_i][col_j] = sum_k A[row_i][k] * V[k][col_j]
                        if elem_k < 16 then
                            acc    <= acc + to_signed(
                                to_integer(Attn(row_i, elem_k)) *
                                to_integer(V_mat(elem_k, col_j)), 40);
                            elem_k <= elem_k + 1;
                        else
                            state <= STORE;
                        end if;

                    when STORE =>
                        raw := to_integer(acc(39 downto 15));
                        if raw > 32767 then
                            O_reg(row_i, col_j) <= to_signed(32767, 16);
                        elsif raw < -32768 then
                            O_reg(row_i, col_j) <= to_signed(-32768, 16);
                        else
                            O_reg(row_i, col_j) <= to_signed(raw, 16);
                        end if;
                        acc    <= (others => '0');
                        elem_k <= 0;
                        if col_j < 8 then
                            col_j <= col_j + 1;
                            state <= COMPUTE;
                        elsif row_i < 15 then
                            col_j <= 0;
                            row_i <= row_i + 1;
                            state <= COMPUTE;
                        else
                            done_reg <= '1';
                            state    <= IDLE;
                        end if;

                    when others => state <= IDLE;
                end case;
            end if;
        end if;
    end process;
end Behavioral;
