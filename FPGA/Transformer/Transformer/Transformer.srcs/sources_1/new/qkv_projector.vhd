library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.transformer_pkg.all;

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
        done    : out std_logic;
        Q_mat   : out matrix_4x8;
        K_mat   : out matrix_4x8;
        V_mat   : out matrix_4x8
    );
end qkv_projector;

architecture Behavioral of qkv_projector is

    type weight_array is array(0 to 63) of signed(15 downto 0);

    constant Wq : weight_array := (
        to_signed(8669,16),  to_signed(3118,16),  to_signed(-726,16),  to_signed(2292,16),
        to_signed(350,16),   to_signed(-7721,16), to_signed(-7697,16), to_signed(3908,16),
        to_signed(7107,16),  to_signed(119,16),   to_signed(-3557,16), to_signed(-1520,16),
        to_signed(1746,16),  to_signed(-4820,16), to_signed(-3997,16), to_signed(4662,16),
        to_signed(-3882,16), to_signed(-261,16),  to_signed(733,16),   to_signed(2764,16),
        to_signed(882,16),   to_signed(4262,16),  to_signed(4480,16),  to_signed(-2585,16),
        to_signed(5899,16),  to_signed(-572,16),  to_signed(-761,16),  to_signed(-3367,16),
        to_signed(-4571,16), to_signed(-6779,16), to_signed(-1049,16), to_signed(443,16),
        to_signed(6797,16),  to_signed(2304,16),  to_signed(-1158,16), to_signed(-3124,16),
        to_signed(-3152,16), to_signed(-7089,16), to_signed(-3380,16), to_signed(3087,16),
        to_signed(-7870,16), to_signed(-3070,16), to_signed(967,16),   to_signed(-3122,16),
        to_signed(1993,16),  to_signed(7110,16),  to_signed(4363,16),  to_signed(-3902,16),
        to_signed(7551,16),  to_signed(1181,16),  to_signed(497,16),   to_signed(-686,16),
        to_signed(-2796,16), to_signed(-7866,16), to_signed(-5781,16), to_signed(-292,16),
        to_signed(7307,16),  to_signed(3345,16),  to_signed(-429,16),  to_signed(-339,16),
        to_signed(-3003,16), to_signed(-8297,16), to_signed(-3180,16), to_signed(2948,16)
    );

    constant Wk : weight_array := (
        to_signed(-3466,16), to_signed(7467,16),  to_signed(660,16),   to_signed(2133,16),
        to_signed(2828,16),  to_signed(-959,16),  to_signed(-2757,16), to_signed(-4267,16),
        to_signed(-2838,16), to_signed(1948,16),  to_signed(624,16),   to_signed(3401,16),
        to_signed(276,16),   to_signed(145,16),   to_signed(-480,16),  to_signed(-2278,16),
        to_signed(3320,16),  to_signed(530,16),   to_signed(528,16),   to_signed(-2568,16),
        to_signed(-1760,16), to_signed(-1479,16), to_signed(1222,16),  to_signed(140,16),
        to_signed(-2697,16), to_signed(-2178,16), to_signed(2278,16),  to_signed(99,16),
        to_signed(-1990,16), to_signed(-1009,16), to_signed(2273,16),  to_signed(-2451,16),
        to_signed(-4152,16), to_signed(2408,16),  to_signed(-1289,16), to_signed(-1956,16),
        to_signed(2397,16),  to_signed(-47,16),   to_signed(-392,16),  to_signed(-1090,16),
        to_signed(6486,16),  to_signed(-3124,16), to_signed(494,16),   to_signed(-2965,16),
        to_signed(-1702,16), to_signed(971,16),   to_signed(3533,16),  to_signed(1208,16),
        to_signed(-2368,16), to_signed(3518,16),  to_signed(-652,16),  to_signed(648,16),
        to_signed(2439,16),  to_signed(-1458,16), to_signed(-2219,16), to_signed(-4977,16),
        to_signed(-5969,16), to_signed(539,16),   to_signed(-1967,16), to_signed(185,16),
        to_signed(2666,16),  to_signed(-217,16),  to_signed(-4259,16), to_signed(57,16)
    );

    constant Wv : weight_array := (
        to_signed(-9593,16),  to_signed(11531,16),  to_signed(4422,16),   to_signed(5124,16),
        to_signed(8681,16),   to_signed(12120,16),  to_signed(-12230,16), to_signed(-13524,16),
        to_signed(16589,16),  to_signed(-16561,16), to_signed(-16558,16), to_signed(-16571,16),
        to_signed(-16578,16), to_signed(-16566,16), to_signed(16558,16),  to_signed(16587,16),
        to_signed(-5865,16),  to_signed(7260,16),   to_signed(5781,16),   to_signed(12970,16),
        to_signed(15001,16),  to_signed(11474,16),  to_signed(-499,16),   to_signed(-9778,16),
        to_signed(-8883,16),  to_signed(6360,16),   to_signed(7478,16),   to_signed(10740,16),
        to_signed(9277,16),   to_signed(4457,16),   to_signed(-14069,16), to_signed(-6666,16),
        to_signed(-16542,16), to_signed(16485,16),  to_signed(16489,16),  to_signed(16496,16),
        to_signed(16500,16),  to_signed(16515,16),  to_signed(-16484,16), to_signed(-16512,16),
        to_signed(16426,16),  to_signed(-7160,16),  to_signed(-10596,16), to_signed(-14467,16),
        to_signed(-15946,16), to_signed(-16432,16), to_signed(9366,16),   to_signed(16471,16),
        to_signed(8954,16),   to_signed(-8088,16),  to_signed(-8831,16),  to_signed(-1325,16),
        to_signed(-1286,16),  to_signed(-10357,16), to_signed(2260,16),   to_signed(9935,16),
        to_signed(16552,16),  to_signed(-16516,16), to_signed(-16518,16), to_signed(-16526,16),
        to_signed(-16529,16), to_signed(-16532,16), to_signed(16516,16),  to_signed(16539,16)
    );

    type input_matrix is array(0 to 3, 0 to 7) of signed(15 downto 0);
    signal X_reg : input_matrix := (others => (others => (others => '0')));
    signal Q_reg : matrix_4x8  := (others => (others => (others => '0')));
    signal K_reg : matrix_4x8  := (others => (others => (others => '0')));
    signal V_reg : matrix_4x8  := (others => (others => (others => '0')));

    signal acc_q : signed(39 downto 0) := (others => '0');
    signal acc_k : signed(39 downto 0) := (others => '0');
    signal acc_v : signed(39 downto 0) := (others => '0');

    type state_type is (IDLE, LOAD_X, COMPUTE);
    signal state    : state_type := IDLE;
    signal load_row : integer range 0 to 4 := 0;
    signal load_col : integer range 0 to 8 := 0;
    signal comp_row : integer range 0 to 4 := 0;
    signal comp_col : integer range 0 to 8 := 0;
    signal elem_cnt : integer range 0 to 8 := 0;

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
    Q_mat <= Q_reg;
    K_mat <= K_reg;
    V_mat <= V_reg;

    process(clk)
        variable raw_q : integer;
        variable raw_k : integer;
        variable raw_v : integer;
        variable vq : signed(15 downto 0);
        variable vk : signed(15 downto 0);
        variable vv : signed(15 downto 0);
    begin
        if rising_edge(clk) then
            valid_reg <= '0';
            done_reg  <= '0';

            if rst = '1' then
                state     <= IDLE;
                load_row  <= 0; load_col  <= 0;
                comp_row  <= 0; comp_col  <= 0; elem_cnt  <= 0;
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
                        X_reg(load_row, load_col) <= X_in;
                        if load_col < 7 then
                            load_col <= load_col + 1;
                        elsif load_row < 3 then
                            load_col <= 0;
                            load_row <= load_row + 1;
                        else
                            state    <= COMPUTE;
                            comp_row <= 0; comp_col <= 0; elem_cnt <= 0;
                            acc_q    <= (others => '0');
                            acc_k    <= (others => '0');
                            acc_v    <= (others => '0');
                        end if;

                    when COMPUTE =>
                        if elem_cnt < 8 then
                            acc_q <= acc_q + to_signed(
                                to_integer(X_reg(comp_row, elem_cnt)) *
                                to_integer(Wq(comp_col * 8 + elem_cnt)), 40);
                            acc_k <= acc_k + to_signed(
                                to_integer(X_reg(comp_row, elem_cnt)) *
                                to_integer(Wk(comp_col * 8 + elem_cnt)), 40);
                            acc_v <= acc_v + to_signed(
                                to_integer(X_reg(comp_row, elem_cnt)) *
                                to_integer(Wv(comp_col * 8 + elem_cnt)), 40);
                            elem_cnt <= elem_cnt + 1;
                        else
                            -- Saturate Q
                            raw_q := to_integer(acc_q(39 downto 15));
                            if raw_q > 32767 then
                                vq := to_signed(32767, 16);
                            elsif raw_q < -32768 then
                                vq := to_signed(-32768, 16);
                            else
                                vq := acc_q(30 downto 15);
                            end if;

                            -- Saturate K
                            raw_k := to_integer(acc_k(39 downto 15));
                            if raw_k > 32767 then
                                vk := to_signed(32767, 16);
                            elsif raw_k < -32768 then
                                vk := to_signed(-32768, 16);
                            else
                                vk := acc_k(30 downto 15);
                            end if;

                            -- Saturate V
                            raw_v := to_integer(acc_v(39 downto 15));
                            if raw_v > 32767 then
                                vv := to_signed(32767, 16);
                            elsif raw_v < -32768 then
                                vv := to_signed(-32768, 16);
                            else
                                vv := acc_v(30 downto 15);
                            end if;

                            Q_reg(comp_row, comp_col) <= vq;
                            K_reg(comp_row, comp_col) <= vk;
                            V_reg(comp_row, comp_col) <= vv;
                            Q_out_reg <= vq;
                            K_out_reg <= vk;
                            V_out_reg <= vv;
                            out_row   <= comp_row;
                            out_col   <= comp_col;
                            valid_reg <= '1';

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
