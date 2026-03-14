library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.transformer_pkg.all;

entity top_level is
    port (
        DDR_addr          : inout std_logic_vector(14 downto 0);
        DDR_ba            : inout std_logic_vector(2 downto 0);
        DDR_cas_n         : inout std_logic;
        DDR_ck_n          : inout std_logic;
        DDR_ck_p          : inout std_logic;
        DDR_cke           : inout std_logic;
        DDR_cs_n          : inout std_logic;
        DDR_dm            : inout std_logic_vector(3 downto 0);
        DDR_dq            : inout std_logic_vector(31 downto 0);
        DDR_dqs_n         : inout std_logic_vector(3 downto 0);
        DDR_dqs_p         : inout std_logic_vector(3 downto 0);
        DDR_odt           : inout std_logic;
        DDR_ras_n         : inout std_logic;
        DDR_reset_n       : inout std_logic;
        DDR_we_n          : inout std_logic;
        FIXED_IO_ddr_vrn  : inout std_logic;
        FIXED_IO_ddr_vrp  : inout std_logic;
        FIXED_IO_mio      : inout std_logic_vector(53 downto 0);
        FIXED_IO_ps_clk   : inout std_logic;
        FIXED_IO_ps_porb  : inout std_logic;
        FIXED_IO_ps_srstb : inout std_logic
    );
end top_level;

