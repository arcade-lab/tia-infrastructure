/*
 * Generic AXI4-Lite slave interface derived heavily from the Xilinx template. The most significant
 * change is the fact that its channel FSMs have been entirely rewritten to support an internal req
 * and ack based LID MMIO protocol.
 */

`include "mmio.svh"

module axi4_lite_interface
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
     output logic read_req,
     input logic read_ack,
     output logic [AXI4_LITE_ADDRESS_WIDTH - 1:0] read_address,
     input logic [AXI4_LITE_DATA_WIDTH - 1:0] read_data,
     output logic write_req,
     input logic write_ack,
     output logic [AXI4_LITE_ADDRESS_WIDTH - 1:0] write_address,
     output logic [AXI4_LITE_DATA_WIDTH - 1:0] write_data);

    // --- Write Channel ---

    // Generate the S_AXI_AWREADY signal.
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN)
            S_AXI_AWREADY <= 0;
        else begin
            if (!S_AXI_AWREADY && S_AXI_AWVALID && S_AXI_WVALID)
                S_AXI_AWREADY <= 1;
            else
                S_AXI_AWREADY <= 0;
        end
    end

    // Latch in valid write addresses.
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN)
            write_address <= 0;
        else if (!S_AXI_AWREADY && S_AXI_AWVALID && S_AXI_WVALID)
            write_address <= S_AXI_AWADDR;
    end

    // Generate the S_AXI_WREADY signal.
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN)
            S_AXI_WREADY <= 0;
        else begin
            if (!S_AXI_WREADY && S_AXI_WVALID && S_AXI_AWVALID)
                S_AXI_WREADY <= 1;
            else
                S_AXI_WREADY <= 0;
        end
    end

    // Write out data to the slave (we discard the write strobe since all our operations are
    // 32-bits.
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN)
            write_data <= 0;
        else if (S_AXI_WREADY && S_AXI_WVALID)
            write_data <= S_AXI_WDATA;
    end

    // --- MMIO-Compliant Writes ---

    // Wait for the internal MMIO protocol to perform the write.
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN)
            write_req <= 0;
        else begin
            if (S_AXI_WREADY && S_AXI_WVALID && S_AXI_AWREADY && S_AXI_AWVALID && !write_req)
                write_req <= 1;
            else if (write_req && write_ack)
                write_req <= 0;
        end
    end

    // --- Write Response Channel ---

    // Generate a write response.
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_BVALID <= 0;
            S_AXI_BRESP <= 0;
        end else begin
            if (write_req && write_ack && !S_AXI_BVALID) begin
                S_AXI_BVALID <= 1;
                S_AXI_BRESP <= 0;
            end else if (S_AXI_BREADY && S_AXI_BVALID)
                S_AXI_BVALID <= 0;
        end
    end

    // --- Read Channel ---

    // Generate the S_AXI_ARREADY signal, and latch in the read address.
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_ARREADY <= 0;
            read_address <= 0;
        end else begin
            if (!S_AXI_ARREADY && S_AXI_ARVALID) begin
                S_AXI_ARREADY <= 1;
                read_address <= S_AXI_ARADDR;
            end else if (read_req && read_ack)
                S_AXI_ARREADY <= 0;
        end
    end

    // Generate the S_AXI_RVALID and S_AXI_RRESP signals.
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_RVALID <= 0;
            S_AXI_RRESP <= 0;
        end else begin
            if (read_req && read_ack && !S_AXI_RVALID) begin
                S_AXI_RVALID <= 1;
                S_AXI_RRESP <= 0;
            end else if (S_AXI_RVALID && S_AXI_RREADY)
                S_AXI_RVALID <= 0;
        end
    end

    // Output the read data onto the bus.
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN)
            S_AXI_RDATA <= 0;
        else if (read_req && read_ack)
            S_AXI_RDATA <= read_data;
    end

    // --- MMIO-Compliant Reads ---

    // Wait for the internal MMIO protocol to perform the read.
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN)
            read_req <= 0;
        else begin
            if (S_AXI_ARREADY && S_AXI_ARVALID && !S_AXI_RVALID)
                read_req <= 1;
            else if (read_req && read_ack)
                read_req <= 0;
        end
    end
endmodule
