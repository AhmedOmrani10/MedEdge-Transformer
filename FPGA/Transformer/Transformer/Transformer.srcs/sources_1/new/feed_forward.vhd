library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library xpm;
use xpm.vcomponents.all;
use work.transformer_pkg.all;

entity feed_forward is
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        start : in  std_logic;
        X_in  : in  matrix_16x9;
        Y_out : out matrix_16x9;
        done  : out std_logic
    );
end feed_forward;

architecture Behavioral of feed_forward is

    type bias_22 is array(0 to 21) of signed(15 downto 0);
    type bias_9  is array(0 to 8)  of signed(15 downto 0);

    constant FF1_B : bias_22 := (
        to_signed(6441,16),  to_signed(8866,16),  to_signed(8379,16),
        to_signed(7907,16),  to_signed(-7038,16), to_signed(-1099,16),
        to_signed(2556,16),  to_signed(-6080,16), to_signed(1571,16),
        to_signed(2254,16),  to_signed(4311,16),  to_signed(-2376,16),
        to_signed(-7231,16), to_signed(2517,16),  to_signed(-2526,16),
        to_signed(-1563,16), to_signed(2824,16),  to_signed(3790,16),
        to_signed(3101,16),  to_signed(6085,16),  to_signed(-4613,16),
        to_signed(-5351,16)
    );

    constant FF2_B : bias_9 := (
        to_signed(-423,16),  to_signed(-4185,16), to_signed(1470,16),
        to_signed(2432,16),  to_signed(-1484,16), to_signed(-1250,16),
        to_signed(-2076,16), to_signed(-4246,16), to_signed(1511,16)
    );

    -- 8-bit address covers 198 entries (ceil(log2(198))=8)
    signal ff1_addr : std_logic_vector(7 downto 0) := (others => '0');
    signal ff2_addr : std_logic_vector(7 downto 0) := (others => '0');
    signal ff1_dout : std_logic_vector(15 downto 0);
    signal ff2_dout : std_logic_vector(15 downto 0);
    signal ff1_data : signed(15 downto 0) := (others => '0');
    signal ff2_data : signed(15 downto 0) := (others => '0');

    -- H: 16 tokens x 22 hidden
    type matrix_16x22 is array(0 to 15, 0 to 21) of signed(15 downto 0);
    signal H_reg  : matrix_16x22 := (others => (others => (others => '0')));
    signal FF_reg : matrix_16x9  := (others => (others => (others => '0')));
    signal acc    : signed(39 downto 0) := (others => '0');

    type state_t is (IDLE, ST_FF1_ADDR, ST_FF1_MAC, ST_FF1_STORE,
                          ST_FF2_ADDR, ST_FF2_MAC, ST_FF2_STORE, ST_OUTPUT);
    signal state    : state_t := IDLE;
    signal comp_row : integer range 0 to 16 := 0;
    signal comp_col : integer range 0 to 22 := 0;
    signal elem_cnt : integer range 0 to 22 := 0;
    signal done_reg : std_logic := '0';

