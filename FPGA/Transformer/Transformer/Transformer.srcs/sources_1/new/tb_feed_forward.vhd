library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.transformer_pkg.all;

entity tb_feed_forward is
end tb_feed_forward;

architecture Behavioral of tb_feed_forward is

    component feed_forward is
        port (
            clk   : in  std_logic;
            rst   : in  std_logic;
            start : in  std_logic;
            X_in  : in  matrix_4x8;
            Y_out : out matrix_4x8;
            done  : out std_logic
        );
    end component;

    signal clk   : std_logic := '0';
    signal rst   : std_logic := '1';
    signal start : std_logic := '0';
    signal X_in  : matrix_4x8 := (others => (others => (others => '0')));
    signal Y_out : matrix_4x8;
    signal done  : std_logic;

    constant CLK_PERIOD : time := 10 ns;

    type flat32_t is array(0 to 31) of integer;

    constant O_FLAT : flat32_t := (
        1620, -7739, -548, -1251, 7679, -6460, -2275, -7700,
        2998, -9388, 741, 10, 9325, -8044, -3272, -9347,
        1293, -7348, -854, -1551, 7288, -6084, -2037, -7308,
        1311, -7370, -837, -1534, 7310, -6105, -2051, -7331
    );

    constant EXP_Y : flat32_t := (
        24807, 32767, 32767, 6146, -32768, -4236, -5483, -32768,
        26698, 32767, 32767, 4211, -32768, -6511, -3396, -32768,
        24359, 32767, 32707, 6606, -32768, -3696, -5979, -32768,
        24384, 32767, 32738, 6580, -32768, -3726, -5952, -32768
    );

begin

    uut : feed_forward
        port map(
            clk   => clk,
            rst   => rst,
            start => start,
            X_in  => X_in,
            Y_out => Y_out,
            done  => done
        );

    clk <= not clk after CLK_PERIOD/2;

    process
        variable pass    : boolean := true;
        variable got     : integer;
        variable exp_val : integer;
    begin
        rst   <= '1';
        start <= '0';
        wait for 3 * CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD;

        for r in 0 to 3 loop
            for c in 0 to 7 loop
                X_in(r, c) <= to_signed(O_FLAT(r*8 + c), 16);
            end loop;
        end loop;
        wait for CLK_PERIOD;

        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';

        wait until done = '1';
        wait for CLK_PERIOD;

        report "=== Checking FF2 output Y ===";
        for r in 0 to 3 loop
            for c in 0 to 7 loop
                got     := to_integer(Y_out(r, c));
                exp_val := EXP_Y(r*8 + c);
                if got /= exp_val then
                    report "Y[" & integer'image(r) & "][" & integer'image(c)
                        & "]=" & integer'image(got)
                        & " exp=" & integer'image(exp_val) severity warning;
                    pass := false;
                end if;
            end loop;
        end loop;

        if pass then
            report "FEED FORWARD: ALL TESTS PASSED!" severity note;
        else
            report "FEED FORWARD: TESTS FAILED!" severity error;
        end if;

        wait;
    end process;

end Behavioral;
