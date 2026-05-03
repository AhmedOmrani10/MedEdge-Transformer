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
        out_row : out integer range 0 to 15;
        out_col : out integer range 0 to 15;
        valid   : out std_logic;
        done    : out std_logic;
        Q_mat   : out matrix_16x16;
        K_mat   : out matrix_16x16;
        V_mat   : out matrix_16x16
    );
end qkv_projector;

architecture Behavioral of qkv_projector is

    type weight_array is array(0 to 255) of signed(15 downto 0);

    constant Wq : weight_array := (
        to_signed(1088,16), to_signed(-2012,16), to_signed(-2277,16), to_signed(3160,16), to_signed(3098,16), to_signed(-1766,16), to_signed(-2657,16), to_signed(3574,16),
        to_signed(-700,16), to_signed(-146,16), to_signed(1871,16), to_signed(1896,16), to_signed(2905,16), to_signed(-3779,16), to_signed(1786,16), to_signed(2902,16),
        to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16),
        to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16),
        to_signed(-911,16), to_signed(-687,16), to_signed(74,16), to_signed(-8192,16), to_signed(-2697,16), to_signed(2372,16), to_signed(694,16), to_signed(2054,16),
        to_signed(1437,16), to_signed(-272,16), to_signed(-4990,16), to_signed(-3796,16), to_signed(-690,16), to_signed(-4640,16), to_signed(-897,16), to_signed(-418,16),
        to_signed(0,16), to_signed(-241,16), to_signed(-45,16), to_signed(-312,16), to_signed(275,16), to_signed(-186,16), to_signed(-50,16), to_signed(512,16),
        to_signed(23,16), to_signed(-7,16), to_signed(18,16), to_signed(-39,16), to_signed(136,16), to_signed(-434,16), to_signed(-35,16), to_signed(200,16),
        to_signed(0,16), to_signed(-10,16), to_signed(-2,16), to_signed(-11,16), to_signed(12,16), to_signed(-8,16), to_signed(-2,16), to_signed(18,16),
        to_signed(1,16), to_signed(0,16), to_signed(2,16), to_signed(-1,16), to_signed(6,16), to_signed(-15,16), to_signed(-1,16), to_signed(8,16),
        to_signed(-11,16), to_signed(129,16), to_signed(31,16), to_signed(127,16), to_signed(-158,16), to_signed(106,16), to_signed(27,16), to_signed(-211,16),
        to_signed(-4,16), to_signed(3,16), to_signed(-33,16), to_signed(3,16), to_signed(-81,16), to_signed(192,16), to_signed(14,16), to_signed(-106,16),
        to_signed(-1008,16), to_signed(3833,16), to_signed(273,16), to_signed(-1886,16), to_signed(-5570,16), to_signed(2496,16), to_signed(440,16), to_signed(-4207,16),
        to_signed(601,16), to_signed(-112,16), to_signed(-2219,16), to_signed(-1270,16), to_signed(-2513,16), to_signed(4252,16), to_signed(258,16), to_signed(-2636,16),
        to_signed(-1143,16), to_signed(3776,16), to_signed(514,16), to_signed(-2606,16), to_signed(-5431,16), to_signed(2543,16), to_signed(711,16), to_signed(-4019,16),
        to_signed(713,16), to_signed(-87,16), to_signed(-2405,16), to_signed(-1564,16), to_signed(-2735,16), to_signed(4154,16), to_signed(-55,16), to_signed(-2737,16),
        to_signed(-1,16), to_signed(-4,16), to_signed(-1,16), to_signed(-9,16), to_signed(4,16), to_signed(-3,16), to_signed(-1,16), to_signed(8,16),
        to_signed(1,16), to_signed(0,16), to_signed(-1,16), to_signed(-2,16), to_signed(2,16), to_signed(-7,16), to_signed(-1,16), to_signed(3,16),
        to_signed(1381,16), to_signed(8,16), to_signed(202,16), to_signed(8192,16), to_signed(1550,16), to_signed(545,16), to_signed(6061,16), to_signed(-7528,16),
        to_signed(-1728,16), to_signed(-114,16), to_signed(2885,16), to_signed(3280,16), to_signed(137,16), to_signed(6594,16), to_signed(410,16), to_signed(-2294,16),
        to_signed(1322,16), to_signed(1235,16), to_signed(-2272,16), to_signed(8192,16), to_signed(315,16), to_signed(-1249,16), to_signed(-3025,16), to_signed(-457,16),
        to_signed(-1169,16), to_signed(-405,16), to_signed(6053,16), to_signed(4716,16), to_signed(3420,16), to_signed(4134,16), to_signed(4225,16), to_signed(-401,16),
        to_signed(-224,16), to_signed(-7,16), to_signed(-8,16), to_signed(-2534,16), to_signed(-126,16), to_signed(-51,16), to_signed(-138,16), to_signed(1159,16),
        to_signed(329,16), to_signed(-39,16), to_signed(-591,16), to_signed(-610,16), to_signed(-183,16), to_signed(-224,16), to_signed(-259,16), to_signed(-138,16),
        to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16),
        to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16),
        to_signed(-14,16), to_signed(168,16), to_signed(37,16), to_signed(122,16), to_signed(-202,16), to_signed(124,16), to_signed(38,16), to_signed(-337,16),
        to_signed(-3,16), to_signed(3,16), to_signed(-41,16), to_signed(0,16), to_signed(-105,16), to_signed(287,16), to_signed(18,16), to_signed(-148,16),
        to_signed(-866,16), to_signed(2013,16), to_signed(1990,16), to_signed(-1919,16), to_signed(-2975,16), to_signed(1759,16), to_signed(2316,16), to_signed(-4129,16),
        to_signed(511,16), to_signed(115,16), to_signed(-1533,16), to_signed(-1439,16), to_signed(-2627,16), to_signed(4127,16), to_signed(-1370,16), to_signed(-2857,16),
        to_signed(-280,16), to_signed(1221,16), to_signed(-215,16), to_signed(-8192,16), to_signed(-3450,16), to_signed(1907,16), to_signed(2090,16), to_signed(2591,16),
        to_signed(1482,16), to_signed(-232,16), to_signed(-4963,16), to_signed(-3523,16), to_signed(-1673,16), to_signed(-4907,16), to_signed(-722,16), to_signed(1592,16)
    );

    constant Wk : weight_array := (
        to_signed(742,16), to_signed(-5678,16), to_signed(3118,16), to_signed(-3356,16), to_signed(8117,16), to_signed(-4005,16), to_signed(800,16), to_signed(2454,16),
        to_signed(520,16), to_signed(1486,16), to_signed(1486,16), to_signed(-1977,16), to_signed(157,16), to_signed(-1357,16), to_signed(-3497,16), to_signed(-574,16),
        to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16),
        to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16),
        to_signed(-259,16), to_signed(648,16), to_signed(2733,16), to_signed(1533,16), to_signed(-704,16), to_signed(1150,16), to_signed(4189,16), to_signed(-4093,16),
        to_signed(-147,16), to_signed(285,16), to_signed(272,16), to_signed(-233,16), to_signed(-2028,16), to_signed(3558,16), to_signed(-1718,16), to_signed(-3596,16),
        to_signed(-10,16), to_signed(-297,16), to_signed(261,16), to_signed(-208,16), to_signed(396,16), to_signed(-59,16), to_signed(306,16), to_signed(-106,16),
        to_signed(12,16), to_signed(64,16), to_signed(99,16), to_signed(-125,16), to_signed(-108,16), to_signed(63,16), to_signed(-319,16), to_signed(-95,16),
        to_signed(0,16), to_signed(-13,16), to_signed(11,16), to_signed(-8,16), to_signed(18,16), to_signed(-3,16), to_signed(13,16), to_signed(-3,16),
        to_signed(0,16), to_signed(3,16), to_signed(4,16), to_signed(-5,16), to_signed(-4,16), to_signed(2,16), to_signed(-13,16), to_signed(-3,16),
        to_signed(4,16), to_signed(167,16), to_signed(-158,16), to_signed(110,16), to_signed(-243,16), to_signed(47,16), to_signed(-151,16), to_signed(40,16),
        to_signed(-7,16), to_signed(-37,16), to_signed(-56,16), to_signed(63,16), to_signed(48,16), to_signed(14,16), to_signed(167,16), to_signed(36,16),
        to_signed(-800,16), to_signed(5303,16), to_signed(-805,16), to_signed(3683,16), to_signed(-8192,16), to_signed(3702,16), to_signed(-1825,16), to_signed(-2523,16),
        to_signed(-502,16), to_signed(-1431,16), to_signed(-1664,16), to_signed(2093,16), to_signed(-611,16), to_signed(845,16), to_signed(2461,16), to_signed(1470,16),
        to_signed(-825,16), to_signed(5096,16), to_signed(-4821,16), to_signed(3636,16), to_signed(-8192,16), to_signed(2734,16), to_signed(-1838,16), to_signed(-3365,16),
        to_signed(-290,16), to_signed(-1283,16), to_signed(-1624,16), to_signed(1771,16), to_signed(-280,16), to_signed(2679,16), to_signed(3331,16), to_signed(97,16),
        to_signed(0,16), to_signed(-4,16), to_signed(5,16), to_signed(-3,16), to_signed(6,16), to_signed(0,16), to_signed(7,16), to_signed(-4,16),
        to_signed(0,16), to_signed(1,16), to_signed(1,16), to_signed(-2,16), to_signed(-3,16), to_signed(3,16), to_signed(-6,16), to_signed(-3,16),
        to_signed(1572,16), to_signed(-8192,16), to_signed(7659,16), to_signed(-2198,16), to_signed(8192,16), to_signed(-6240,16), to_signed(5891,16), to_signed(6669,16),
        to_signed(-206,16), to_signed(1099,16), to_signed(3121,16), to_signed(-2384,16), to_signed(1713,16), to_signed(-4959,16), to_signed(-7861,16), to_signed(-1516,16),
        to_signed(148,16), to_signed(254,16), to_signed(-2514,16), to_signed(-1111,16), to_signed(-223,16), to_signed(-668,16), to_signed(-4832,16), to_signed(5625,16),
        to_signed(154,16), to_signed(-378,16), to_signed(-498,16), to_signed(432,16), to_signed(1942,16), to_signed(-4735,16), to_signed(2100,16), to_signed(2723,16),
        to_signed(-105,16), to_signed(44,16), to_signed(899,16), to_signed(48,16), to_signed(-17,16), to_signed(370,16), to_signed(1071,16), to_signed(-1264,16),
        to_signed(26,16), to_signed(154,16), to_signed(3,16), to_signed(-320,16), to_signed(-697,16), to_signed(990,16), to_signed(-759,16), to_signed(-806,16),
        to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16),
        to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16), to_signed(0,16),
        to_signed(4,16), to_signed(199,16), to_signed(-147,16), to_signed(145,16), to_signed(-295,16), to_signed(61,16), to_signed(-152,16), to_signed(37,16),
        to_signed(-8,16), to_signed(-48,16), to_signed(-77,16), to_signed(75,16), to_signed(51,16), to_signed(-4,16), to_signed(177,16), to_signed(44,16),
        to_signed(-1622,16), to_signed(5378,16), to_signed(-3243,16), to_signed(3237,16), to_signed(-8049,16), to_signed(3673,16), to_signed(-2637,16), to_signed(-1215,16),
        to_signed(-391,16), to_signed(-1503,16), to_signed(-1434,16), to_signed(1678,16), to_signed(-1682,16), to_signed(1884,16), to_signed(1183,16), to_signed(1985,16),
        to_signed(-283,16), to_signed(729,16), to_signed(2934,16), to_signed(1680,16), to_signed(-767,16), to_signed(1182,16), to_signed(3087,16), to_signed(-5219,16),
        to_signed(-162,16), to_signed(280,16), to_signed(303,16), to_signed(-192,16), to_signed(-2053,16), to_signed(3832,16), to_signed(-1975,16), to_signed(-2340,16)
    );

    constant Wv : weight_array := (
        to_signed(-4002,16), to_signed(-245,16), to_signed(3014,16), to_signed(1229,16), to_signed(-4157,16), to_signed(2090,16), to_signed(2241,16), to_signed(-3705,16),
        to_signed(-502,16), to_signed(-1864,16), to_signed(1876,16), to_signed(177,16), to_signed(-4596,16), to_signed(4437,16), to_signed(-2686,16), to_signed(-1048,16),
        to_signed(-783,16), to_signed(-4236,16), to_signed(10107,16), to_signed(-53,16), to_signed(-931,16), to_signed(-703,16), to_signed(10597,16), to_signed(-6069,16),
        to_signed(1662,16), to_signed(1354,16), to_signed(-2732,16), to_signed(-3272,16), to_signed(-4880,16), to_signed(819,16), to_signed(-8019,16), to_signed(-7643,16),
        to_signed(1317,16), to_signed(1310,16), to_signed(-1035,16), to_signed(6151,16), to_signed(-5024,16), to_signed(-2426,16), to_signed(1823,16), to_signed(-5293,16),
        to_signed(-1421,16), to_signed(3724,16), to_signed(-2386,16), to_signed(764,16), to_signed(967,16), to_signed(1128,16), to_signed(2795,16), to_signed(-5035,16),
        to_signed(-2917,16), to_signed(3547,16), to_signed(-2418,16), to_signed(-667,16), to_signed(-1079,16), to_signed(2520,16), to_signed(2222,16), to_signed(-2995,16),
        to_signed(294,16), to_signed(-1002,16), to_signed(141,16), to_signed(224,16), to_signed(-1621,16), to_signed(3606,16), to_signed(3093,16), to_signed(36,16),
        to_signed(-1141,16), to_signed(426,16), to_signed(-8430,16), to_signed(11373,16), to_signed(-6766,16), to_signed(812,16), to_signed(-6616,16), to_signed(-3423,16),
        to_signed(-3030,16), to_signed(-2356,16), to_signed(5087,16), to_signed(7902,16), to_signed(2082,16), to_signed(-2683,16), to_signed(7750,16), to_signed(209,16),
        to_signed(2812,16), to_signed(-1667,16), to_signed(-6468,16), to_signed(9620,16), to_signed(3980,16), to_signed(-2106,16), to_signed(-6420,16), to_signed(2591,16),
        to_signed(-1537,16), to_signed(-343,16), to_signed(4020,16), to_signed(5713,16), to_signed(5723,16), to_signed(-4747,16), to_signed(5892,16), to_signed(4786,16),
        to_signed(-5378,16), to_signed(4010,16), to_signed(-842,16), to_signed(-5091,16), to_signed(-597,16), to_signed(4479,16), to_signed(5310,16), to_signed(-9982,16),
        to_signed(4412,16), to_signed(4265,16), to_signed(-1859,16), to_signed(-3291,16), to_signed(-7744,16), to_signed(10337,16), to_signed(-5166,16), to_signed(-5378,16),
        to_signed(-4403,16), to_signed(1005,16), to_signed(358,16), to_signed(-3229,16), to_signed(-4629,16), to_signed(1930,16), to_signed(9105,16), to_signed(-11344,16),
        to_signed(2012,16), to_signed(438,16), to_signed(-2748,16), to_signed(-1313,16), to_signed(-10388,16), to_signed(8299,16), to_signed(-5095,16), to_signed(-8296,16),
        to_signed(1271,16), to_signed(1761,16), to_signed(224,16), to_signed(6682,16), to_signed(2029,16), to_signed(-238,16), to_signed(-1757,16), to_signed(-1357,16),
        to_signed(-979,16), to_signed(-299,16), to_signed(1893,16), to_signed(2428,16), to_signed(2051,16), to_signed(2095,16), to_signed(1680,16), to_signed(-328,16),
        to_signed(-857,16), to_signed(1359,16), to_signed(1921,16), to_signed(-3531,16), to_signed(-1216,16), to_signed(-4,16), to_signed(2712,16), to_signed(-448,16),
        to_signed(716,16), to_signed(373,16), to_signed(-1168,16), to_signed(-2142,16), to_signed(-2255,16), to_signed(3397,16), to_signed(-139,16), to_signed(-2115,16),
        to_signed(-2552,16), to_signed(3974,16), to_signed(1664,16), to_signed(3216,16), to_signed(-9408,16), to_signed(6048,16), to_signed(595,16), to_signed(-6862,16),
        to_signed(1977,16), to_signed(-1144,16), to_signed(624,16), to_signed(-903,16), to_signed(-4920,16), to_signed(7677,16), to_signed(1350,16), to_signed(-3186,16),
        to_signed(-2440,16), to_signed(1905,16), to_signed(1679,16), to_signed(3362,16), to_signed(-2816,16), to_signed(-3061,16), to_signed(8029,16), to_signed(-1045,16),
        to_signed(659,16), to_signed(4975,16), to_signed(-1744,16), to_signed(-1493,16), to_signed(-612,16), to_signed(2367,16), to_signed(-2214,16), to_signed(-6510,16),
        to_signed(496,16), to_signed(453,16), to_signed(-1935,16), to_signed(5663,16), to_signed(4186,16), to_signed(2886,16), to_signed(3947,16), to_signed(-6448,16),
        to_signed(-313,16), to_signed(2114,16), to_signed(383,16), to_signed(1824,16), to_signed(-1638,16), to_signed(6203,16), to_signed(-519,16), to_signed(-1258,16),
        to_signed(-5658,16), to_signed(3844,16), to_signed(5758,16), to_signed(11449,16), to_signed(-8738,16), to_signed(7129,16), to_signed(7397,16), to_signed(-11469,16),
        to_signed(3555,16), to_signed(-2701,16), to_signed(1606,16), to_signed(-1356,16), to_signed(-10561,16), to_signed(11469,16), to_signed(-933,16), to_signed(-11469,16),
        to_signed(-4468,16), to_signed(2192,16), to_signed(2092,16), to_signed(751,16), to_signed(1012,16), to_signed(2297,16), to_signed(4577,16), to_signed(-3627,16),
        to_signed(-148,16), to_signed(-1338,16), to_signed(-3604,16), to_signed(-4065,16), to_signed(-2830,16), to_signed(947,16), to_signed(-1901,16), to_signed(-5505,16),
        to_signed(1263,16), to_signed(2362,16), to_signed(2550,16), to_signed(4492,16), to_signed(-1739,16), to_signed(-5157,16), to_signed(3202,16), to_signed(-1678,16),
        to_signed(1109,16), to_signed(1229,16), to_signed(-1712,16), to_signed(-283,16), to_signed(-3521,16), to_signed(5606,16), to_signed(-5761,16), to_signed(-5420,16)
    );

    type input_matrix is array(0 to 15, 0 to 15) of signed(15 downto 0);
    signal X_reg : input_matrix := (others => (others => (others => '0')));
    signal Q_reg : matrix_16x16 := (others => (others => (others => '0')));
    signal K_reg : matrix_16x16 := (others => (others => (others => '0')));
    signal V_reg : matrix_16x16 := (others => (others => (others => '0')));

    signal acc_q : signed(39 downto 0) := (others => '0');
    signal acc_k : signed(39 downto 0) := (others => '0');
    signal acc_v : signed(39 downto 0) := (others => '0');

    type state_type is (IDLE, LOAD_X, COMPUTE);
    signal state    : state_type := IDLE;
    signal load_row : integer range 0 to 16 := 0;
    signal load_col : integer range 0 to 16 := 0;
    signal comp_row : integer range 0 to 16 := 0;
    signal comp_col : integer range 0 to 16 := 0;
    signal elem_cnt : integer range 0 to 16 := 0;

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
        variable vq    : signed(15 downto 0);
        variable vk    : signed(15 downto 0);
        variable vv    : signed(15 downto 0);
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
                        if load_col < 15 then
                            load_col <= load_col + 1;
                        elsif load_row < 15 then
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
                        if elem_cnt < 16 then
                            -- 40-bit accumulation using to_integer to prevent overflow
                            acc_q <= acc_q + to_signed(
                                to_integer(X_reg(comp_row, elem_cnt)) *
                                to_integer(Wq(comp_col * 16 + elem_cnt)), 40);
                            acc_k <= acc_k + to_signed(
                                to_integer(X_reg(comp_row, elem_cnt)) *
                                to_integer(Wk(comp_col * 16 + elem_cnt)), 40);
                            acc_v <= acc_v + to_signed(
                                to_integer(X_reg(comp_row, elem_cnt)) *
                                to_integer(Wv(comp_col * 16 + elem_cnt)), 40);
                            elem_cnt <= elem_cnt + 1;
                        else
                            -- Saturate Q to Q1.15
                            raw_q := to_integer(acc_q(39 downto 15));
                            if raw_q > 32767 then
                                vq := to_signed(32767, 16);
                            elsif raw_q < -32768 then
                                vq := to_signed(-32768, 16);
                            else
                                vq := acc_q(30 downto 15);
                            end if;

                            -- Saturate K to Q1.15
                            raw_k := to_integer(acc_k(39 downto 15));
                            if raw_k > 32767 then
                                vk := to_signed(32767, 16);
                            elsif raw_k < -32768 then
                                vk := to_signed(-32768, 16);
                            else
                                vk := acc_k(30 downto 15);
                            end if;

                            -- Saturate V to Q1.15
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

                            if comp_col < 15 then
                                comp_col <= comp_col + 1;
                            elsif comp_row < 15 then
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