begin
    done  <= done_reg;
    Y_out <= FF_reg;

    -- FF1: 22x9=198 entries, MEMORY_SIZE=3168 bits < 4096 limit
    xpm_FF1 : xpm_memory_sprom
        generic map (
            MEMORY_SIZE       => 3168,
            ADDR_WIDTH_A      => 8,
            READ_DATA_WIDTH_A => 16,
            MEMORY_PRIMITIVE  => "block",
            READ_LATENCY_A    => 1,
            MEMORY_INIT_FILE  => "FF1_init.mem",
            MEMORY_INIT_PARAM => ""
        )
        port map (
            addra          => ff1_addr,
            clka           => clk,
            douta          => ff1_dout,
            ena            => '1',
            injectdbiterra => '0',
            injectsbiterra => '0',
            regcea         => '1',
            rsta           => rst,
            sleep          => '0',
            sbiterra       => open,
            dbiterra       => open
        );

    -- FF2: 9x22=198 entries, MEMORY_SIZE=3168 bits < 4096 limit
    xpm_FF2 : xpm_memory_sprom
        generic map (
            MEMORY_SIZE       => 3168,
            ADDR_WIDTH_A      => 8,
            READ_DATA_WIDTH_A => 16,
            MEMORY_PRIMITIVE  => "block",
            READ_LATENCY_A    => 1,
            MEMORY_INIT_FILE  => "FF2_init.mem",
            MEMORY_INIT_PARAM => ""
        )
        port map (
            addra          => ff2_addr,
            clka           => clk,
            douta          => ff2_dout,
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
            ff1_data <= signed(ff1_dout);
            ff2_data <= signed(ff2_dout);
        end if;
    end process;

    process(clk)
        variable raw    : integer;
        variable result : signed(15 downto 0);
    begin
        if rising_edge(clk) then
            done_reg <= '0';
            if rst = '1' then
                state    <= IDLE;
                comp_row <= 0; comp_col <= 0; elem_cnt <= 0;
                acc      <= (others => '0');
                ff1_addr <= (others => '0');
                ff2_addr <= (others => '0');
                H_reg    <= (others => (others => (others => '0')));
                FF_reg   <= (others => (others => (others => '0')));
            else
                case state is

                    when IDLE =>
                        if start = '1' then
                            state    <= ST_FF1_ADDR;
                            comp_row <= 0; comp_col <= 0; elem_cnt <= 0;
                            acc      <= (others => '0');
                            ff1_addr <= (others => '0');
                        end if;

                    -- FF1: X(16x9) * W1(9x22) = H(16x22)
                    -- comp_col = output col 0-21, elem_cnt = input dim 0-8
                    when ST_FF1_ADDR =>
                        ff1_addr <= std_logic_vector(
                            to_unsigned(comp_col * 9 + elem_cnt, 8));
                        state <= ST_FF1_MAC;

                    when ST_FF1_MAC =>
                        if elem_cnt < 9 then
                            acc      <= acc + to_signed(
                                to_integer(X_in(comp_row, elem_cnt)) *
                                to_integer(ff1_data), 40);
                            elem_cnt <= elem_cnt + 1;
                            if elem_cnt < 8 then
                                ff1_addr <= std_logic_vector(
                                    to_unsigned(comp_col*9 + elem_cnt + 1, 8));
                            end if;
                        else
                            state <= ST_FF1_STORE;
                        end if;

                    when ST_FF1_STORE =>
                        raw := to_integer(acc(39 downto 15)) +
                               to_integer(FF1_B(comp_col));
                        if raw > 32767 then result := to_signed(32767,16);
                        elsif raw < -32768 then result := to_signed(-32768,16);
                        else result := to_signed(raw, 16); end if;
                        -- ReLU
                        if result < 0 then
                            H_reg(comp_row, comp_col) <= (others => '0');
                        else
                            H_reg(comp_row, comp_col) <= result;
                        end if;
                        acc      <= (others => '0');
                        elem_cnt <= 0;
                        if comp_col < 21 then
                            comp_col <= comp_col + 1;
                            ff1_addr <= std_logic_vector(
                                to_unsigned((comp_col+1)*9, 8));
                            state    <= ST_FF1_ADDR;
                        elsif comp_row < 15 then
                            comp_col <= 0;
                            comp_row <= comp_row + 1;
                            ff1_addr <= (others => '0');
                            state    <= ST_FF1_ADDR;
                        else
                            comp_row <= 0; comp_col <= 0; elem_cnt <= 0;
                            acc      <= (others => '0');
                            ff2_addr <= (others => '0');
                            state    <= ST_FF2_ADDR;
                        end if;

                    -- FF2: H(16x22) * W2(22x9) = Y(16x9)
                    -- comp_col = output col 0-8, elem_cnt = hidden dim 0-21
                    when ST_FF2_ADDR =>
                        ff2_addr <= std_logic_vector(
                            to_unsigned(comp_col * 22 + elem_cnt, 8));
                        state <= ST_FF2_MAC;

                    when ST_FF2_MAC =>
                        if elem_cnt < 22 then
                            acc      <= acc + to_signed(
                                to_integer(H_reg(comp_row, elem_cnt)) *
                                to_integer(ff2_data), 40);
                            elem_cnt <= elem_cnt + 1;
                            if elem_cnt < 21 then
                                ff2_addr <= std_logic_vector(
                                    to_unsigned(comp_col*22 + elem_cnt + 1, 8));
                            end if;
                        else
                            state <= ST_FF2_STORE;
                        end if;

                    when ST_FF2_STORE =>
                        raw := to_integer(acc(39 downto 15)) +
                               to_integer(FF2_B(comp_col));
                        if raw > 32767 then
                            FF_reg(comp_row, comp_col) <= to_signed(32767,16);
                        elsif raw < -32768 then
                            FF_reg(comp_row, comp_col) <= to_signed(-32768,16);
                        else
                            FF_reg(comp_row, comp_col) <= to_signed(raw,16);
                        end if;
                        acc      <= (others => '0');
                        elem_cnt <= 0;
                        if comp_col < 8 then
                            comp_col <= comp_col + 1;
                            ff2_addr <= std_logic_vector(
                                to_unsigned((comp_col+1)*22, 8));
                            state    <= ST_FF2_ADDR;
                        elsif comp_row < 15 then
                            comp_col <= 0;
                            comp_row <= comp_row + 1;
                            ff2_addr <= (others => '0');
                            state    <= ST_FF2_ADDR;
                        else
                            state <= ST_OUTPUT;
                        end if;

                    when ST_OUTPUT =>
                        done_reg <= '1';
                        state    <= IDLE;

                    when others => state <= IDLE;
                end case;
            end if;
        end if;
    end process;
end Behavioral;
