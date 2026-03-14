library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.transformer_pkg.all;

entity feed_forward is
    port (
        clk    : in  std_logic;
        rst    : in  std_logic;
        start  : in  std_logic;
        X_in   : in  matrix_4x8;
        Y_out  : out matrix_4x8;
        done   : out std_logic
    );
end feed_forward;

architecture Behavioral of feed_forward is

    type weight_16x8 is array(0 to 127) of signed(15 downto 0);
    type weight_8x16 is array(0 to 127) of signed(15 downto 0);
    type bias_16     is array(0 to 15)  of signed(15 downto 0);
    type bias_8      is array(0 to 7)   of signed(15 downto 0);

    constant FF1_W : weight_16x8 := (
        to_signed(28071,16), to_signed(25168,16), to_signed(32765,16), to_signed(29079,16),
        to_signed(32765,16), to_signed(21898,16), to_signed(-27938,16),to_signed(32765,16),
        to_signed(32765,16), to_signed(8721,16),  to_signed(27122,16), to_signed(11239,16),
        to_signed(22163,16), to_signed(-4502,16), to_signed(-29100,16),to_signed(32765,16),
        to_signed(31915,16), to_signed(-5543,16), to_signed(-5258,16), to_signed(32765,16),
        to_signed(-1770,16), to_signed(-32768,16),to_signed(-5117,16), to_signed(3972,16),
        to_signed(22685,16), to_signed(-16931,16),to_signed(-6208,16), to_signed(21143,16),
        to_signed(-3818,16), to_signed(-23432,16),to_signed(-18368,16),to_signed(15812,16),
        to_signed(-8892,16), to_signed(-4024,16), to_signed(8455,16),  to_signed(-565,16),
        to_signed(7174,16),  to_signed(-415,16),  to_signed(10375,16), to_signed(-6482,16),
        to_signed(-2002,16), to_signed(-310,16),  to_signed(8848,16),  to_signed(11313,16),
        to_signed(-6469,16), to_signed(-4882,16), to_signed(4041,16),  to_signed(-9686,16),
        to_signed(-17873,16),to_signed(2779,16),  to_signed(-14344,16),to_signed(-15671,16),
        to_signed(7776,16),  to_signed(8666,16),  to_signed(5342,16),  to_signed(-14876,16),
        to_signed(1448,16),  to_signed(-5969,16), to_signed(-12321,16),to_signed(9545,16),
        to_signed(-11440,16),to_signed(4854,16),  to_signed(8395,16),  to_signed(892,16),
        to_signed(-11926,16),to_signed(-1267,16), to_signed(1778,16),  to_signed(-13609,16),
        to_signed(1328,16),  to_signed(4713,16),  to_signed(10096,16), to_signed(-7772,16),
        to_signed(27962,16), to_signed(6221,16),  to_signed(7535,16),  to_signed(29490,16),
        to_signed(11803,16), to_signed(-9236,16), to_signed(-1784,16), to_signed(10194,16),
        to_signed(-14481,16),to_signed(-9692,16), to_signed(3378,16),  to_signed(2835,16),
        to_signed(648,16),   to_signed(10101,16), to_signed(8370,16),  to_signed(5253,16),
        to_signed(-2446,16), to_signed(-14920,16),to_signed(-18675,16),to_signed(-8215,16),
        to_signed(-7310,16), to_signed(1858,16),  to_signed(14083,16), to_signed(-9543,16),
        to_signed(26160,16), to_signed(20495,16), to_signed(19039,16), to_signed(19122,16),
        to_signed(21044,16), to_signed(-1718,16), to_signed(-31628,16),to_signed(19778,16),
        to_signed(76,16),    to_signed(16318,16), to_signed(18686,16), to_signed(-10134,16),
        to_signed(4934,16),  to_signed(17294,16), to_signed(-11075,16),to_signed(19262,16),
        to_signed(32765,16), to_signed(29485,16), to_signed(32765,16), to_signed(31690,16),
        to_signed(28546,16), to_signed(1658,16),  to_signed(-32768,16),to_signed(27248,16),
        to_signed(-6675,16), to_signed(139,16),   to_signed(8487,16),  to_signed(-395,16),
        to_signed(4151,16),  to_signed(-4490,16), to_signed(7753,16),  to_signed(2788,16)
    );

    constant FF1_B : bias_16 := (
        to_signed(29791,16), to_signed(9586,16),  to_signed(-22348,16),to_signed(-11228,16),
        to_signed(-782,16),  to_signed(-11369,16),to_signed(10313,16), to_signed(7850,16),
        to_signed(1219,16),  to_signed(-9982,16), to_signed(16953,16), to_signed(375,16),
        to_signed(6207,16),  to_signed(7811,16),  to_signed(14413,16), to_signed(-11931,16)
    );

    constant FF2_W : weight_8x16 := (
        to_signed(-30637,16),to_signed(11634,16), to_signed(32765,16), to_signed(-32768,16),
        to_signed(-1459,16), to_signed(-6264,16), to_signed(3296,16),  to_signed(214,16),
        to_signed(-5954,16), to_signed(32765,16), to_signed(-1323,16), to_signed(-11633,16),
        to_signed(13721,16), to_signed(18592,16), to_signed(21925,16), to_signed(-159,16),
        to_signed(-1712,16), to_signed(-9673,16), to_signed(-32768,16),to_signed(25803,16),
        to_signed(-687,16),  to_signed(501,16),   to_signed(16932,16), to_signed(12314,16),
        to_signed(18083,16), to_signed(-7204,16), to_signed(-15059,16),to_signed(28383,16),
        to_signed(-9168,16), to_signed(-2942,16), to_signed(218,16),   to_signed(6409,16),
        to_signed(-12458,16),to_signed(-8121,16), to_signed(-32768,16),to_signed(32765,16),
        to_signed(102,16),   to_signed(-6789,16), to_signed(10656,16), to_signed(-5637,16),
        to_signed(15167,16), to_signed(-11259,16),to_signed(-12385,16),to_signed(6696,16),
        to_signed(-1143,16), to_signed(-7244,16), to_signed(24766,16), to_signed(-5842,16),
        to_signed(-27654,16),to_signed(16782,16), to_signed(27147,16), to_signed(-19571,16),
        to_signed(-9981,16), to_signed(-5403,16), to_signed(-11114,16),to_signed(-7108,16),
        to_signed(-1047,16), to_signed(26244,16), to_signed(7807,16),  to_signed(-14590,16),
        to_signed(17707,16), to_signed(17745,16), to_signed(32765,16), to_signed(1699,16),
        to_signed(4285,16),  to_signed(-884,16),  to_signed(-32768,16),to_signed(32765,16),
        to_signed(-9040,16), to_signed(969,16),   to_signed(2421,16),  to_signed(-10288,16),
        to_signed(6997,16),  to_signed(-12064,16),to_signed(-15270,16),to_signed(16941,16),
        to_signed(-7424,16), to_signed(3014,16),  to_signed(6652,16),  to_signed(2360,16),
        to_signed(14410,16), to_signed(8288,16),  to_signed(32765,16), to_signed(-28881,16),
        to_signed(-8342,16), to_signed(-6411,16), to_signed(-9838,16), to_signed(-3535,16),
        to_signed(-7975,16), to_signed(1522,16),  to_signed(6279,16),  to_signed(-5581,16),
        to_signed(3697,16),  to_signed(5840,16),  to_signed(-13614,16),to_signed(5645,16),
        to_signed(-30675,16),to_signed(23173,16), to_signed(32765,16), to_signed(-21721,16),
        to_signed(-9133,16), to_signed(-4178,16), to_signed(-5970,16), to_signed(-1696,16),
        to_signed(-4239,16), to_signed(28384,16), to_signed(6132,16),  to_signed(-15755,16),
        to_signed(16335,16), to_signed(22567,16), to_signed(32161,16), to_signed(-4132,16),
        to_signed(-32768,16),to_signed(31681,16), to_signed(-32768,16),to_signed(32765,16),
        to_signed(7689,16),  to_signed(-3446,16), to_signed(5346,16),  to_signed(-6442,16),
        to_signed(-507,16),  to_signed(11250,16), to_signed(6388,16),  to_signed(-1527,16),
        to_signed(29671,16), to_signed(20913,16), to_signed(32765,16), to_signed(581,16)
    );

    constant FF2_B : bias_8 := (
        to_signed(9032,16),  to_signed(-11147,16),to_signed(-2655,16), to_signed(9919,16),
        to_signed(-14851,16),to_signed(-2730,16), to_signed(9083,16),  to_signed(-13,16)
    );

    type matrix_4x16 is array(0 to 3, 0 to 15) of signed(15 downto 0);
    signal H_reg    : matrix_4x16 := (others => (others => (others => '0')));
    signal FF_reg   : matrix_4x8  := (others => (others => (others => '0')));
    signal acc      : signed(31 downto 0) := (others => '0');

    type state_t is (IDLE, FF1_COMPUTE, FF2_COMPUTE, OUTPUT);
    signal state    : state_t := IDLE;

    signal comp_row : integer range 0 to 4  := 0;
    signal comp_col : integer range 0 to 16 := 0;
    signal elem_cnt : integer range 0 to 16 := 0;
    signal done_reg : std_logic := '0';