architecture structural of top_level is

    component design_1_wrapper is
        port (
            Attn_mat_0        : out std_logic_vector(255 downto 0);
            DDR_addr          : inout std_logic_vector(14 downto 0);
            DDR_ba            : inout std_logic_vector(2 downto 0);
            DDR_cas_n         : inout std_logic;
            DDR_ck_n          : inout std_logic;
            DDR_ck_p          : inout std_logic;
            DDR_cke           : inout std_logic;
            DDR_cs_n          : inout std_logic;
            DDR_dm            : inout std_logic_vector(3 downto 0);
            DDR_dq            : inout std_logic_vector(31 downto 0);
            DDR_dqs_n         : inout std_logic_vector(3 downto 0);
            DDR_dqs_p         : inout std_logic_vector(3 downto 0);
            DDR_odt           : inout std_logic;
            DDR_ras_n         : inout std_logic;
            DDR_reset_n       : inout std_logic;
            DDR_we_n          : inout std_logic;
            FIXED_IO_ddr_vrn  : inout std_logic;
            FIXED_IO_ddr_vrp  : inout std_logic;
            FIXED_IO_mio      : inout std_logic_vector(53 downto 0);
            FIXED_IO_ps_clk   : inout std_logic;
            FIXED_IO_ps_porb  : inout std_logic;
            FIXED_IO_ps_srstb : inout std_logic;
            S_mat_in_0        : in  std_logic_vector(255 downto 0);
            X_mat_0           : in  std_logic_vector(511 downto 0);
            pl_busy_0         : in  std_logic;
            pl_done_0         : in  std_logic;
            pl_start_0        : out std_logic;
            pooled_in_0       : in  std_logic_vector(127 downto 0);
            pl_clk0           : out std_logic;
            pl_resetn         : out std_logic
        );
    end component;

    component qkv_projector is
        port (
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

    component attention_score is
        port (
            clk     : in  std_logic;
            rst     : in  std_logic;
            start   : in  std_logic;
            Q_mat   : in  matrix_4x8;
            K_mat   : in  matrix_4x8;
            S_mat   : out matrix_4x4;
            S_out   : out std_logic_vector(15 downto 0);
            out_row : out integer range 0 to 3;
            out_col : out integer range 0 to 3;
            valid   : out std_logic;
            done    : out std_logic
        );
    end component;

    component attention_output is
        port (
            clk   : in  std_logic;
            rst   : in  std_logic;
            start : in  std_logic;
            Attn  : in  matrix_4x4;
            V_mat : in  matrix_4x8;
            O_mat : out matrix_4x8;
            done  : out std_logic
        );
    end component;

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

    component avg_pool is
        port (
            clk   : in  std_logic;
            rst   : in  std_logic;
            start : in  std_logic;
            X_in  : in  matrix_4x8;
            Y_out : out matrix_1x8;
            done  : out std_logic
        );
    end component;

    -- Clock and Reset
    signal fclk_clk0     : std_logic;
    signal pl_resetn_sig : std_logic;
    signal clk           : std_logic;
    signal rst           : std_logic;

    -- AXI control
    signal pl_start      : std_logic;
    signal pl_done       : std_logic;
    signal pl_busy       : std_logic;

    -- X matrix
    signal X_mat_flat    : std_logic_vector(511 downto 0);
    signal X_mat         : matrix_4x8;

    -- QKV
    signal qkv_start     : std_logic;
    signal qkv_done      : std_logic;
    signal qkv_valid     : std_logic;
    signal qkv_out_row   : integer range 0 to 3;
    signal qkv_out_col   : integer range 0 to 7;
    signal Q_mat         : matrix_4x8;
    signal K_mat         : matrix_4x8;
    signal V_mat         : matrix_4x8;
    signal load_row      : integer range 0 to 3 := 0;
    signal load_col      : integer range 0 to 7 := 0;

    -- Attention score
    signal attn_start    : std_logic;
    signal attn_done     : std_logic;
    signal S_mat         : matrix_4x4;

    -- Attention output
    signal attn_out_start    : std_logic;
    signal attn_out_done     : std_logic;
    signal O_mat             : matrix_4x8;

    -- Feed forward
    signal ff_start      : std_logic;
    signal ff_done       : std_logic;
    signal FF_out        : matrix_4x8;

    -- Avg pool
    signal pool_start    : std_logic;
    signal pool_done     : std_logic;
    signal pooled        : matrix_1x8;

    -- Flat vectors
    signal S_mat_flat    : std_logic_vector(255 downto 0);
    signal Attn_mat_flat : std_logic_vector(255 downto 0);
    signal Attn_mat      : matrix_4x4;
    signal pooled_flat   : std_logic_vector(127 downto 0);

    -- FSM
    type state_t is (IDLE, RUN_QKV, WAIT_QKV, RUN_ATTN, WAIT_ATTN,
                     SEND_S, WAIT_PS, RUN_ATTN_OUT, WAIT_ATTN_OUT,
                     RUN_FF, WAIT_FF, RUN_POOL, WAIT_POOL, DONE_ST);
    signal state             : state_t;
    signal done_cnt          : integer range 0 to 10000000 := 0;
    signal qkv_done_lat      : std_logic;
    signal attn_done_lat     : std_logic;
    signal attn_out_done_lat : std_logic;
    signal ff_done_lat       : std_logic;
    signal pool_done_lat     : std_logic;

    -- *** KEY FIX: track that pl_start went high then low ***
    signal ps_ack_seen       : std_logic;

begin

    clk <= fclk_clk0;
    rst <= not pl_resetn_sig;

    -- Unpack X_mat
    process(X_mat_flat)
        variable idx : integer;
    begin
        for row in 0 to 3 loop
            for col in 0 to 7 loop
                idx := (row * 8 + col) * 16;
                X_mat(row, col) <= signed(X_mat_flat(idx + 15 downto idx));
            end loop;
        end loop;
    end process;

    -- Pack S_mat
    S_mat_flat(15  downto 0)   <= std_logic_vector(S_mat(0,0));
    S_mat_flat(31  downto 16)  <= std_logic_vector(S_mat(0,1));
    S_mat_flat(47  downto 32)  <= std_logic_vector(S_mat(0,2));
    S_mat_flat(63  downto 48)  <= std_logic_vector(S_mat(0,3));
    S_mat_flat(79  downto 64)  <= std_logic_vector(S_mat(1,0));
    S_mat_flat(95  downto 80)  <= std_logic_vector(S_mat(1,1));
    S_mat_flat(111 downto 96)  <= std_logic_vector(S_mat(1,2));
    S_mat_flat(127 downto 112) <= std_logic_vector(S_mat(1,3));
    S_mat_flat(143 downto 128) <= std_logic_vector(S_mat(2,0));
    S_mat_flat(159 downto 144) <= std_logic_vector(S_mat(2,1));
    S_mat_flat(175 downto 160) <= std_logic_vector(S_mat(2,2));
    S_mat_flat(191 downto 176) <= std_logic_vector(S_mat(2,3));
    S_mat_flat(207 downto 192) <= std_logic_vector(S_mat(3,0));
    S_mat_flat(223 downto 208) <= std_logic_vector(S_mat(3,1));
    S_mat_flat(239 downto 224) <= std_logic_vector(S_mat(3,2));
    S_mat_flat(255 downto 240) <= std_logic_vector(S_mat(3,3));

    -- Unpack Attn_mat
    Attn_mat(0,0) <= signed(Attn_mat_flat(15  downto 0));
    Attn_mat(0,1) <= signed(Attn_mat_flat(31  downto 16));
    Attn_mat(0,2) <= signed(Attn_mat_flat(47  downto 32));
    Attn_mat(0,3) <= signed(Attn_mat_flat(63  downto 48));
    Attn_mat(1,0) <= signed(Attn_mat_flat(79  downto 64));
    Attn_mat(1,1) <= signed(Attn_mat_flat(95  downto 80));
    Attn_mat(1,2) <= signed(Attn_mat_flat(111 downto 96));
    Attn_mat(1,3) <= signed(Attn_mat_flat(127 downto 112));
    Attn_mat(2,0) <= signed(Attn_mat_flat(143 downto 128));
    Attn_mat(2,1) <= signed(Attn_mat_flat(159 downto 144));
    Attn_mat(2,2) <= signed(Attn_mat_flat(175 downto 160));
    Attn_mat(2,3) <= signed(Attn_mat_flat(191 downto 176));
    Attn_mat(3,0) <= signed(Attn_mat_flat(207 downto 192));
    Attn_mat(3,1) <= signed(Attn_mat_flat(223 downto 208));
    Attn_mat(3,2) <= signed(Attn_mat_flat(239 downto 224));
    Attn_mat(3,3) <= signed(Attn_mat_flat(255 downto 240));

    -- Pack pooled
    pooled_flat(15  downto 0)   <= std_logic_vector(pooled(0,0));
    pooled_flat(31  downto 16)  <= std_logic_vector(pooled(0,1));
    pooled_flat(47  downto 32)  <= std_logic_vector(pooled(0,2));
    pooled_flat(63  downto 48)  <= std_logic_vector(pooled(0,3));
    pooled_flat(79  downto 64)  <= std_logic_vector(pooled(0,4));
    pooled_flat(95  downto 80)  <= std_logic_vector(pooled(0,5));
    pooled_flat(111 downto 96)  <= std_logic_vector(pooled(0,6));
    pooled_flat(127 downto 112) <= std_logic_vector(pooled(0,7));

    -- PL status
    pl_busy <= '1' when (state /= IDLE and state /= DONE_ST) else '0';
    pl_done <= '1' when state = DONE_ST else '0';

    -- X loading counter
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                load_row <= 0;
                load_col <= 0;
            elsif qkv_start = '1' then
                load_row <= 0;
                load_col <= 0;
            elsif state = RUN_QKV or state = WAIT_QKV then
                if load_row < 3 or load_col < 7 then
                    if load_col < 7 then
                        load_col <= load_col + 1;
                    else
                        load_col <= 0;
                        if load_row < 3 then
                            load_row <= load_row + 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- ============================================
    -- Main FSM
    -- ============================================
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state                <= IDLE;
                qkv_start            <= '0';
                attn_start           <= '0';
                attn_out_start       <= '0';
                ff_start             <= '0';
                pool_start           <= '0';
                done_cnt             <= 0;
                qkv_done_lat         <= '0';
                attn_done_lat        <= '0';
                attn_out_done_lat    <= '0';
                ff_done_lat          <= '0';
                pool_done_lat        <= '0';
                ps_ack_seen          <= '0';
            else
                qkv_start      <= '0';
                attn_start     <= '0';
                attn_out_start <= '0';
                ff_start       <= '0';
                pool_start     <= '0';

                case state is

                    when IDLE =>
                        done_cnt             <= 0;
                        qkv_done_lat         <= '0';
                        attn_done_lat        <= '0';
                        attn_out_done_lat    <= '0';
                        ff_done_lat          <= '0';
                        pool_done_lat        <= '0';
                        ps_ack_seen          <= '0';
                        if pl_start = '1' then
                            state     <= RUN_QKV;
                            qkv_start <= '1';
                        end if;

                    when RUN_QKV =>
                        state <= WAIT_QKV;

                    when WAIT_QKV =>
                        if qkv_done = '1' then
                            qkv_done_lat <= '1';
                        end if;
                        if qkv_done = '1' or qkv_done_lat = '1' then
                            state      <= RUN_ATTN;
                            attn_start <= '1';
                        end if;

                    when RUN_ATTN =>
                        state <= WAIT_ATTN;

                    when WAIT_ATTN =>
                        if attn_done = '1' then
                            attn_done_lat <= '1';
                        end if;
                        if attn_done = '1' or attn_done_lat = '1' then
                            state <= SEND_S;
                        end if;

                    -- *** FIX: hold here until PS clears pl_start ***
                    -- PS protocol:
                    --   1. PS sees pl_done=1 (DONE_ST not used here, pl_busy=1 still)
                    --   Wait - actually we use pl_busy here.
                    --   PS sees S ready (pl_done not set yet in SEND_S)
                    --   PS reads S, writes Attn, clears pl_start=0
                    --   PL sees pl_start=0 → proceeds
                    when SEND_S =>
                        -- Wait here while pl_start is still high
                        -- PS will read S, write Attn, then clear pl_start
                        if pl_start = '0' then
                            state          <= RUN_ATTN_OUT;
                            attn_out_start <= '1';
                        end if;

                    -- WAIT_PS no longer needed - removed
                    -- kept in type for safety but never entered
                    when WAIT_PS =>
                        state <= SEND_S;

                    when RUN_ATTN_OUT =>
                        state <= WAIT_ATTN_OUT;

                    when WAIT_ATTN_OUT =>
                        if attn_out_done = '1' then
                            attn_out_done_lat <= '1';
                        end if;
                        if attn_out_done = '1' or attn_out_done_lat = '1' then
                            state    <= RUN_FF;
                            ff_start <= '1';
                        end if;

                    when RUN_FF =>
                        state <= WAIT_FF;

                    when WAIT_FF =>
                        if ff_done = '1' then
                            ff_done_lat <= '1';
                        end if;
                        if ff_done = '1' or ff_done_lat = '1' then
                            state      <= RUN_POOL;
                            pool_start <= '1';
                        end if;

                    when RUN_POOL =>
                        state <= WAIT_POOL;

                    when WAIT_POOL =>
                        if pool_done = '1' then
                            pool_done_lat <= '1';
                        end if;
                        if pool_done = '1' or pool_done_lat = '1' then
                            state <= DONE_ST;
                        end if;

                    when DONE_ST =>
                        if done_cnt < 10000000 then
                            done_cnt <= done_cnt + 1;
                        else
                            done_cnt <= 0;
                            state    <= IDLE;
                        end if;

                    when others =>
                        state <= IDLE;

                end case;
            end if;
        end if;
    end process;

    -- Component instantiations
    design_1_wrapper_i : design_1_wrapper
        port map (
            Attn_mat_0        => Attn_mat_flat,
            DDR_addr          => DDR_addr,
            DDR_ba            => DDR_ba,
            DDR_cas_n         => DDR_cas_n,
            DDR_ck_n          => DDR_ck_n,
            DDR_ck_p          => DDR_ck_p,
            DDR_cke           => DDR_cke,
            DDR_cs_n          => DDR_cs_n,
            DDR_dm            => DDR_dm,
            DDR_dq            => DDR_dq,
            DDR_dqs_n         => DDR_dqs_n,
            DDR_dqs_p         => DDR_dqs_p,
            DDR_odt           => DDR_odt,
            DDR_ras_n         => DDR_ras_n,
            DDR_reset_n       => DDR_reset_n,
            DDR_we_n          => DDR_we_n,
            FIXED_IO_ddr_vrn  => FIXED_IO_ddr_vrn,
            FIXED_IO_ddr_vrp  => FIXED_IO_ddr_vrp,
            FIXED_IO_mio      => FIXED_IO_mio,
            FIXED_IO_ps_clk   => FIXED_IO_ps_clk,
            FIXED_IO_ps_porb  => FIXED_IO_ps_porb,
            FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,
            S_mat_in_0        => S_mat_flat,
            X_mat_0           => X_mat_flat,
            pl_busy_0         => pl_busy,
            pl_done_0         => pl_done,
            pl_start_0        => pl_start,
            pooled_in_0       => pooled_flat,
            pl_clk0           => fclk_clk0,
            pl_resetn         => pl_resetn_sig
        );

    qkv_projector_i : qkv_projector
        port map (
            clk     => clk,
            rst     => rst,
            start   => qkv_start,
            X_in    => X_mat(load_row, load_col),
            Q_out   => open,
            K_out   => open,
            V_out   => open,
            out_row => qkv_out_row,
            out_col => qkv_out_col,
            valid   => qkv_valid,
            done    => qkv_done,
            Q_mat   => Q_mat,
            K_mat   => K_mat,
            V_mat   => V_mat
        );

    attention_score_i : attention_score
        port map (
            clk     => clk,
            rst     => rst,
            start   => attn_start,
            Q_mat   => Q_mat,
            K_mat   => K_mat,
            S_mat   => S_mat,
            S_out   => open,
            out_row => open,
            out_col => open,
            valid   => open,
            done    => attn_done
        );

    attention_output_i : attention_output
        port map (
            clk   => clk,
            rst   => rst,
            start => attn_out_start,
            Attn  => Attn_mat,
            V_mat => V_mat,
            O_mat => O_mat,
            done  => attn_out_done
        );

    feed_forward_i : feed_forward
        port map (
            clk   => clk,
            rst   => rst,
            start => ff_start,
            X_in  => O_mat,
            Y_out => FF_out,
            done  => ff_done
        );

    avg_pool_i : avg_pool
        port map (
            clk   => clk,
            rst   => rst,
            start => pool_start,
            X_in  => FF_out,
            Y_out => pooled,
            done  => pool_done
        );

end structural;