library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.transformer_pkg.all;

entity attention_score is
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        start   : in  std_logic;
        Q_mat   : in  matrix_16x9;
        K_mat   : in  matrix_16x9;
        S_mat   : out matrix_16x16;
        S_out   : out signed(15 downto 0);
        out_row : out integer range 0 to 15;
        out_col : out integer range 0 to 15;
        valid   : out std_logic;
        done    : out std_logic
    );
end attention_score;

architecture Behavioral of attention_score is

    -- INV_SQRT_9 = round(32768 / sqrt(9)) = round(32768/3) = 10923 (Q15)
    constant INV_SQRT_D : signed(15 downto 0) := to_signed(10923, 16);

    signal S_reg     : matrix_16x16 := (others => (others => (others => '0')));
    signal acc       : signed(39 downto 0) := (others => '0');
    signal done_reg  : std_logic := '0';
    signal valid_reg : std_logic := '0';

    -- Pipeline register: store acc*INV_SQRT_D intermediate (56-bit product)
    -- then in CLAMP we shift right by 15 and saturate
    signal prod_reg  : signed(55 downto 0) := (others => '0');
    signal scale_row : integer range 0 to 15 := 0;
    signal scale_col : integer range 0 to 15 := 0;

    type state_t is (IDLE, COMPUTE, SCALE, CLAMP, OUTPUT_S);
    signal state  : state_t := IDLE;
    signal row_i  : integer range 0 to 16 := 0;
    signal col_j  : integer range 0 to 16 := 0;
    signal elem_k : integer range 0 to 9  := 0;

begin
    S_mat <= S_reg;
    done  <= done_reg;
    valid <= valid_reg;

    process(clk)
        variable shifted : signed(39 downto 0);
        variable raw     : integer;
    begin
        if rising_edge(clk) then
            done_reg  <= '0';
            valid_reg <= '0';

            if rst = '1' then
                state     <= IDLE;
                row_i     <= 0; col_j <= 0; elem_k <= 0;
                acc       <= (others => '0');
                prod_reg  <= (others => '0');
                scale_row <= 0; scale_col <= 0;
                S_reg     <= (others => (others => (others => '0')));
            else
                case state is

                    when IDLE =>
                        if start = '1' then
                            state  <= COMPUTE;
                            row_i  <= 0; col_j <= 0; elem_k <= 0;
                            acc    <= (others => '0');
                        end if;

                    when COMPUTE =>
                        if elem_k < 9 then
                            acc    <= acc + to_signed(
                                to_integer(Q_mat(row_i, elem_k)) *
                                to_integer(K_mat(col_j, elem_k)), 40);
                            elem_k <= elem_k + 1;
                        else
                            state <= SCALE;
                        end if;

                    when SCALE =>
                        -- Pipeline stage 1: just do the multiply, register product
                        -- acc is Q15, INV_SQRT_D is Q15
                        -- product is Q30 in a 56-bit register
                        prod_reg  <= acc * INV_SQRT_D;
                        scale_row <= row_i;
                        scale_col <= col_j;
                        state     <= CLAMP;

                    when CLAMP =>
                        -- Pipeline stage 2: shift right by 15 to get Q15 result
                        -- then extract integer and saturate
                        -- prod_reg is 56-bit Q30, shift right 15 gives Q15
                        -- take bits (39 downto 0) after shift = prod_reg(54 downto 15)
                        shifted := prod_reg(54 downto 15);
                        raw := to_integer(shifted(39 downto 15));
                        if raw > 32767 then
                            S_reg(scale_row, scale_col) <= to_signed(32767, 16);
                        elsif raw < -32768 then
                            S_reg(scale_row, scale_col) <= to_signed(-32768, 16);
                        else
                            S_reg(scale_row, scale_col) <= to_signed(raw, 16);
                        end if;
                        S_out     <= to_signed(raw, 16);
                        out_row   <= scale_row;
                        out_col   <= scale_col;
                        valid_reg <= '1';
                        acc       <= (others => '0');
                        elem_k    <= 0;

                        if col_j < 15 then
                            col_j <= col_j + 1;
                            state <= COMPUTE;
                        elsif row_i < 15 then
                            col_j <= 0;
                            row_i <= row_i + 1;
                            state <= COMPUTE;
                        else
                            state <= OUTPUT_S;
                        end if;

                    when OUTPUT_S =>
                        done_reg <= '1';
                        state    <= IDLE;

                    when others => state <= IDLE;
                end case;
            end if;
        end if;
    end process;

end Behavioral;
