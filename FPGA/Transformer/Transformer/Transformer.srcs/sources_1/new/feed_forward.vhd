library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.transformer_pkg.all;

entity feed_forward is
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        start : in  std_logic;
        X_in  : in  matrix_4x8;
        Y_out : out matrix_4x8;
        done  : out std_logic
    );
end feed_forward;

architecture Behavioral of feed_forward is

    type weight_16x8 is array(0 to 127) of signed(15 downto 0);
    type weight_8x16 is array(0 to 127) of signed(15 downto 0);
    type bias_16     is array(0 to 15)  of signed(15 downto 0);
    type bias_8      is array(0 to 7)   of signed(15 downto 0);

    constant FF1_W : weight_16x8 := (
        to_signed(-16445,16), to_signed(-16569,16), to_signed(-16453,16), to_signed(-16444,16),
        to_signed(16519,16),  to_signed(-12975,16), to_signed(16522,16),  to_signed(-16580,16),
        to_signed(583,16),    to_signed(-8789,16),  to_signed(-16408,16), to_signed(-4156,16),
        to_signed(10989,16),  to_signed(-10796,16), to_signed(8679,16),   to_signed(-9138,16),
        to_signed(6262,16),   to_signed(-15846,16), to_signed(-3656,16),  to_signed(6664,16),
        to_signed(14729,16),  to_signed(-15746,16), to_signed(-3444,16),  to_signed(-15923,16),
        to_signed(16457,16),  to_signed(16505,16),  to_signed(16473,16),  to_signed(14797,16),
        to_signed(-16480,16), to_signed(2693,16),   to_signed(-16489,16), to_signed(16514,16),
        to_signed(9470,16),   to_signed(5648,16),   to_signed(10223,16),  to_signed(-1917,16),
        to_signed(-2835,16),  to_signed(9769,16),   to_signed(-7529,16),  to_signed(-7170,16),
        to_signed(16481,16),  to_signed(15215,16),  to_signed(16484,16),  to_signed(12779,16),
        to_signed(-16505,16), to_signed(4884,16),   to_signed(-16515,16), to_signed(14595,16),
        to_signed(-7414,16),  to_signed(-14461,16), to_signed(-16436,16), to_signed(-10857,16),
        to_signed(16456,16),  to_signed(-7151,16),  to_signed(13685,16),  to_signed(-12383,16),
        to_signed(-16457,16), to_signed(-16527,16), to_signed(-16463,16), to_signed(-16458,16),
        to_signed(16530,16),  to_signed(-5308,16),  to_signed(16468,16),  to_signed(-16543,16),
        to_signed(16464,16),  to_signed(16540,16),  to_signed(16464,16),  to_signed(16462,16),
        to_signed(-16491,16), to_signed(195,16),    to_signed(-16472,16), to_signed(16518,16),
        to_signed(-16526,16), to_signed(-10616,16), to_signed(-16529,16), to_signed(-16523,16),
        to_signed(16461,16),  to_signed(1816,16),   to_signed(16505,16),  to_signed(-16477,16),
        to_signed(-4065,16),  to_signed(-1189,16),  to_signed(486,16),    to_signed(-3384,16),
        to_signed(-6737,16),  to_signed(4928,16),   to_signed(7237,16),   to_signed(4405,16),
        to_signed(-7719,16),  to_signed(1376,16),   to_signed(-4372,16),  to_signed(-6025,16),
        to_signed(-2091,16),  to_signed(6549,16),   to_signed(12192,16),  to_signed(-4197,16),
        to_signed(15009,16),  to_signed(15472,16),  to_signed(16511,16),  to_signed(9813,16),
        to_signed(-5376,16),  to_signed(4759,16),   to_signed(-12742,16), to_signed(13874,16),
        to_signed(-16441,16), to_signed(-2388,16),  to_signed(-16444,16), to_signed(-12730,16),
        to_signed(16442,16),  to_signed(6184,16),   to_signed(5839,16),   to_signed(-9276,16),
        to_signed(-3739,16),  to_signed(-1261,16),  to_signed(-943,16),   to_signed(-3731,16),
        to_signed(-5694,16),  to_signed(8403,16),   to_signed(5398,16),   to_signed(4388,16),
        to_signed(16489,16),  to_signed(16560,16),  to_signed(16493,16),  to_signed(16486,16),
        to_signed(-16534,16), to_signed(2812,16),   to_signed(-16497,16), to_signed(16556,16)
    );

    constant FF1_B : bias_16 := (
        to_signed(944,16),   to_signed(3895,16),  to_signed(13748,16), to_signed(8667,16),
        to_signed(12776,16), to_signed(7619,16),  to_signed(2215,16),  to_signed(14869,16),
        to_signed(7182,16),  to_signed(10735,16), to_signed(-1206,16), to_signed(491,16),
        to_signed(7254,16),  to_signed(5352,16),  to_signed(-423,16),  to_signed(7288,16)
    );

    constant FF2_W : weight_8x16 := (
        to_signed(16608,16),  to_signed(13274,16),  to_signed(5722,16),   to_signed(-12819,16),
        to_signed(-8422,16),  to_signed(-14003,16), to_signed(10584,16),  to_signed(16616,16),
        to_signed(-16502,16), to_signed(-6269,16),  to_signed(-15862,16), to_signed(-13584,16),
        to_signed(-6862,16),  to_signed(-8029,16),  to_signed(-7838,16),  to_signed(-16502,16),
        to_signed(16477,16),  to_signed(8004,16),   to_signed(8762,16),   to_signed(-16451,16),
        to_signed(-15967,16), to_signed(-16469,16), to_signed(16437,16),  to_signed(16488,16),
        to_signed(-16529,16), to_signed(16619,16),  to_signed(-13020,16), to_signed(-2373,16),
        to_signed(-16507,16), to_signed(-1615,16),  to_signed(-6057,16),  to_signed(-16519,16),
        to_signed(16584,16),  to_signed(12889,16),  to_signed(10815,16),  to_signed(-16441,16),
        to_signed(-13596,16), to_signed(-16444,16), to_signed(10386,16),  to_signed(16551,16),
        to_signed(-16512,16), to_signed(8224,16),   to_signed(-5494,16),  to_signed(-9928,16),
        to_signed(-12120,16), to_signed(-10874,16), to_signed(-13399,16), to_signed(-16520,16),
        to_signed(-1112,16),  to_signed(-14330,16), to_signed(-8520,16),  to_signed(-8171,16),
        to_signed(1319,16),   to_signed(-14362,16), to_signed(-4122,16),  to_signed(16618,16),
        to_signed(-16474,16), to_signed(16507,16),  to_signed(-3865,16),  to_signed(9565,16),
        to_signed(-5453,16),  to_signed(16457,16),  to_signed(3824,16),   to_signed(-16480,16),
        to_signed(-16504,16), to_signed(-14915,16), to_signed(-6266,16),  to_signed(16461,16),
        to_signed(8530,16),   to_signed(16471,16),  to_signed(-14486,16), to_signed(-16445,16),
        to_signed(16533,16),  to_signed(-16525,16), to_signed(15751,16),  to_signed(14559,16),
        to_signed(16510,16),  to_signed(5591,16),   to_signed(13366,16),  to_signed(16544,16),
        to_signed(-16668,16), to_signed(-5179,16),  to_signed(-10094,16), to_signed(-12023,16),
        to_signed(6229,16),   to_signed(-4570,16),  to_signed(-5536,16),  to_signed(-1303,16),
        to_signed(-16494,16), to_signed(16498,16),  to_signed(3305,16),   to_signed(10355,16),
        to_signed(-14221,16), to_signed(16450,16),  to_signed(1772,16),   to_signed(-16499,16),
        to_signed(-2926,16),  to_signed(6499,16),   to_signed(13205,16),  to_signed(13516,16),
        to_signed(-9028,16),  to_signed(11386,16),  to_signed(8431,16),   to_signed(-16620,16),
        to_signed(16477,16),  to_signed(-16502,16), to_signed(-6116,16),  to_signed(-7259,16),
        to_signed(1738,16),   to_signed(-14442,16), to_signed(-794,16),   to_signed(16481,16),
        to_signed(-16463,16), to_signed(-10175,16), to_signed(597,16),    to_signed(16470,16),
        to_signed(12863,16),  to_signed(16499,16),  to_signed(-16432,16), to_signed(-16483,16),
        to_signed(16555,16),  to_signed(-16610,16), to_signed(10188,16),  to_signed(4721,16),
        to_signed(16542,16),  to_signed(-2818,16),  to_signed(9392,16),   to_signed(16540,16)
    );

    constant FF2_B : bias_8 := (
        to_signed(-914,16),  to_signed(1135,16),  to_signed(-2511,16), to_signed(-7777,16),
        to_signed(2007,16),  to_signed(-272,16),  to_signed(9511,16),  to_signed(-6728,16)
    );

    type matrix_4x16 is array(0 to 3, 0 to 15) of signed(15 downto 0);
    signal H_reg    : matrix_4x16 := (others => (others => (others => '0')));
    signal FF_reg   : matrix_4x8  := (others => (others => (others => '0')));
    signal acc      : signed(39 downto 0) := (others => '0');

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
        variable raw : integer;
        variable result : signed(15 downto 0);
    begin
        if rising_edge(clk) then
            done_reg <= '0';
            if rst = '1' then
                state    <= IDLE;
                comp_row <= 0; comp_col <= 0; elem_cnt <= 0;
                acc      <= (others => '0');
                H_reg    <= (others => (others => (others => '0')));
                FF_reg   <= (others => (others => (others => '0')));
            else
                case state is

                    when IDLE =>
                        if start = '1' then
                            state    <= FF1_COMPUTE;
                            comp_row <= 0; comp_col <= 0; elem_cnt <= 0;
                            acc      <= (others => '0');
                        end if;

                    when FF1_COMPUTE =>
                        if elem_cnt < 8 then
                            acc      <= acc + to_signed(
                                to_integer(X_in(comp_row, elem_cnt)) *
                                to_integer(FF1_W(comp_col * 8 + elem_cnt)), 40);
                            elem_cnt <= elem_cnt + 1;
                        else
                            -- Saturate FF1 output + bias
                            raw := to_integer(acc(39 downto 15)) +
                                   to_integer(FF1_B(comp_col));
                            if raw > 32767 then
                                result := to_signed(32767, 16);
                            elsif raw < -32768 then
                                result := to_signed(-32768, 16);
                            else
                                result := to_signed(raw, 16);
                            end if;
                            -- ReLU
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
                                comp_row <= 0; comp_col <= 0; elem_cnt <= 0;
                                acc      <= (others => '0');
                            end if;
                        end if;

                    when FF2_COMPUTE =>
                        if elem_cnt < 16 then
                            acc      <= acc + to_signed(
                                to_integer(H_reg(comp_row, elem_cnt)) *
                                to_integer(FF2_W(comp_col * 16 + elem_cnt)), 40);
                            elem_cnt <= elem_cnt + 1;
                        else
                            -- Saturate FF2 output + bias
                            raw := to_integer(acc(39 downto 15)) +
                                   to_integer(FF2_B(comp_col));
                            if raw > 32767 then
                                FF_reg(comp_row, comp_col) <= to_signed(32767, 16);
                            elsif raw < -32768 then
                                FF_reg(comp_row, comp_col) <= to_signed(-32768, 16);
                            else
                                FF_reg(comp_row, comp_col) <= to_signed(raw, 16);
                            end if;
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
