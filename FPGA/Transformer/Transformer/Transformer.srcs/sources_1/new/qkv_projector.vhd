library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity qkv_projector is
    port(
        clk     : in  std_logic;
        rst     : in  std_logic;
        start   : in  std_logic;
        X_in    : in  signed(15 downto 0);
        Q_out   : out signed(15 downto 0);
        K_out   : out signed(15 downto 0);
        V_out   : out signed(15 downto 0);
        out_row : out integer range 0 to 3;
        out_col : out integer range 0 to 7;
        valid   : out std_logic;
        done    : out std_logic
    );
end qkv_projector;

architecture Behavioral of qkv_projector is

    type weight_array is array(0 to 63) of signed(15 downto 0);

    constant Wq : weight_array := (
        to_signed(2270,16),   to_signed(7621,16),   to_signed(-11627,16), to_signed(-2833,16),
        to_signed(10281,16),  to_signed(-2546,16),  to_signed(17295,16),  to_signed(1646,16),
        to_signed(612,16),    to_signed(-4961,16),  to_signed(8720,16),   to_signed(-5127,16),
        to_signed(1354,16),   to_signed(-4862,16),  to_signed(1603,16),   to_signed(5303,16),
        to_signed(2249,16),   to_signed(-7485,16),  to_signed(-1845,16),  to_signed(-4061,16),
        to_signed(5268,16),   to_signed(-1395,16),  to_signed(-5460,16),  to_signed(-3164,16),
        to_signed(-2779,16),  to_signed(-60,16),    to_signed(1061,16),   to_signed(4439,16),
        to_signed(5980,16),   to_signed(-5405,16),  to_signed(10385,16),  to_signed(7857,16),
        to_signed(1362,16),   to_signed(4103,16),   to_signed(1358,16),   to_signed(13058,16),
        to_signed(-8534,16),  to_signed(-7415,16),  to_signed(3419,16),   to_signed(2188,16),
        to_signed(-959,16),   to_signed(689,16),    to_signed(4105,16),   to_signed(-890,16),
        to_signed(374,16),    to_signed(-3002,16),  to_signed(3466,16),   to_signed(5457,16),
        to_signed(-4392,16),  to_signed(8201,16),   to_signed(-5204,16),  to_signed(-1634,16),
        to_signed(4746,16),   to_signed(-6437,16),  to_signed(-47,16),    to_signed(11412,16),
        to_signed(5378,16),   to_signed(8537,16),   to_signed(3294,16),   to_signed(-12459,16),
        to_signed(-7263,16),  to_signed(4501,16),   to_signed(8725,16),   to_signed(2247,16)
    );

    constant Wk : weight_array := (
        to_signed(-4585,16),  to_signed(6602,16),   to_signed(-6278,16),  to_signed(6561,16),
        to_signed(9795,16),   to_signed(-894,16),   to_signed(-267,16),   to_signed(3643,16),
        to_signed(2573,16),   to_signed(-5851,16),  to_signed(2915,16),   to_signed(2471,16),
        to_signed(-1893,16),  to_signed(7930,16),   to_signed(-8351,16),  to_signed(-288,16),
        to_signed(-9266,16),  to_signed(3394,16),   to_signed(-4731,16),  to_signed(-6326,16),
        to_signed(6795,16),   to_signed(1610,16),   to_signed(-10848,16), to_signed(-6977,16),
        to_signed(4006,16),   to_signed(-3172,16),  to_signed(4799,16),   to_signed(8535,16),
        to_signed(-8233,16),  to_signed(-3861,16),  to_signed(3560,16),   to_signed(-1962,16),
        to_signed(-70,16),    to_signed(-10222,16), to_signed(-8254,16),  to_signed(-4629,16),
        to_signed(-4348,16),  to_signed(-6371,16),  to_signed(-11403,16), to_signed(8070,16),
        to_signed(7039,16),   to_signed(3621,16),   to_signed(-7870,16),  to_signed(-981,16),
        to_signed(2222,16),   to_signed(6615,16),   to_signed(9850,16),   to_signed(8004,16),
        to_signed(-879,16),   to_signed(236,16),    to_signed(1028,16),   to_signed(-983,16),
        to_signed(3930,16),   to_signed(5997,16),   to_signed(-6704,16),  to_signed(14541,16),
        to_signed(-310,16),   to_signed(4540,16),   to_signed(5908,16),   to_signed(-7817,16),
        to_signed(2653,16),   to_signed(10057,16),  to_signed(-5019,16),  to_signed(2493,16)
    );

    constant Wv : weight_array := (
        to_signed(19371,16),  to_signed(19048,16),  to_signed(2368,16),   to_signed(25375,16),
        to_signed(5357,16),   to_signed(-12534,16), to_signed(-25169,16), to_signed(3586,16),
        to_signed(-15055,16), to_signed(-23242,16), to_signed(-20441,16), to_signed(-14621,16),
        to_signed(-17957,16), to_signed(1508,16),   to_signed(18292,16),  to_signed(12363,16),
        to_signed(-18103,16), to_signed(-9427,16),  to_signed(-17771,16), to_signed(-15398,16),
        to_signed(-5764,16),  to_signed(13604,16),  to_signed(7060,16),   to_signed(18284,16),
        to_signed(-32768,16), to_signed(-4550,16),  to_signed(-8538,16),  to_signed(-17743,16),
        to_signed(-11648,16), to_signed(18079,16),  to_signed(11798,16),  to_signed(-3585,16),
        to_signed(-4402,16),  to_signed(-28475,16), to_signed(-21473,16), to_signed(4192,16),
        to_signed(-32768,16), to_signed(-19902,16), to_signed(-16907,16), to_signed(32266,16),
        to_signed(-10142,16), to_signed(-21741,16), to_signed(-10177,16), to_signed(-4134,16),
        to_signed(-19553,16), to_signed(-6840,16),  to_signed(6371,16),   to_signed(15645,16),
        to_signed(2942,16),   to_signed(-15644,16), to_signed(-15568,16), to_signed(18847,16),
        to_signed(-26219,16), to_signed(-19499,16), to_signed(-6941,16),  to_signed(25992,16),
        to_signed(9029,16),   to_signed(23717,16),  to_signed(6289,16),   to_signed(-8905,16),
        to_signed(22131,16),  to_signed(7112,16),   to_signed(12679,16),  to_signed(-22703,16)
    );

    -- Input storage
    type input_matrix is array(0 to 3, 0 to 7) of signed(15 downto 0);
    signal X_reg : input_matrix := (others => (others => (others => '0')));

    -- Output storage
    type output_matrix is array(0 to 3, 0 to 7) of signed(15 downto 0);
    signal Q_reg : output_matrix := (others => (others => (others => '0')));
    signal K_reg : output_matrix := (others => (others => (others => '0')));
    signal V_reg : output_matrix := (others => (others => (others => '0')));

    -- Accumulators
    signal acc_q : signed(31 downto 0) := (others => '0');
    signal acc_k : signed(31 downto 0) := (others => '0');
    signal acc_v : signed(31 downto 0) := (others => '0');

    -- FSM
    type state_type is (IDLE, LOAD_X, COMPUTE);
    signal state : state_type := IDLE;

    -- Counters
    signal load_row : integer range 0 to 4 := 0;
    signal load_col : integer range 0 to 8 := 0;
    signal comp_row : integer range 0 to 4 := 0;
    signal comp_col : integer range 0 to 8 := 0;
    signal elem_cnt : integer range 0 to 8 := 0;

    -- Output registers
    signal Q_out_reg : signed(15 downto 0) := (others => '0');
    signal K_out_reg : signed(15 downto 0) := (others => '0');
    signal V_out_reg : signed(15 downto 0) := (others => '0');
    signal valid_reg : std_logic := '0';
    signal done_reg  : std_logic := '0';

