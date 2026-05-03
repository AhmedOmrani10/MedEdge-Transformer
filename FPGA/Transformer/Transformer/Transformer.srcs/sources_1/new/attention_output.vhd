library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.transformer_pkg.all;

entity attention_output is
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        start   : in  std_logic;
        Attn    : in  matrix_16x16;
        V_mat   : in  matrix_16x16;
        O_mat   : out matrix_16x16;
        done    : out std_logic
    );
end attention_output;

architecture Behavioral of attention_output is

    signal O_reg    : matrix_16x16 := (others => (others => (others => '0')));

    -- 40-bit accumulator: 16 products of Q1.15 x Q1.15
    -- worst case = 16 x 32767 x 32767 = 17,178,820,624 needs 34 bits
    -- 40-bit gives safe headroom
    signal acc      : signed(39 downto 0) := (others => '0');

    type state_t is (IDLE, COMPUTE, OUTPUT);
    signal state    : state_t := IDLE;

    signal comp_row : integer range 0 to 16 := 0;
    signal comp_col : integer range 0 to 16 := 0;
    signal elem_cnt : integer range 0 to 16 := 0;
    signal done_reg : std_logic := '0';

begin
    done  <= done_reg;
    O_mat <= O_reg;

    process(clk)
        variable raw : integer;
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
                        if elem_cnt < 16 then
                            -- O[row][col] = sum over k of Attn[row][k] * V[k][col]
                            -- 40-bit accumulation using to_integer to prevent overflow
                            acc      <= acc + to_signed(
                                to_integer(Attn(comp_row, elem_cnt)) *
                                to_integer(V_mat(elem_cnt, comp_col)), 40);
                            elem_cnt <= elem_cnt + 1;
                        else
                            -- Saturate to Q1.15
                            raw := to_integer(acc(39 downto 15));
                            if raw > 32767 then
                                O_reg(comp_row, comp_col) <= to_signed(32767, 16);
                            elsif raw < -32768 then
                                O_reg(comp_row, comp_col) <= to_signed(-32768, 16);
                            else
                                O_reg(comp_row, comp_col) <= acc(30 downto 15);
                            end if;
                            acc      <= (others => '0');
                            elem_cnt <= 0;

                            if comp_col < 15 then
                                comp_col <= comp_col + 1;
                            elsif comp_row < 15 then
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
