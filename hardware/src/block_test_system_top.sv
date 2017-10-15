/*
 * Top-level system wrapper.
 */

module block_test_system_top
    (inout logic [14:0] DDR_addr,
     inout logic [2:0] DDR_ba,
     inout logic DDR_cas_n,
     inout logic DDR_ck_n,
     inout logic DDR_ck_p,
     inout logic DDR_cke,
     inout logic DDR_cs_n,
     inout logic [3:0] DDR_dm,
     inout logic [31:0] DDR_dq,
     inout logic [3:0] DDR_dqs_n,
     inout logic [3:0] DDR_dqs_p,
     inout logic DDR_odt,
     inout logic DDR_ras_n,
     inout logic DDR_reset_n,
     inout logic DDR_we_n,
     inout logic FIXED_IO_ddr_vrn,
     inout logic FIXED_IO_ddr_vrp,
     inout logic [53:0] FIXED_IO_mio,
     inout logic FIXED_IO_ps_clk,
     inout logic FIXED_IO_ps_porb,
     inout logic FIXED_IO_ps_srstb);

    // Internal logic and wiring.
    logic ACLK;
    logic [0:0] ARESETN;
    logic [31:0] M00_AXI_araddr;
    logic [2:0] M00_AXI_arprot;
    logic M00_AXI_arready;
    logic M00_AXI_arvalid;
    logic [31:0] M00_AXI_awaddr;
    logic [2:0] M00_AXI_awprot;
    logic M00_AXI_awready;
    logic M00_AXI_awvalid;
    logic M00_AXI_bready;
    logic [1:0] M00_AXI_bresp;
    logic M00_AXI_bvalid;
    logic [31:0] M00_AXI_rdata;
    logic M00_AXI_rready;
    logic [1:0] M00_AXI_rresp;
    logic M00_AXI_rvalid;
    logic [31:0] M00_AXI_wdata;
    logic M00_AXI_wready;
    logic [3:0] M00_AXI_wstrb;
    logic M00_AXI_wvalid;

    // Zynq system
    zynq_block_wrapper zynq
        (ACLK,
         ARESETN,
         DDR_addr,
         DDR_ba,
         DDR_cas_n,
         DDR_ck_n,
         DDR_ck_p,
         DDR_cke,
         DDR_cs_n,
         DDR_dm,
         DDR_dq,
         DDR_dqs_n,
         DDR_dqs_p,
         DDR_odt,
         DDR_ras_n,
         DDR_reset_n,
         DDR_we_n,
         FIXED_IO_ddr_vrn,
         FIXED_IO_ddr_vrp,
         FIXED_IO_mio,
         FIXED_IO_ps_clk,
         FIXED_IO_ps_porb,
         FIXED_IO_ps_srstb,
         M00_AXI_araddr,
         M00_AXI_arprot,
         M00_AXI_arready,
         M00_AXI_arvalid,
         M00_AXI_awaddr,
         M00_AXI_awprot,
         M00_AXI_awready,
         M00_AXI_awvalid,
         M00_AXI_bready,
         M00_AXI_bresp,
         M00_AXI_bvalid,
         M00_AXI_rdata,
         M00_AXI_rready,
         M00_AXI_rresp,
         M00_AXI_rvalid,
         M00_AXI_wdata,
         M00_AXI_wready,
         M00_AXI_wstrb,
         M00_AXI_wvalid);

    // Our device.
    block_test_system bts
        (.S_AXI_ACLK(ACLK), // Positive-edge triggered.
         .S_AXI_ARESETN(ARESETN), // Active low.
         .S_AXI_AWADDR(M00_AXI_awaddr),
         .S_AXI_AWPROT(M00_AXI_awprot),
         .S_AXI_AWVALID(M00_AXI_awvalid),
         .S_AXI_AWREADY(M00_AXI_awready),
         .S_AXI_WDATA(M00_AXI_wdata),
         .S_AXI_WSTRB(M00_AXI_wstrb),
         .S_AXI_WVALID(M00_AXI_wvalid),
         .S_AXI_WREADY(M00_AXI_wready),
         .S_AXI_BRESP(M00_AXI_bresp),
         .S_AXI_BVALID(M00_AXI_bvalid),
         .S_AXI_BREADY(M00_AXI_bready),
         .S_AXI_ARADDR(M00_AXI_araddr),
         .S_AXI_ARPROT(M00_AXI_arprot),
         .S_AXI_ARVALID(M00_AXI_arvalid),
         .S_AXI_ARREADY(M00_AXI_arready),
         .S_AXI_RDATA(M00_AXI_rdata),
         .S_AXI_RRESP(M00_AXI_rresp),
         .S_AXI_RVALID(M00_AXI_rvalid),
         .S_AXI_RREADY(M00_AXI_rready));
endmodule
