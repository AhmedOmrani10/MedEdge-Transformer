library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.transformer_pkg.all;

entity tb_qkv_projector is
end tb_qkv_projector;

architecture Behavioral of tb_qkv_projector is

    component qkv_projector is
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
    end component;

    signal clk     : std_logic := '0';
    signal rst     : std_logic := '1';
    signal start   : std_logic := '0';
    signal X_in    : signed(15 downto 0) := (others => '0');
    signal Q_out   : signed(15 downto 0);
    signal K_out   : signed(15 downto 0);
    signal V_out   : signed(15 downto 0);
    signal out_row : integer range 0 to 3;
    signal out_col : integer range 0 to 7;
    signal valid   : std_logic;
    signal done    : std_logic;
    signal Q_mat   : matrix_4x8;
    signal K_mat   : matrix_4x8;
    signal V_mat   : matrix_4x8;

    constant CLK_PERIOD : time := 10 ns;

    type flat32_t is array(0 to 31) of integer;

    constant X_FLAT : flat32_t := (
        -14714, -701, -698, -827, -815, 8234, 832, -3548,
        4574, -19918, -19891, -20036, -20043, -10948, 20039, 15646,
        -19130, 3697, 3695, 3570, 3586, 12626, -3564, -7942,
        -18881, 3449, 3447, 3321, 3338, 12378, -3316, -7694
    );

    constant EXP_Q : flat32_t := (
        -6570, -4941, 3106, -4200, -5121, 5928, -5432, -5746,
        -2122, 4332, -2977, 8322, 5864, -701, 1117, 3526,
        -7589, -7064, 4498, -7067, -7637, 7445, -6932, -7868,
        -7531, -6944, 4419, -6905, -7495, 7360, -6847, -7749
    );

    constant EXP_K : flat32_t := (
        1409, 1397, -1761, 1325, 1926, -2537, 1041, 2470,
        -11861, -5638, 3775, 1278, -2276, 7771, -7208, -4216,
        4446, 3007, -3028, 1336, 2888, -4896, 2929, 4001,
        4275, 2916, -2957, 1336, 2834, -4763, 2822, 3915
    );

    constant EXP_V : flat32_t := (
        7820, -11450, 5583, 4676, 11416, -11910, -7215, -11425,
        -32768, 32767, -32768, -32768, -32768, 32767, 22709, 32767,
        18186, -29245, 14794, 13795, 29137, -26256, -14066, -29174,
        17601, -28240, 14274, 13280, 28137, -25446, -13679, -28172
    );

begin

    uut : qkv_projector
        port map(
            clk => clk, rst => rst, start => start,
            X_in => X_in, Q_out => Q_out,
            K_out => K_out, V_out => V_out,
            out_row => out_row, out_col => out_col,
            valid => valid, done => done,
            Q_mat => Q_mat, K_mat => K_mat, V_mat => V_mat
        );

    clk <= not clk after CLK_PERIOD/2;

    process
        variable load_idx : integer;
        variable pass : boolean := true;
        variable got, exp_val : integer;
    begin
        rst   <= '1';
        start <= '0';
        wait for 3 * CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD;

        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';

        load_idx := 0;
        while load_idx < 32 loop
            X_in <= to_signed(X_FLAT(load_idx), 16);
            wait for CLK_PERIOD;
            load_idx := load_idx + 1;
        end loop;

        wait until done = '1';
        wait for CLK_PERIOD;

        report "=== Checking Q matrix ===";
        for r in 0 to 3 loop
            for c in 0 to 7 loop
                got     := to_integer(Q_mat(r, c));
                exp_val := EXP_Q(r*8 + c);
                if got /= exp_val then
                    report "Q[" & integer'image(r) & "][" & integer'image(c)
                        & "]=" & integer'image(got)
                        & " exp=" & integer'image(exp_val) severity warning;
                    pass := false;
                end if;
            end loop;
        end loop;

        report "=== Checking K matrix ===";
        for r in 0 to 3 loop
            for c in 0 to 7 loop
                got     := to_integer(K_mat(r, c));
                exp_val := EXP_K(r*8 + c);
                if got /= exp_val then
                    report "K[" & integer'image(r) & "][" & integer'image(c)
                        & "]=" & integer'image(got)
                        & " exp=" & integer'image(exp_val) severity warning;
                    pass := false;
                end if;
            end loop;
        end loop;

        report "=== Checking V matrix ===";
        for r in 0 to 3 loop
            for c in 0 to 7 loop
                got     := to_integer(V_mat(r, c));
                exp_val := EXP_V(r*8 + c);
                if got /= exp_val then
                    report "V[" & integer'image(r) & "][" & integer'image(c)
                        & "]=" & integer'image(got)
                        & " exp=" & integer'image(exp_val) severity warning;
                    pass := false;
                end if;
            end loop;
        end loop;

        if pass then
            report "QKV PROJECTOR: ALL TESTS PASSED!" severity note;
        else
            report "QKV PROJECTOR: TESTS FAILED!" severity error;
        end if;

        wait;
    end process;

end Behavioral;