library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity transformer_axi_slave_lite_v1_0_S00_AXI is
    generic (
        C_S_AXI_DATA_WIDTH : integer := 32;
        C_S_AXI_ADDR_WIDTH : integer := 9
    );
    port (
        pl_start : out std_logic;
        pl_done  : in  std_logic;
        pl_busy  : in  std_logic;
        S_mat_in : in  std_logic_vector(255 downto 0);
        Attn_mat : out std_logic_vector(255 downto 0);
        X_mat    : out std_logic_vector(511 downto 0);

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

    signal axi_awaddr  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    signal axi_awready : std_logic;
    signal axi_wready  : std_logic;
    signal axi_bresp   : std_logic_vector(1 downto 0);
    signal axi_bvalid  : std_logic;
    signal axi_araddr  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    signal axi_arready : std_logic;
    signal axi_rresp   : std_logic_vector(1 downto 0);
    signal axi_rvalid  : std_logic;

    constant ADDR_LSB          : integer := (C_S_AXI_DATA_WIDTH/32) + 1;
    constant OPT_MEM_ADDR_BITS : integer := 6;

    -- =============================================
    -- reg0  = STATUS      (PL driven, read-only)
    -- reg1  = CTRL        (PS writes)
    -- reg2-33  = X matrix (PS writes, PL reads) 4x8=32 elements
    -- reg34-49 = S matrix (PL driven, read-only)
    -- reg50-65 = Attn mat (PS writes, PL reads)
    -- =============================================

    -- PS writable registers
    signal slv_reg1  : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    -- X matrix (reg2-33)
    signal slv_reg2  : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg3  : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg4  : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg5  : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg6  : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg7  : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg8  : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg9  : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg10 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg11 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg12 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg13 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg14 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg15 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg16 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg17 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg18 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg19 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg20 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg21 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg22 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg23 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg24 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg25 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg26 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg27 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg28 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg29 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg30 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg31 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg32 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg33 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    -- Attn matrix (reg50-65)
    signal slv_reg50 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg51 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg52 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg53 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg54 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg55 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg56 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg57 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg58 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg59 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg60 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg61 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg62 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg63 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg64 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg65 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

    -- PL driven read-only registers
    signal slv_reg0  : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    -- S matrix (reg34-49)
    signal slv_reg34 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg35 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg36 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg37 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg38 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg39 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg40 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg41 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg42 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg43 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg44 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg45 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg46 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg47 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg48 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg49 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

    signal byte_index : integer;
    signal mem_logic  : std_logic_vector(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);

    constant Idle  : std_logic_vector(1 downto 0) := "00";
    constant Raddr : std_logic_vector(1 downto 0) := "10";
    constant Rdata : std_logic_vector(1 downto 0) := "11";
    constant Waddr : std_logic_vector(1 downto 0) := "10";
    constant Wdata : std_logic_vector(1 downto 0) := "11";

    signal state_read  : std_logic_vector(1 downto 0);
    signal state_write : std_logic_vector(1 downto 0);

begin

    S_AXI_AWREADY <= axi_awready;
    S_AXI_WREADY  <= axi_wready;
    S_AXI_BRESP   <= axi_bresp;
    S_AXI_BVALID  <= axi_bvalid;
    S_AXI_ARREADY <= axi_arready;
    S_AXI_RRESP   <= axi_rresp;
    S_AXI_RVALID  <= axi_rvalid;

    mem_logic <= S_AXI_AWADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB)
                 when (S_AXI_AWVALID = '1')
                 else axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);

    -- =============================================
    -- PL driven registers (STATUS + S matrix)
    -- =============================================
    slv_reg0  <= (1 => pl_done, 0 => pl_busy, others => '0');
    slv_reg34 <= std_logic_vector(resize(signed(S_mat_in(15  downto 0)),   32));
    slv_reg35 <= std_logic_vector(resize(signed(S_mat_in(31  downto 16)),  32));
    slv_reg36 <= std_logic_vector(resize(signed(S_mat_in(47  downto 32)),  32));
    slv_reg37 <= std_logic_vector(resize(signed(S_mat_in(63  downto 48)),  32));
    slv_reg38 <= std_logic_vector(resize(signed(S_mat_in(79  downto 64)),  32));
    slv_reg39 <= std_logic_vector(resize(signed(S_mat_in(95  downto 80)),  32));
    slv_reg40 <= std_logic_vector(resize(signed(S_mat_in(111 downto 96)),  32));
    slv_reg41 <= std_logic_vector(resize(signed(S_mat_in(127 downto 112)), 32));
    slv_reg42 <= std_logic_vector(resize(signed(S_mat_in(143 downto 128)), 32));
    slv_reg43 <= std_logic_vector(resize(signed(S_mat_in(159 downto 144)), 32));
    slv_reg44 <= std_logic_vector(resize(signed(S_mat_in(175 downto 160)), 32));
    slv_reg45 <= std_logic_vector(resize(signed(S_mat_in(191 downto 176)), 32));
    slv_reg46 <= std_logic_vector(resize(signed(S_mat_in(207 downto 192)), 32));
    slv_reg47 <= std_logic_vector(resize(signed(S_mat_in(223 downto 208)), 32));
    slv_reg48 <= std_logic_vector(resize(signed(S_mat_in(239 downto 224)), 32));
    slv_reg49 <= std_logic_vector(resize(signed(S_mat_in(255 downto 240)), 32));

    -- =============================================
    -- PS driven outputs to PL
    -- =============================================
    pl_start <= slv_reg1(0);

    -- X matrix output (4x8 = 32 elements, reg2-33)
    X_mat(15  downto 0)   <= slv_reg2(15  downto 0);
    X_mat(31  downto 16)  <= slv_reg3(15  downto 0);
    X_mat(47  downto 32)  <= slv_reg4(15  downto 0);
    X_mat(63  downto 48)  <= slv_reg5(15  downto 0);
    X_mat(79  downto 64)  <= slv_reg6(15  downto 0);
    X_mat(95  downto 80)  <= slv_reg7(15  downto 0);
    X_mat(111 downto 96)  <= slv_reg8(15  downto 0);
    X_mat(127 downto 112) <= slv_reg9(15  downto 0);
    X_mat(143 downto 128) <= slv_reg10(15 downto 0);
    X_mat(159 downto 144) <= slv_reg11(15 downto 0);
    X_mat(175 downto 160) <= slv_reg12(15 downto 0);
    X_mat(191 downto 176) <= slv_reg13(15 downto 0);
    X_mat(207 downto 192) <= slv_reg14(15 downto 0);
    X_mat(223 downto 208) <= slv_reg15(15 downto 0);
    X_mat(239 downto 224) <= slv_reg16(15 downto 0);
    X_mat(255 downto 240) <= slv_reg17(15 downto 0);
    X_mat(271 downto 256) <= slv_reg18(15 downto 0);
    X_mat(287 downto 272) <= slv_reg19(15 downto 0);
    X_mat(303 downto 288) <= slv_reg20(15 downto 0);
    X_mat(319 downto 304) <= slv_reg21(15 downto 0);
    X_mat(335 downto 320) <= slv_reg22(15 downto 0);
    X_mat(351 downto 336) <= slv_reg23(15 downto 0);
    X_mat(367 downto 352) <= slv_reg24(15 downto 0);
    X_mat(383 downto 368) <= slv_reg25(15 downto 0);
    X_mat(399 downto 384) <= slv_reg26(15 downto 0);
    X_mat(415 downto 400) <= slv_reg27(15 downto 0);
    X_mat(431 downto 416) <= slv_reg28(15 downto 0);
    X_mat(447 downto 432) <= slv_reg29(15 downto 0);
    X_mat(463 downto 448) <= slv_reg30(15 downto 0);
    X_mat(479 downto 464) <= slv_reg31(15 downto 0);
    X_mat(495 downto 480) <= slv_reg32(15 downto 0);
    X_mat(511 downto 496) <= slv_reg33(15 downto 0);

    -- Attn matrix output (reg50-65)
    Attn_mat(15  downto 0)   <= slv_reg50(15 downto 0);
    Attn_mat(31  downto 16)  <= slv_reg51(15 downto 0);
    Attn_mat(47  downto 32)  <= slv_reg52(15 downto 0);
    Attn_mat(63  downto 48)  <= slv_reg53(15 downto 0);
    Attn_mat(79  downto 64)  <= slv_reg54(15 downto 0);
    Attn_mat(95  downto 80)  <= slv_reg55(15 downto 0);
    Attn_mat(111 downto 96)  <= slv_reg56(15 downto 0);
    Attn_mat(127 downto 112) <= slv_reg57(15 downto 0);
    Attn_mat(143 downto 128) <= slv_reg58(15 downto 0);
    Attn_mat(159 downto 144) <= slv_reg59(15 downto 0);
    Attn_mat(175 downto 160) <= slv_reg60(15 downto 0);
    Attn_mat(191 downto 176) <= slv_reg61(15 downto 0);
    Attn_mat(207 downto 192) <= slv_reg62(15 downto 0);
    Attn_mat(223 downto 208) <= slv_reg63(15 downto 0);
    Attn_mat(239 downto 224) <= slv_reg64(15 downto 0);
    Attn_mat(255 downto 240) <= slv_reg65(15 downto 0);

    -- =============================================
    -- AXI Write State Machine
    -- =============================================
    process(S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_awready <= '0';
                axi_wready  <= '0';
                axi_bvalid  <= '0';
                axi_bresp   <= (others => '0');
                state_write <= Idle;
            else
                case state_write is
                    when Idle =>
                        if S_AXI_ARESETN = '1' then
                            axi_awready <= '1';
                            axi_wready  <= '1';
                            state_write <= Waddr;
                        end if;
                    when Waddr =>
                        if S_AXI_AWVALID = '1' and axi_awready = '1' then
                            axi_awaddr <= S_AXI_AWADDR;
                            if S_AXI_WVALID = '1' then
                                axi_awready <= '1';
                                state_write <= Waddr;
                                axi_bvalid  <= '1';
                            else
                                axi_awready <= '0';
                                state_write <= Wdata;
                                if S_AXI_BREADY = '1' and axi_bvalid = '1' then
                                    axi_bvalid <= '0';
                                end if;
                            end if;
                        else
                            state_write <= state_write;
                            if S_AXI_BREADY = '1' and axi_bvalid = '1' then
                                axi_bvalid <= '0';
                            end if;
                        end if;
                    when Wdata =>
                        if S_AXI_WVALID = '1' then
                            state_write <= Waddr;
                            axi_bvalid  <= '1';
                            axi_awready <= '1';
                        else
                            state_write <= state_write;
                            if S_AXI_BREADY = '1' and axi_bvalid = '1' then
                                axi_bvalid <= '0';
                            end if;
                        end if;
                    when others =>
                        axi_awready <= '0';
                        axi_wready  <= '0';
                        axi_bvalid  <= '0';
                end case;
            end if;
        end if;
    end process;

    -- =============================================
    -- AXI Write Data Process
    -- =============================================
    process(S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                slv_reg1  <= (others => '0');
                slv_reg2  <= (others => '0');
                slv_reg3  <= (others => '0');
                slv_reg4  <= (others => '0');
                slv_reg5  <= (others => '0');
                slv_reg6  <= (others => '0');
                slv_reg7  <= (others => '0');
                slv_reg8  <= (others => '0');
                slv_reg9  <= (others => '0');
                slv_reg10 <= (others => '0');
                slv_reg11 <= (others => '0');
                slv_reg12 <= (others => '0');
                slv_reg13 <= (others => '0');
                slv_reg14 <= (others => '0');
                slv_reg15 <= (others => '0');
                slv_reg16 <= (others => '0');
                slv_reg17 <= (others => '0');
                slv_reg18 <= (others => '0');
                slv_reg19 <= (others => '0');
                slv_reg20 <= (others => '0');
                slv_reg21 <= (others => '0');
                slv_reg22 <= (others => '0');
                slv_reg23 <= (others => '0');
                slv_reg24 <= (others => '0');
                slv_reg25 <= (others => '0');
                slv_reg26 <= (others => '0');
                slv_reg27 <= (others => '0');
                slv_reg28 <= (others => '0');
                slv_reg29 <= (others => '0');
                slv_reg30 <= (others => '0');
                slv_reg31 <= (others => '0');
                slv_reg32 <= (others => '0');
                slv_reg33 <= (others => '0');
                slv_reg50 <= (others => '0');
                slv_reg51 <= (others => '0');
                slv_reg52 <= (others => '0');
                slv_reg53 <= (others => '0');
                slv_reg54 <= (others => '0');
                slv_reg55 <= (others => '0');
                slv_reg56 <= (others => '0');
                slv_reg57 <= (others => '0');
                slv_reg58 <= (others => '0');
                slv_reg59 <= (others => '0');
                slv_reg60 <= (others => '0');
                slv_reg61 <= (others => '0');
                slv_reg62 <= (others => '0');
                slv_reg63 <= (others => '0');
                slv_reg64 <= (others => '0');
                slv_reg65 <= (others => '0');
            else
                if S_AXI_WVALID = '1' then
                    case mem_logic is
                        when b"0000001" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg1(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0000010" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg2(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0000011" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg3(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0000100" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg4(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0000101" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg5(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0000110" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg6(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0000111" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg7(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0001000" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg8(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0001001" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg9(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0001010" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg10(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0001011" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg11(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0001100" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg12(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0001101" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg13(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0001110" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg14(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0001111" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg15(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0010000" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg16(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0010001" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg17(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0010010" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg18(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0010011" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg19(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0010100" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg20(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0010101" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg21(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0010110" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg22(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0010111" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg23(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0011000" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg24(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0011001" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg25(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0011010" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg26(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0011011" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg27(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0011100" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg28(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0011101" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg29(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0011110" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg30(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0011111" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg31(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0100000" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg32(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0100001" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg33(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0110010" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg50(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0110011" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg51(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0110100" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg52(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0110101" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg53(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0110110" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg54(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0110111" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg55(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0111000" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg56(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0111001" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg57(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0111010" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg58(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0111011" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg59(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0111100" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg60(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0111101" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg61(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0111110" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg62(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"0111111" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg63(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"1000000" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg64(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when b"1000001" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg65(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when others => null;
                    end case;
                end if;
            end if;
        end if;
    end process;

    -- =============================================
    -- AXI Read State Machine
    -- =============================================
    process(S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_arready <= '0';
                axi_rvalid  <= '0';
                axi_rresp   <= (others => '0');
                state_read  <= Idle;
            else
                case state_read is
                    when Idle =>
                        if S_AXI_ARESETN = '1' then
                            axi_arready <= '1';
                            state_read  <= Raddr;
                        end if;
                    when Raddr =>
                        if S_AXI_ARVALID = '1' and axi_arready = '1' then
                            state_read  <= Rdata;
                            axi_rvalid  <= '1';
                            axi_arready <= '0';
                            axi_araddr  <= S_AXI_ARADDR;
                        end if;
                    when Rdata =>
                        if axi_rvalid = '1' and S_AXI_RREADY = '1' then
                            axi_rvalid  <= '0';
                            axi_arready <= '1';
                            state_read  <= Raddr;
                        end if;
                    when others =>
                        axi_arready <= '0';
                        axi_rvalid  <= '0';
                end case;
            end if;
        end if;
    end process;

    -- =============================================
    -- AXI Read Data Mux
    -- =============================================
    S_AXI_RDATA <=
        slv_reg0  when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0000000" else
        slv_reg1  when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0000001" else
        slv_reg2  when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0000010" else
        slv_reg3  when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0000011" else
        slv_reg4  when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0000100" else
        slv_reg5  when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0000101" else
        slv_reg6  when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0000110" else
        slv_reg7  when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0000111" else
        slv_reg8  when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0001000" else
        slv_reg9  when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0001001" else
        slv_reg10 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0001010" else
        slv_reg11 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0001011" else
        slv_reg12 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0001100" else
        slv_reg13 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0001101" else
        slv_reg14 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0001110" else
        slv_reg15 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0001111" else
        slv_reg16 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0010000" else
        slv_reg17 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0010001" else
        slv_reg18 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0010010" else
        slv_reg19 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0010011" else
        slv_reg20 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0010100" else
        slv_reg21 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0010101" else
        slv_reg22 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0010110" else
        slv_reg23 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0010111" else
        slv_reg24 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0011000" else
        slv_reg25 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0011001" else
        slv_reg26 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0011010" else
        slv_reg27 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0011011" else
        slv_reg28 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0011100" else
        slv_reg29 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0011101" else
        slv_reg30 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0011110" else
        slv_reg31 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0011111" else
        slv_reg32 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0100000" else
        slv_reg33 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0100001" else
        slv_reg34 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0100010" else
        slv_reg35 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0100011" else
        slv_reg36 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0100100" else
        slv_reg37 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0100101" else
        slv_reg38 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0100110" else
        slv_reg39 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0100111" else
        slv_reg40 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0101000" else
        slv_reg41 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0101001" else
        slv_reg42 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0101010" else
        slv_reg43 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0101011" else
        slv_reg44 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0101100" else
        slv_reg45 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0101101" else
        slv_reg46 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0101110" else
        slv_reg47 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0101111" else
        slv_reg48 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0110000" else
        slv_reg49 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0110001" else
        slv_reg50 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0110010" else
        slv_reg51 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0110011" else
        slv_reg52 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0110100" else
        slv_reg53 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0110101" else
        slv_reg54 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0110110" else
        slv_reg55 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0110111" else
        slv_reg56 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0111000" else
        slv_reg57 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0111001" else
        slv_reg58 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0111010" else
        slv_reg59 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0111011" else
        slv_reg60 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0111100" else
        slv_reg61 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0111101" else
        slv_reg62 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0111110" else
        slv_reg63 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "0111111" else
        slv_reg64 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "1000000" else
        slv_reg65 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "1000001" else
        (others => '0');

end arch_imp;