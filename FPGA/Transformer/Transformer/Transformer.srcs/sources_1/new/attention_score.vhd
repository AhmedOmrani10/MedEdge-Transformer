library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.transformer_pkg.all;

entity attention_score is
    port(
        clk     : in  std_logic;
        rst     : in  std_logic;
        start   : in  std_logic;
        Q_mat   : in  matrix_16x16;
        K_mat   : in  matrix_16x16;
        S_mat   : out matrix_16x16;
        S_out   : out signed(15 downto 0);
        out_row : out integer range 0 to 15;
        out_col : out integer range 0 to 15;
        valid   : out std_logic;
        done    : out std_logic
    );
end attention_score;

architecture Behavioral of attention_score is

    -- INV_SQRT16 = floor(1/sqrt(16) * 32768) = floor(32768/4) = 8192
    constant INV_SQRT16 : signed(15 downto 0) := to_signed(8192, 16);

    signal S_reg     : matrix_16x16 := (others => (others => (others => '0')));

    -- 40-bit accumulator: 16 products of Q1.15 x Q1.15
    -- worst case = 16 x 32767 x 32767 = 17,178,820,624 needs 34 bits
    -- 40-bit gives safe headroom
    signal acc       : signed(39 downto 0) := (others => '0');

    type state_type is (IDLE, COMPUTE, SCALE);
    signal state     : state_type := IDLE;

    signal comp_row  : integer range 0 to 16 := 0;
    signal comp_col  : integer range 0 to 16 := 0;
    signal elem_cnt  : integer range 0 to 16 := 0;

    signal S_out_reg : signed(15 downto 0) := (others => '0');
    signal valid_reg : std_logic := '0';
    signal done_reg  : std_logic := '0';

begin

    S_out <= S_out_reg;
    valid <= valid_reg;
    done  <= done_reg;
    S_mat <= S_reg;

    process(clk)
        variable scaled    : signed(31 downto 0);
        variable s_clamped : signed(15 downto 0);
        variable raw_acc   : integer;
    begin
        if rising_edge(clk) then

            valid_reg <= '0';
            done_reg  <= '0';

            if rst = '1' then
                state     <= IDLE;
                comp_row  <= 0;
                comp_col  <= 0;
                elem_cnt  <= 0;
                acc       <= (others => '0');
                S_out_reg <= (others => '0');

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
                            -- 40-bit accumulation to prevent overflow
                            -- Q_mat(row, k) * K_mat(col, k) summed over 16 elements
                            acc      <= acc + to_signed(
                                to_integer(Q_mat(comp_row, elem_cnt)) *
                                to_integer(K_mat(comp_col, elem_cnt)), 40);
                            elem_cnt <= elem_cnt + 1;
                        else
                            state <= SCALE;
                        end if;

                    when SCALE =>
                        -- Step 1: extract Q1.15 result from 40-bit accumulator
                        -- acc is Q2.30 so acc(30:15) gives Q1.15
                        -- saturate first using full integer range check
                        raw_acc := to_integer(acc(39 downto 15));
                        if raw_acc > 32767 then
                            scaled := to_signed(32767, 16) * INV_SQRT16;
                        elsif raw_acc < -32768 then
                            scaled := to_signed(-32768, 16) * INV_SQRT16;
                        else
                            scaled := acc(30 downto 15) * INV_SQRT16;
                        end if;

                        -- Step 2: extract Q1.15 from scaled result (Q2.30)
                        -- and saturate again
                        if scaled(31) = '0' and scaled(30) = '1' then
                            s_clamped := to_signed(32767, 16);
                        elsif scaled(31) = '1' and scaled(30) = '0' then
                            s_clamped := to_signed(-32768, 16);
                        else
                            s_clamped := scaled(30 downto 15);
                        end if;

                        S_reg(comp_row, comp_col) <= s_clamped;
                        S_out_reg                 <= s_clamped;
                        out_row                   <= comp_row;
                        out_col                   <= comp_col;
                        valid_reg                 <= '1';

                        acc      <= (others => '0');
                        elem_cnt <= 0;
                        state    <= COMPUTE;

                        if comp_col < 15 then
                            comp_col <= comp_col + 1;
                        elsif comp_row < 15 then
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