begin

    Q_out <= Q_out_reg;
    K_out <= K_out_reg;
    V_out <= V_out_reg;
    valid <= valid_reg;
    done  <= done_reg;

    process(clk)
    begin
        if rising_edge(clk) then

            valid_reg <= '0';
            done_reg  <= '0';

            if rst = '1' then
                state     <= IDLE;
                load_row  <= 0;
                load_col  <= 0;
                comp_row  <= 0;
                comp_col  <= 0;
                elem_cnt  <= 0;
                acc_q     <= (others => '0');
                acc_k     <= (others => '0');
                acc_v     <= (others => '0');
                Q_out_reg <= (others => '0');
                K_out_reg <= (others => '0');
                V_out_reg <= (others => '0');

            else
                case state is

                    when IDLE =>
                        if start = '1' then
                            state    <= LOAD_X;
                            load_row <= 0;
                            load_col <= 0;
                        end if;

                    when LOAD_X =>
                    -- store X_in into X_reg element by element
                        X_reg(load_row, load_col) <= X_in;

                        if load_col < 7 then
                            load_col <= load_col + 1;
                        elsif load_row < 3 then
                            load_col <= 0;
                            load_row <= load_row + 1;
                        else
                            -- all 32 elements loaded
                            state    <= COMPUTE;
                            comp_row <= 0;
                            comp_col <= 0;
                            elem_cnt <= 0;
                            acc_q    <= (others => '0');
                            acc_k    <= (others => '0');
                            acc_v    <= (others => '0');
                        end if;

                    when COMPUTE =>
                        if elem_cnt < 8 then
                            -- 3 DSP48E1 slices working simultaneously
                            acc_q <= acc_q + (X_reg(comp_row, elem_cnt) *
                                     Wq(elem_cnt * 8 + comp_col));
                            acc_k <= acc_k + (X_reg(comp_row, elem_cnt) *
                                     Wk(elem_cnt * 8 + comp_col));
                            acc_v <= acc_v + (X_reg(comp_row, elem_cnt) *
                                     Wv(elem_cnt * 8 + comp_col));
                            elem_cnt <= elem_cnt + 1;

                        else
                            -- store and output result
                            Q_reg(comp_row, comp_col) <= acc_q(30 downto 15);
                            K_reg(comp_row, comp_col) <= acc_k(30 downto 15);
                            V_reg(comp_row, comp_col) <= acc_v(30 downto 15);

                            Q_out_reg <= acc_q(30 downto 15);
                            K_out_reg <= acc_k(30 downto 15);
                            V_out_reg <= acc_v(30 downto 15);
                            out_row   <= comp_row;
                            out_col   <= comp_col;
                            valid_reg <= '1';

                            -- reset for next dot product
                            acc_q    <= (others => '0');
                            acc_k    <= (others => '0');
                            acc_v    <= (others => '0');
                            elem_cnt <= 0;

                            if comp_col < 7 then
                                comp_col <= comp_col + 1;
                            elsif comp_row < 3 then
                                comp_col <= 0;
                                comp_row <= comp_row + 1;
                            else
                                done_reg <= '1';
                                state    <= IDLE;
                            end if;

                        end if;

                    when others =>
                        state <= IDLE;

                end case;
            end if;
        end if;
    end process;

end Behavioral;