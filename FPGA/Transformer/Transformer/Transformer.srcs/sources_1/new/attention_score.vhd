library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.transformer_pkg.all;

entity attention_score is
    port(
        clk     : in  std_logic;
        rst     : in  std_logic;
        start   : in  std_logic;
        Q_mat   : in  matrix_4x8;
        K_mat   : in  matrix_4x8;
        S_mat   : out matrix_4x4;
        S_out   : out signed(15 downto 0);
        out_row : out integer range 0 to 3;
        out_col : out integer range 0 to 3;
        valid   : out std_logic;
        done    : out std_logic
    );
end attention_score;

architecture Behavioral of attention_score is

    constant INV_SQRT8 : signed(15 downto 0) := to_signed(11585, 16);

    signal S_reg     : matrix_4x4 := (others => (others => (others => '0')));
    signal acc       : signed(31 downto 0) := (others => '0');

    type state_type is (IDLE, COMPUTE, SCALE);
    signal state     : state_type := IDLE;

    signal comp_row  : integer range 0 to 4 := 0;
    signal comp_col  : integer range 0 to 4 := 0;
    signal elem_cnt  : integer range 0 to 8 := 0;

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
                        if elem_cnt < 8 then
                            acc      <= acc + (Q_mat(comp_row, elem_cnt) *
                                        K_mat(comp_col, elem_cnt));
                            elem_cnt <= elem_cnt + 1;
                        else
                            state <= SCALE;
                        end if;

                    when SCALE =>
                        -- multiply acc(30:15) by INV_SQRT8
                        scaled := acc(30 downto 15) * INV_SQRT8;

                        -- saturate to Q1.15: check bits [31:30]
                        -- "00" or "11" = no overflow → take bits [30:15]
                        -- "01" = positive overflow → clamp to +32767
                        -- "10" = negative overflow → clamp to -32768
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