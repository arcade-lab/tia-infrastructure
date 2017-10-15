/*
 * Simple width-adjusting bridge between AXI4-Lite and MMIO.
 */

`include "mmio.svh"

module axi4_lite_to_mmio_bridge
    (input logic S_AXI_ACLK, // Positive-edge triggered.
     input logic S_AXI_ARESETN, // Active low.
     input logic [AXI4_LITE_ADDRESS_WIDTH - 1:0] S_AXI_AWADDR,
     input logic [2:0] S_AXI_AWPROT,
     input logic S_AXI_AWVALID,
     output logic S_AXI_AWREADY,
     input logic [AXI4_LITE_DATA_WIDTH - 1:0] S_AXI_WDATA,
     input logic [AXI4_LITE_DATA_WIDTH / 8 - 1:0] S_AXI_WSTRB,
     input logic S_AXI_WVALID,
     output logic S_AXI_WREADY,
     output logic [1:0] S_AXI_BRESP,
     output logic S_AXI_BVALID,
     input logic S_AXI_BREADY,
     input logic [AXI4_LITE_ADDRESS_WIDTH - 1:0] S_AXI_ARADDR,
     input logic [2:0] S_AXI_ARPROT,
     input logic S_AXI_ARVALID,
     output logic S_AXI_ARREADY,
     output logic [AXI4_LITE_DATA_WIDTH - 1:0] S_AXI_RDATA,
     output logic [1:0] S_AXI_RRESP,
     output logic S_AXI_RVALID,
     input logic S_AXI_RREADY,
     mmio_if.host host_interface);

    // --- Internal Logic and Wiring ---

    // AXI4-Lite declarations.
    logic axi4_lite_read_req;
    logic axi4_lite_read_ack;
    logic [AXI4_LITE_ADDRESS_WIDTH - 1:0] axi4_lite_read_address;
    logic [AXI4_LITE_DATA_WIDTH - 1:0] axi4_lite_read_data;
    logic axi4_lite_write_req;
    logic axi4_lite_write_ack;
    logic [AXI4_LITE_ADDRESS_WIDTH - 1:0] axi4_lite_write_address;
    logic [AXI4_LITE_DATA_WIDTH - 1:0] axi4_lite_write_data;

    // AXI4-Lite interface.
    axi4_lite_interface ali(S_AXI_ACLK,
                            S_AXI_ARESETN,
                            S_AXI_AWADDR,
                            S_AXI_AWPROT,
                            S_AXI_AWVALID,
                            S_AXI_AWREADY,
                            S_AXI_WDATA,
                            S_AXI_WSTRB,
                            S_AXI_WVALID,
                            S_AXI_WREADY,
                            S_AXI_BRESP,
                            S_AXI_BVALID,
                            S_AXI_BREADY,
                            S_AXI_ARADDR,
                            S_AXI_ARPROT,
                            S_AXI_ARVALID,
                            S_AXI_ARREADY,
                            S_AXI_RDATA,
                            S_AXI_RRESP,
                            S_AXI_RVALID,
                            S_AXI_RREADY,
                            axi4_lite_read_req,
                            axi4_lite_read_ack,
                            axi4_lite_read_address,
                            axi4_lite_read_data,
                            axi4_lite_write_req,
                            axi4_lite_write_ack,
                            axi4_lite_write_address,
                            axi4_lite_write_data);

    // --- Combinational Logic ---

    // Mapping onto MMIO.
    assign host_interface.read_req = axi4_lite_read_req;
    assign axi4_lite_read_ack = host_interface.read_ack;
    assign host_interface.read_index =
        axi4_lite_read_address[AXI4_LITE_ADDRESS_WIDTH - 1:AXI4_LITE_ADDRESS_WIDTH - TIA_MMIO_INDEX_WIDTH];
    assign axi4_lite_read_data = host_interface.read_data;
    assign host_interface.write_req = axi4_lite_write_req;
    assign axi4_lite_write_ack = host_interface.write_ack;
    assign host_interface.write_index =
        axi4_lite_write_address[AXI4_LITE_ADDRESS_WIDTH - 1:AXI4_LITE_ADDRESS_WIDTH - TIA_MMIO_INDEX_WIDTH];
    assign host_interface.write_data = axi4_lite_write_data;
endmodule