begin

    done  <= done_reg;
    Y_out <= FF_reg;

    process(clk)
        variable result : signed(15 downto 0);
    begin
        if rising_edge(clk) then

            done_reg <= '0';

            if rst = '1' then
                state    <= IDLE;
                comp_row <= 0;
                comp_col <= 0;
                elem_cnt <= 0;
                acc      <= (others => '0');
                H_reg    <= (others => (others => (others => '0')));
                FF_reg   <= (others => (others => (others => '0')));

            else
                case state is

                    when IDLE =>
                        if start = '1' then
                            state    <= FF1_COMPUTE;
                            comp_row <= 0;
                            comp_col <= 0;
                            elem_cnt <= 0;
                            acc      <= (others => '0');
                        end if;

                    when FF1_COMPUTE =>
                        if elem_cnt < 8 then
                            acc      <= acc + (X_in(comp_row, elem_cnt) *
                                        FF1_W(comp_col * 8 + elem_cnt));
                            elem_cnt <= elem_cnt + 1;
                        else
                            result := acc(30 downto 15) + FF1_B(comp_col);
                            if result < 0 then
                                H_reg(comp_row, comp_col) <= (others => '0');
                            else
                                H_reg(comp_row, comp_col) <= result;
                            end if;
                            acc      <= (others => '0');
                            elem_cnt <= 0;
                            if comp_col < 15 then
                                comp_col <= comp_col + 1;
                            elsif comp_row < 3 then
                                comp_col <= 0;
                                comp_row <= comp_row + 1;
                            else
                                state    <= FF2_COMPUTE;
                                comp_row <= 0;
                                comp_col <= 0;
                                elem_cnt <= 0;
                                acc      <= (others => '0');
                            end if;
                        end if;

                    when FF2_COMPUTE =>
                        if elem_cnt < 16 then
                            acc      <= acc + (H_reg(comp_row, elem_cnt) *
                                        FF2_W(comp_col * 16 + elem_cnt));
                            elem_cnt <= elem_cnt + 1;
                        else
                            FF_reg(comp_row, comp_col) <= acc(30 downto 15) + FF2_B(comp_col);
                            acc      <= (others => '0');
                            elem_cnt <= 0;
                            if comp_col < 7 then
                                comp_col <= comp_col + 1;
                            elsif comp_row < 3 then
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