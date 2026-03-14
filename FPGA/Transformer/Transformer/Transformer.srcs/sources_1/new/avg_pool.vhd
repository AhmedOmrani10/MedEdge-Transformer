library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.transformer_pkg.all;

entity avg_pool is
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        start : in  std_logic;
        X_in  : in  matrix_4x8;
        Y_out : out matrix_1x8;
        done  : out std_logic
    );
end avg_pool;

architecture Behavioral of avg_pool is
    signal Y_reg    : matrix_1x8 := (others => (others => (others => '0')));
    signal done_reg : std_logic  := '0';
    type state_t is (IDLE, COMPUTE, OUTPUT);
    signal state    : state_t    := IDLE;
    signal col      : integer range 0 to 8 := 0;
begin
    done  <= done_reg;
    Y_out <= Y_reg;

    process(clk)
        variable sum_v : signed(17 downto 0);
    begin
        if rising_edge(clk) then
            done_reg <= '0';
            if rst = '1' then
                state  <= IDLE;
                col    <= 0;
                Y_reg  <= (others => (others => (others => '0')));
            else
                case state is
                    when IDLE =>
                        if start = '1' then
                            state <= COMPUTE;
                            col   <= 0;
                        end if;

                    when COMPUTE =>
                        sum_v := resize(X_in(0, col), 18) +
                                 resize(X_in(1, col), 18) +
                                 resize(X_in(2, col), 18) +
                                 resize(X_in(3, col), 18);
                        Y_reg(0, col) <= sum_v(17 downto 2);
                        if col < 7 then
                            col <= col + 1;
                        else
                            state <= OUTPUT;
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