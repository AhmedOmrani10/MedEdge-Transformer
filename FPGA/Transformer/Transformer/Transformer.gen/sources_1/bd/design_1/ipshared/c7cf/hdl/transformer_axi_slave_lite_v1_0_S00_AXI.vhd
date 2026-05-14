library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity transformer_axi_slave_lite_v1_0_S00_AXI is
    generic (
        C_S_AXI_DATA_WIDTH : integer := 32;
        C_S_AXI_ADDR_WIDTH : integer := 12
    );
    port (
        STATUS_REG   : in  std_logic_vector(31 downto 0);
        CTRL_REG     : out std_logic_vector(31 downto 0);
        X_mat_out    : out std_logic_vector(2303 downto 0);
        S_mat_in     : in  std_logic_vector(4095 downto 0);
        Attn_mat_out : out std_logic_vector(4095 downto 0);
        pooled_in    : in  std_logic_vector(143 downto 0);
        S_AXI_ACLK    : in  std_logic;
        S_AXI_ARESETN : in  std_logic;
        S_AXI_AWADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_AWPROT  : in  std_logic_vector(2 downto 0);
        S_AXI_AWVALID : in  std_logic;
        S_AXI_AWREADY : out std_logic;
        S_AXI_WDATA   : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_WSTRB   : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
        S_AXI_WVALID  : in  std_logic;
        S_AXI_WREADY  : out std_logic;
        S_AXI_BRESP   : out std_logic_vector(1 downto 0);
        S_AXI_BVALID  : out std_logic;
        S_AXI_BREADY  : in  std_logic;
        S_AXI_ARADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_ARPROT  : in  std_logic_vector(2 downto 0);
        S_AXI_ARVALID : in  std_logic;
        S_AXI_ARREADY : out std_logic;
        S_AXI_RDATA   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_RRESP   : out std_logic_vector(1 downto 0);
        S_AXI_RVALID  : out std_logic;
        S_AXI_RREADY  : in  std_logic
    );
end transformer_axi_slave_lite_v1_0_S00_AXI;

architecture arch_imp of transformer_axi_slave_lite_v1_0_S00_AXI is

    -- reg0:       STATUS  (RO - PL driven)
    -- reg1:       CTRL    (RW - PS writes)
    -- reg2-145:   X_mat   144 regs (RW) 16x9
    -- reg146-401: S_mat   256 regs (RO - PL driven)
    -- reg402-657: Attn    256 regs (RW)
    -- reg658-666: pooled    9 regs (RO - PL driven)

    constant ADDR_LSB          : integer := 2;
    constant OPT_MEM_ADDR_BITS : integer := 9;

    signal axi_awaddr  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    signal axi_awready : std_logic;
    signal axi_wready  : std_logic;
    signal axi_bresp   : std_logic_vector(1 downto 0);
    signal axi_bvalid  : std_logic;
    signal axi_araddr  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    signal axi_arready : std_logic;
    signal axi_rresp   : std_logic_vector(1 downto 0);
    signal axi_rvalid  : std_logic;
    signal aw_en       : std_logic;

    -- RW registers
    signal slv_reg1 : std_logic_vector(31 downto 0) := (others=>'0');

    type xmat_regs_t  is array(0 to 143) of std_logic_vector(31 downto 0);
    type attn_regs_t  is array(0 to 255) of std_logic_vector(31 downto 0);

    signal xmat_regs  : xmat_regs_t := (others=>(others=>'0'));
    signal attn_regs  : attn_regs_t := (others=>(others=>'0'));

    -- RO registers (PL driven — combinational, no register needed)
    signal reg_status : std_logic_vector(31 downto 0);
    type smat_regs_t   is array(0 to 255) of std_logic_vector(31 downto 0);
    type pool_regs_t   is array(0 to 8)   of std_logic_vector(31 downto 0);
    signal smat_regs   : smat_regs_t;
    signal pool_regs   : pool_regs_t;

    signal mem_logic : std_logic_vector(OPT_MEM_ADDR_BITS-1 downto 0);
    signal rd_idx    : integer range 0 to 1023;

