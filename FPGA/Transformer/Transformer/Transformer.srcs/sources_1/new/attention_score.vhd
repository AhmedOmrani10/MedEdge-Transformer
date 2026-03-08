library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.transformer_pkg.all;

entity attention_score is
    port(
        clk     : in  std_logic;
        rst     : in  std_logic;
        start   : in  std_logic;

        -- input Q and K matrices from qkv_projector
        Q_mat   : in  matrix_4x8;
        K_mat   : in  matrix_4x8;

        -- output scaled attention scores
        S_mat   : out matrix_4x4;
        S_out   : out signed(15 downto 0);
        out_row : out integer range 0 to 3;
        out_col : out integer range 0 to 3;
        valid   : out std_logic;
        done    : out std_logic
    );
end attention_score;

architecture Behavioral of attention_score is

    -- 1/sqrt(8) in Q1.15 = 11585
    constant INV_SQRT8 : signed(15 downto 0) := to_signed(11585, 16);

    -- internal score matrix
    signal S_reg : matrix_4x4 := (others => (others => (others => '0')));

    -- accumulator
    signal acc : signed(31 downto 0) := (others => '0');

    -- FSM
    type state_type is (IDLE, COMPUTE, SCALE);
    signal state : state_type := IDLE;

    -- counters
    signal comp_row : integer range 0 to 4 := 0;
    signal comp_col : integer range 0 to 4 := 0;
    signal elem_cnt : integer range 0 to 8 := 0;

    -- output registers
    signal S_out_reg  : signed(15 downto 0) := (others => '0');
    signal valid_reg  : std_logic := '0';
    signal done_reg   : std_logic := '0';

begin

    S_out <= S_out_reg;
    valid <= valid_reg;
    done  <= done_reg;
    S_mat <= S_reg;

    process(clk)
    begin
        if rising_edge(clk) then

            valid_reg <= '0';
            done_reg  <= '0';

            if rst = '1' then
                state    <= IDLE;
                comp_row <= 0;
                comp_col <= 0;
                elem_cnt <= 0;
                acc      <= (others => '0');
                S_out_reg<= (others => '0');

            else
                case state is

                    -- =======================
                    when IDLE =>
                        if start = '1' then
                            state    <= COMPUTE;
                            comp_row <= 0;
                            comp_col <= 0;
                            elem_cnt <= 0;
                            acc      <= (others => '0');
                        end if;

                    -- =======================
                    -- Compute S[i][j] = Q[i] dot K[j]
                    when COMPUTE =>
                        if elem_cnt < 8 then
                            -- DSP48E1: dot product of Q row i with K row j
                            -- Kᵀ[k][j] = K[j][k]
                            acc      <= acc + (Q_mat(comp_row, elem_cnt) *
                                        K_mat(comp_col, elem_cnt));
                            elem_cnt <= elem_cnt + 1;

                        else
                            -- dot product done → go scale
                            state <= SCALE;
                        end if;

                    -- =======================
                    -- Scale by 1/sqrt(8)
                    when SCALE =>
                        -- multiply by INV_SQRT8 then shift right 15
                        -- acc is Q2.30, after ×INV_SQRT8 we get Q3.45
                        -- take bits (44 downto 29) to get Q1.15
                        S_reg(comp_row, comp_col) <=
                            resize(shift_right(
                                acc(30 downto 15) * INV_SQRT8,
                            15), 16);

                        S_out_reg <= resize(shift_right(
                                acc(30 downto 15) * INV_SQRT8,
                            15), 16);

                        out_row   <= comp_row;
                        out_col   <= comp_col;
                        valid_reg <= '1';

                        -- reset for next element
                        acc      <= (others => '0');
                        elem_cnt <= 0;
                        state    <= COMPUTE;

                        -- advance counters
                        if comp_col < 3 then
                            comp_col <= comp_col + 1;
                        elsif comp_row < 3 then
                            comp_col <= 0;
                            comp_row <= comp_row + 1;
                        else
                            done_reg <= '1';
                            state    <= IDLE;
                        end if;

                    when others =>
                        state <= IDLE;

                end case;
            end if;
        end if;
    end process;

end Behavioral;