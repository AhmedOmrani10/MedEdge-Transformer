library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library xpm;
use xpm.vcomponents.all;
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
        out_col : out integer range 0 to 8;
        valid   : out std_logic;
        done    : out std_logic;
        Q_mat   : out matrix_16x9;
        K_mat   : out matrix_16x9;
        V_mat   : out matrix_16x9
    );
end qkv_projector;

architecture Behavioral of qkv_projector is

    -- Input: 16 tokens x 9 features (after embedding)
    type input_array is array(0 to 143) of signed(15 downto 0);
    signal X_reg : input_array := (others => (others => '0'));

    signal Q_reg : matrix_16x9 := (others => (others => (others => '0')));
    signal K_reg : matrix_16x9 := (others => (others => (others => '0')));
    signal V_reg : matrix_16x9 := (others => (others => (others => '0')));

    signal acc_q : signed(39 downto 0) := (others => '0');
    signal acc_k : signed(39 downto 0) := (others => '0');
    signal acc_v : signed(39 downto 0) := (others => '0');

    -- 7-bit address: 9x9=81 entries, ceil(log2(81))=7
    signal rom_addr : std_logic_vector(6 downto 0) := (others => '0');
    signal wq_dout  : std_logic_vector(15 downto 0);
    signal wk_dout  : std_logic_vector(15 downto 0);
    signal wv_dout  : std_logic_vector(15 downto 0);
    signal wq_data  : signed(15 downto 0) := (others => '0');
    signal wk_data  : signed(15 downto 0) := (others => '0');
    signal wv_data  : signed(15 downto 0) := (others => '0');
    signal x_data   : signed(15 downto 0) := (others => '0');
    signal x_addr   : integer range 0 to 143 := 0;

    type state_type is (IDLE, LOAD_X, ADDR, MAC, SATURATE);
    signal state    : state_type := IDLE;
    signal load_idx : integer range 0 to 144 := 0;
    signal comp_row : integer range 0 to 16  := 0;
    signal comp_col : integer range 0 to 9   := 0;
    signal elem_cnt : integer range 0 to 9   := 0;

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

    xpm_Wq : xpm_memory_sprom
        generic map (
            MEMORY_SIZE       => 1296,
            ADDR_WIDTH_A      => 7,
            READ_DATA_WIDTH_A => 16,
            MEMORY_PRIMITIVE  => "block",
            READ_LATENCY_A    => 1,
            MEMORY_INIT_FILE  => "Wq_init.mem",
            MEMORY_INIT_PARAM => ""
        )
        port map (
            addra          => rom_addr,
            clka           => clk,
            douta          => wq_dout,
            ena            => '1',
            injectdbiterra => '0',
            injectsbiterra => '0',
            regcea         => '1',
            rsta           => rst,
            sleep          => '0',
            sbiterra       => open,
            dbiterra       => open
        );

    xpm_Wk : xpm_memory_sprom
        generic map (
            MEMORY_SIZE       => 1296,
            ADDR_WIDTH_A      => 7,
            READ_DATA_WIDTH_A => 16,
            MEMORY_PRIMITIVE  => "block",
            READ_LATENCY_A    => 1,
            MEMORY_INIT_FILE  => "Wk_init.mem",
            MEMORY_INIT_PARAM => ""
        )
        port map (
            addra          => rom_addr,
            clka           => clk,
            douta          => wk_dout,
            ena            => '1',
            injectdbiterra => '0',
            injectsbiterra => '0',
            regcea         => '1',
            rsta           => rst,
            sleep          => '0',
            sbiterra       => open,
            dbiterra       => open
        );

    xpm_Wv : xpm_memory_sprom
        generic map (
            MEMORY_SIZE       => 1296,
            ADDR_WIDTH_A      => 7,
            READ_DATA_WIDTH_A => 16,
            MEMORY_PRIMITIVE  => "block",
            READ_LATENCY_A    => 1,
            MEMORY_INIT_FILE  => "Wv_init.mem",
            MEMORY_INIT_PARAM => ""
        )
        port map (
            addra          => rom_addr,
            clka           => clk,
            douta          => wv_dout,
            ena            => '1',
            injectdbiterra => '0',
            injectsbiterra => '0',
            regcea         => '1',
            rsta           => rst,
            sleep          => '0',
            sbiterra       => open,
            dbiterra       => open
        );

    process(clk)
    begin
        if rising_edge(clk) then
            wq_data <= signed(wq_dout);
            wk_data <= signed(wk_dout);
            wv_data <= signed(wv_dout);
            x_data  <= X_reg(x_addr);
        end if;
    end process;

    process(clk)
        variable raw_q, raw_k, raw_v : integer;
        variable vq, vk, vv : signed(15 downto 0);
    begin
        if rising_edge(clk) then
            valid_reg <= '0';
            done_reg  <= '0';
            if rst = '1' then
                state     <= IDLE;
                load_idx  <= 0;
                comp_row  <= 0; comp_col <= 0; elem_cnt <= 0;
                acc_q     <= (others => '0');
                acc_k     <= (others => '0');
                acc_v     <= (others => '0');
                rom_addr  <= (others => '0');
                x_addr    <= 0;
                Q_out_reg <= (others => '0');
                K_out_reg <= (others => '0');
                V_out_reg <= (others => '0');
            else
                case state is
                    when IDLE =>
                        if start = '1' then
                            state    <= LOAD_X;
                            load_idx <= 0;
                        end if;

                    when LOAD_X =>
                        X_reg(load_idx) <= X_in;
                        if load_idx < 143 then
                            load_idx <= load_idx + 1;
                        else
                            state    <= ADDR;
                            comp_row <= 0; comp_col <= 0; elem_cnt <= 0;
                            acc_q    <= (others => '0');
                            acc_k    <= (others => '0');
                            acc_v    <= (others => '0');
                            rom_addr <= (others => '0');
                            x_addr   <= 0;
                        end if;

                    when ADDR =>
                        rom_addr <= std_logic_vector(
                            to_unsigned(comp_col * 9 + elem_cnt, 7));
                        x_addr   <= comp_row * 9 + elem_cnt;
                        state    <= MAC;

                    when MAC =>
                        if elem_cnt < 9 then
                            acc_q <= acc_q + to_signed(
                                to_integer(x_data) * to_integer(wq_data), 40);
                            acc_k <= acc_k + to_signed(
                                to_integer(x_data) * to_integer(wk_data), 40);
                            acc_v <= acc_v + to_signed(
                                to_integer(x_data) * to_integer(wv_data), 40);
                            elem_cnt <= elem_cnt + 1;
                            if elem_cnt < 8 then
                                rom_addr <= std_logic_vector(
                                    to_unsigned(comp_col * 9 + elem_cnt + 1, 7));
                                x_addr   <= comp_row * 9 + elem_cnt + 1;
                            end if;
                        else
                            state <= SATURATE;
                        end if;

                    when SATURATE =>
                        raw_q := to_integer(acc_q(39 downto 15));
                        if raw_q > 32767 then vq := to_signed(32767,16);
                        elsif raw_q < -32768 then vq := to_signed(-32768,16);
                        else vq := acc_q(30 downto 15); end if;

                        raw_k := to_integer(acc_k(39 downto 15));
                        if raw_k > 32767 then vk := to_signed(32767,16);
                        elsif raw_k < -32768 then vk := to_signed(-32768,16);
                        else vk := acc_k(30 downto 15); end if;

                        raw_v := to_integer(acc_v(39 downto 15));
                        if raw_v > 32767 then vv := to_signed(32767,16);
                        elsif raw_v < -32768 then vv := to_signed(-32768,16);
                        else vv := acc_v(30 downto 15); end if;

                        Q_reg(comp_row, comp_col) <= vq;
                        K_reg(comp_row, comp_col) <= vk;
                        V_reg(comp_row, comp_col) <= vv;
                        Q_out_reg <= vq; K_out_reg <= vk; V_out_reg <= vv;
                        out_row   <= comp_row; out_col <= comp_col;
                        valid_reg <= '1';
                        acc_q <= (others => '0');
                        acc_k <= (others => '0');
                        acc_v <= (others => '0');
                        elem_cnt <= 0;

                        if comp_col < 8 then
                            comp_col <= comp_col + 1;
                            rom_addr <= std_logic_vector(
                                to_unsigned((comp_col+1)*9, 7));
                            x_addr   <= comp_row * 9;
                            state    <= ADDR;
                        elsif comp_row < 15 then
                            comp_col <= 0;
                            comp_row <= comp_row + 1;
                            rom_addr <= (others => '0');
                            x_addr   <= (comp_row+1) * 9;
                            state    <= ADDR;
                        else
                            done_reg <= '1';
                            state    <= IDLE;
                        end if;

                    when others => state <= IDLE;
                end case;
            end if;
        end if;
    end process;

end Behavioral;