begin

    S_AXI_AWREADY <= axi_awready;
    S_AXI_WREADY  <= axi_wready;
    S_AXI_BRESP   <= axi_bresp;
    S_AXI_BVALID  <= axi_bvalid;
    S_AXI_ARREADY <= axi_arready;
    S_AXI_RRESP   <= axi_rresp;
    S_AXI_RVALID  <= axi_rvalid;

    -- PL outputs
    CTRL_REG <= slv_reg1;

    gen_x: for i in 0 to 143 generate
        X_mat_out(i*16+15 downto i*16) <= xmat_regs(i)(15 downto 0);
    end generate;

    gen_a: for i in 0 to 255 generate
        Attn_mat_out(i*16+15 downto i*16) <= attn_regs(i)(15 downto 0);
    end generate;

    -- PL inputs (combinational — no driver conflict)
    reg_status <= STATUS_REG;

    gen_s: for i in 0 to 255 generate
        smat_regs(i) <= x"0000" & S_mat_in(i*16+15 downto i*16);
    end generate;

    gen_p: for i in 0 to 8 generate
        pool_regs(i) <= x"0000" & pooled_in(i*16+15 downto i*16);
    end generate;

    mem_logic <= axi_awaddr(ADDR_LSB+OPT_MEM_ADDR_BITS-1 downto ADDR_LSB);

    -- AW channel
    process(S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_awready <= '0'; aw_en <= '1';
            else
                if axi_awready='0' and S_AXI_AWVALID='1' and
                   S_AXI_WVALID='1' and aw_en='1' then
                    axi_awready <= '1'; aw_en <= '0';
                elsif S_AXI_BREADY='1' and axi_bvalid='1' then
                    aw_en <= '1'; axi_awready <= '0';
                else
                    axi_awready <= '0';
                end if;
            end if;
        end if;
    end process;

    process(S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_awaddr <= (others=>'0');
            elsif axi_awready='0' and S_AXI_AWVALID='1' and
                  S_AXI_WVALID='1' and aw_en='1' then
                axi_awaddr <= S_AXI_AWADDR;
            end if;
        end if;
    end process;

    -- W channel
    process(S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_wready <= '0';
            else
                if axi_wready='0' and S_AXI_WVALID='1' and
                   S_AXI_AWVALID='1' and aw_en='1' then
                    axi_wready <= '1';
                else
                    axi_wready <= '0';
                end if;
            end if;
        end if;
    end process;

    -- Write registers — separate processes per group, no overlap
    process(S_AXI_ACLK)
        variable idx : integer;
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                slv_reg1 <= (others=>'0');
            elsif axi_wready='1' and S_AXI_WVALID='1' and
                  axi_awready='1' and S_AXI_AWVALID='1' then
                idx := to_integer(unsigned(mem_logic));
                if idx = 1 then
                    for b in 0 to 3 loop
                        if S_AXI_WSTRB(b)='1' then
                            slv_reg1(b*8+7 downto b*8) <=
                                S_AXI_WDATA(b*8+7 downto b*8);
                        end if;
                    end loop;
                end if;
            end if;
        end if;
    end process;

    process(S_AXI_ACLK)
        variable idx : integer;
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                for i in 0 to 143 loop
                    xmat_regs(i) <= (others=>'0');
                end loop;
            elsif axi_wready='1' and S_AXI_WVALID='1' and
                  axi_awready='1' and S_AXI_AWVALID='1' then
                idx := to_integer(unsigned(mem_logic));
                if idx >= 2 and idx <= 145 then
                    for b in 0 to 3 loop
                        if S_AXI_WSTRB(b)='1' then
                            xmat_regs(idx-2)(b*8+7 downto b*8) <=
                                S_AXI_WDATA(b*8+7 downto b*8);
                        end if;
                    end loop;
                end if;
            end if;
        end if;
    end process;

    process(S_AXI_ACLK)
        variable idx : integer;
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                for i in 0 to 255 loop
                    attn_regs(i) <= (others=>'0');
                end loop;
            elsif axi_wready='1' and S_AXI_WVALID='1' and
                  axi_awready='1' and S_AXI_AWVALID='1' then
                idx := to_integer(unsigned(mem_logic));
                if idx >= 402 and idx <= 657 then
                    for b in 0 to 3 loop
                        if S_AXI_WSTRB(b)='1' then
                            attn_regs(idx-402)(b*8+7 downto b*8) <=
                                S_AXI_WDATA(b*8+7 downto b*8);
                        end if;
                    end loop;
                end if;
            end if;
        end if;
    end process;

    -- B channel
    process(S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_bvalid <= '0'; axi_bresp <= "00";
            else
                if axi_awready='1' and S_AXI_AWVALID='1' and
                   axi_wready='1' and S_AXI_WVALID='1' and
                   axi_bvalid='0' then
                    axi_bvalid <= '1'; axi_bresp <= "00";
                elsif S_AXI_BREADY='1' and axi_bvalid='1' then
                    axi_bvalid <= '0';
                end if;
            end if;
        end if;
    end process;

    -- AR channel
    process(S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_arready <= '0'; axi_araddr <= (others=>'0');
            else
                if axi_arready='0' and S_AXI_ARVALID='1' then
                    axi_arready <= '1'; axi_araddr <= S_AXI_ARADDR;
                else
                    axi_arready <= '0';
                end if;
            end if;
        end if;
    end process;

    process(S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_rvalid <= '0'; axi_rresp <= "00";
            else
                if axi_arready='1' and S_AXI_ARVALID='1' and
                   axi_rvalid='0' then
                    axi_rvalid <= '1'; axi_rresp <= "00";
                elsif axi_rvalid='1' and S_AXI_RREADY='1' then
                    axi_rvalid <= '0';
                end if;
            end if;
        end if;
    end process;

    -- Read data mux
    rd_idx <= to_integer(unsigned(
        axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-1 downto ADDR_LSB)));

    process(rd_idx, reg_status, slv_reg1, xmat_regs,
            smat_regs, attn_regs, pool_regs)
    begin
        if    rd_idx = 0                          then S_AXI_RDATA <= reg_status;
        elsif rd_idx = 1                          then S_AXI_RDATA <= slv_reg1;
        elsif rd_idx >= 2   and rd_idx <= 145     then S_AXI_RDATA <= xmat_regs(rd_idx-2);
        elsif rd_idx >= 146 and rd_idx <= 401     then S_AXI_RDATA <= smat_regs(rd_idx-146);
        elsif rd_idx >= 402 and rd_idx <= 657     then S_AXI_RDATA <= attn_regs(rd_idx-402);
        elsif rd_idx >= 658 and rd_idx <= 666     then S_AXI_RDATA <= pool_regs(rd_idx-658);
        else                                           S_AXI_RDATA <= (others=>'0');
        end if;
    end process;

end arch_imp;
