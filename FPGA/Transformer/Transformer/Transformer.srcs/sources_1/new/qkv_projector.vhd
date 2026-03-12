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

        -- NEW: expose full matrices
        Q_mat   : out matrix_4x8;
        K_mat   : out matrix_4x8;
        V_mat   : out matrix_4x8
    );
end qkv_projector;

architecture Behavioral of qkv_projector is

    type weight_array is array(0 to 63) of signed(15 downto 0);

    constant Wq : weight_array := (
    to_signed(8297,16),   to_signed(-3392,16),  to_signed(-5168,16),  to_signed(-10687,16),
    to_signed(6933,16),   to_signed(4493,16),   to_signed(-1354,16),  to_signed(6835,16),
    to_signed(-9702,16),  to_signed(8003,16),   to_signed(-1237,16),  to_signed(-9301,16),
    to_signed(1081,16),   to_signed(1596,16),   to_signed(-871,16),   to_signed(-9012,16),
    to_signed(-2980,16),  to_signed(-7907,16),  to_signed(-10282,16), to_signed(-10913,16),
    to_signed(-7763,16),  to_signed(2622,16),   to_signed(-8098,16),  to_signed(-7780,16),
    to_signed(-11867,16), to_signed(10077,16),  to_signed(-5550,16),  to_signed(692,16),
    to_signed(2647,16),   to_signed(3032,16),   to_signed(-477,16),   to_signed(5802,16),
    to_signed(-8178,16),  to_signed(-6319,16),  to_signed(1478,16),   to_signed(8627,16),
    to_signed(7365,16),   to_signed(-457,16),   to_signed(731,16),    to_signed(1889,16),
    to_signed(-148,16),   to_signed(7198,16),   to_signed(12616,16),  to_signed(-783,16),
    to_signed(-7029,16),  to_signed(4854,16),   to_signed(-4027,16),  to_signed(-1619,16),
    to_signed(-8737,16),  to_signed(7207,16),   to_signed(-1542,16),  to_signed(-1334,16),
    to_signed(-829,16),   to_signed(5692,16),   to_signed(9003,16),   to_signed(-7943,16),
    to_signed(4672,16),   to_signed(-634,16),   to_signed(-2868,16),  to_signed(865,16),
    to_signed(7072,16),   to_signed(4647,16),   to_signed(8789,16),   to_signed(7155,16)
);

    constant Wk : weight_array := (
    to_signed(-4987,16),  to_signed(-4448,16),  to_signed(-15056,16), to_signed(8953,16),
    to_signed(-4249,16),  to_signed(-3543,16),  to_signed(-206,16),   to_signed(6723,16),
    to_signed(-7479,16),  to_signed(-799,16),   to_signed(-8288,16),  to_signed(5657,16),
    to_signed(14173,16),  to_signed(-2157,16),  to_signed(7709,16),   to_signed(6779,16),
    to_signed(9648,16),   to_signed(-8110,16),  to_signed(9399,16),   to_signed(2663,16),
    to_signed(-10810,16), to_signed(-12489,16), to_signed(12281,16),  to_signed(-3895,16),
    to_signed(3514,16),   to_signed(3500,16),   to_signed(8910,16),   to_signed(3397,16),
    to_signed(-1919,16),  to_signed(-4830,16),  to_signed(8649,16),   to_signed(-12250,16),
    to_signed(-2129,16),  to_signed(-12805,16), to_signed(8927,16),   to_signed(2056,16),
    to_signed(332,16),    to_signed(8248,16),   to_signed(-9462,16),  to_signed(1090,16),
    to_signed(9621,16),   to_signed(5578,16),   to_signed(-4286,16),  to_signed(4452,16),
    to_signed(-7850,16),  to_signed(2840,16),   to_signed(6588,16),   to_signed(5693,16),
    to_signed(-3039,16),  to_signed(6765,16),   to_signed(9201,16),   to_signed(7625,16),
    to_signed(-23,16),    to_signed(-5491,16),  to_signed(-1973,16),  to_signed(1070,16),
    to_signed(3940,16),   to_signed(-7699,16),  to_signed(-6363,16),  to_signed(-141,16),
    to_signed(-6578,16),  to_signed(8214,16),   to_signed(8137,16),   to_signed(-8164,16)
);

    constant Wv : weight_array := (
    to_signed(-16919,16), to_signed(-13116,16), to_signed(26887,16),  to_signed(-28758,16),
    to_signed(4011,16),   to_signed(-13369,16), to_signed(16845,16),  to_signed(31061,16),
    to_signed(-6309,16),  to_signed(-14136,16), to_signed(-10427,16), to_signed(-20848,16),
    to_signed(-18819,16), to_signed(-15514,16), to_signed(18289,16),  to_signed(26929,16),
    to_signed(-17613,16), to_signed(-25924,16), to_signed(10063,16),  to_signed(-32363,16),
    to_signed(-19187,16), to_signed(-4125,16),  to_signed(19224,16),  to_signed(25343,16),
    to_signed(-19393,16), to_signed(-3559,16),  to_signed(24686,16),  to_signed(-22938,16),
    to_signed(2379,16),   to_signed(-32768,16), to_signed(31753,16),  to_signed(15081,16),
    to_signed(-9970,16),  to_signed(-27141,16), to_signed(3397,16),   to_signed(-25847,16),
    to_signed(-13786,16), to_signed(-12245,16), to_signed(17813,16),  to_signed(10848,16),
    to_signed(-5455,16),  to_signed(-9741,16),  to_signed(-24651,16), to_signed(-5324,16),
    to_signed(-20462,16), to_signed(17480,16),  to_signed(-12571,16), to_signed(15327,16),
    to_signed(20377,16),  to_signed(6863,16),   to_signed(-22003,16), to_signed(17055,16),
    to_signed(14837,16),  to_signed(21638,16),  to_signed(-17204,16), to_signed(-18470,16),
    to_signed(-18751,16), to_signed(-22169,16), to_signed(4452,16),   to_signed(-23166,16),
    to_signed(-13432,16), to_signed(-29319,16), to_signed(26197,16),  to_signed(32765,16)
);
    type input_matrix is array(0 to 3, 0 to 7) of signed(15 downto 0);
    signal X_reg : input_matrix := (others => (others => (others => '0')));

    signal Q_reg : matrix_4x8 := (others => (others => (others => '0')));
    signal K_reg : matrix_4x8 := (others => (others => (others => '0')));
    signal V_reg : matrix_4x8 := (others => (others => (others => '0')));

    signal acc_q : signed(31 downto 0) := (others => '0');
    signal acc_k : signed(31 downto 0) := (others => '0');
    signal acc_v : signed(31 downto 0) := (others => '0');

    type state_type is (IDLE, LOAD_X, COMPUTE);
    signal state : state_type := IDLE;

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

    -- connect internal matrices to output ports
    Q_mat <= Q_reg;
    K_mat <= K_reg;
    V_mat <= V_reg;

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
                        X_reg(load_row, load_col) <= X_in;
                        if load_col < 7 then
                            load_col <= load_col + 1;
                        elsif load_row < 3 then
                            load_col <= 0;
                            load_row <= load_row + 1;
                        else
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
        acc_q <= acc_q + (X_reg(comp_row, elem_cnt) *
                 Wq(comp_col * 8 + elem_cnt));   -- FIXED
        acc_k <= acc_k + (X_reg(comp_row, elem_cnt) *
                 Wk(comp_col * 8 + elem_cnt));   -- FIXED
        acc_v <= acc_v + (X_reg(comp_row, elem_cnt) *
                 Wv(comp_col * 8 + elem_cnt));   -- FIXED
        elem_cnt <= elem_cnt + 1;
                        else
                            Q_reg(comp_row, comp_col) <= acc_q(30 downto 15);
                            K_reg(comp_row, comp_col) <= acc_k(30 downto 15);
                            V_reg(comp_row, comp_col) <= acc_v(30 downto 15);

                            Q_out_reg <= acc_q(30 downto 15);
                            K_out_reg <= acc_k(30 downto 15);
                            V_out_reg <= acc_v(30 downto 15);
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
