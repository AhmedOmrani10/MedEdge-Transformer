library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.transformer_pkg.all;

entity weighted_pool is
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        start : in  std_logic;
        X_in  : in  matrix_16x9;
        Y_out : out matrix_1x9;
        done  : out std_logic
    );
end weighted_pool;

architecture Behavioral of weighted_pool is

    -- Pool weights from Python softmax output (Q15)
    -- pool_w[16]: {0.004121,0.022229,0.158733,0.058486,0.011117,
    --              0.141242,0.004855,0.010264,0.099267,0.015157,
    --              0.019176,0.045108,0.285119,0.042371,0.074944,0.007813}
    type pool_array is array(0 to 15) of signed(15 downto 0);
    constant POOL_W : pool_array := (
        to_signed(135,16),   to_signed(729,16),   to_signed(5202,16),
        to_signed(1917,16),  to_signed(364,16),   to_signed(4630,16),
        to_signed(159,16),   to_signed(336,16),   to_signed(3254,16),
        to_signed(497,16),   to_signed(629,16),   to_signed(1479,16),
        to_signed(9346,16),  to_signed(1389,16),  to_signed(2456,16),
        to_signed(256,16)
    );

    signal Y_reg    : matrix_1x9 := (others => (others => (others => '0')));
    signal acc      : signed(39 downto 0) := (others => '0');
    signal done_reg : std_logic := '0';

    type state_t is (IDLE, COMPUTE, STORE);
    signal state  : state_t := IDLE;
    signal col_j  : integer range 0 to 9  := 0;
    signal elem_k : integer range 0 to 16 := 0;

begin
    Y_out <= Y_reg;
    done  <= done_reg;

    process(clk)
        variable raw : integer;
    begin
        if rising_edge(clk) then
            done_reg <= '0';
            if rst = '1' then
                state  <= IDLE;
                col_j  <= 0; elem_k <= 0;
                acc    <= (others => '0');
                Y_reg  <= (others => (others => (others => '0')));
            else
                case state is
                    when IDLE =>
                        if start = '1' then
                            state  <= COMPUTE;
                            col_j  <= 0; elem_k <= 0;
                            acc    <= (others => '0');
                        end if;

                    when COMPUTE =>
                        -- Y[0][col_j] = sum_k POOL_W[k] * X_in[k][col_j]
                        if elem_k < 16 then
                            acc    <= acc + to_signed(
                                to_integer(POOL_W(elem_k)) *
                                to_integer(X_in(elem_k, col_j)), 40);
                            elem_k <= elem_k + 1;
                        else
                            state <= STORE;
                        end if;

                    when STORE =>
                        raw := to_integer(acc(39 downto 15));
                        if raw > 32767 then
                            Y_reg(0, col_j) <= to_signed(32767, 16);
                        elsif raw < -32768 then
                            Y_reg(0, col_j) <= to_signed(-32768, 16);
                        else
                            Y_reg(0, col_j) <= to_signed(raw, 16);
                        end if;
                        acc    <= (others => '0');
                        elem_k <= 0;
                        if col_j < 8 then
                            col_j <= col_j + 1;
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
