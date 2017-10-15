/*
 * Test system for an individual PE.
 */

`ifdef ASIC_SYNTHESIS
    `include "processing_element.svh"
`elsif FPGA_SYNTHESIS
    `include "processing_element.svh"
`elsif SIMULATION
    `include "../processing_element/processing_element.svh"
`else
    `include "processing_element.svh"
`endif

module processing_element_test_system
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
     input logic S_AXI_RREADY);

    // --- AXI4-Lite to Generic MMIO Bridge ---

    // Top-level MMIO interface.
    mmio_if host_interface();

    // Protocol bridge.
    axi4_lite_to_mmio_bridge altmb(.S_AXI_ACLK(S_AXI_ACLK),
                                   .S_AXI_ARESETN(S_AXI_ARESETN),
                                   .S_AXI_AWADDR(S_AXI_AWADDR),
                                   .S_AXI_AWPROT(S_AXI_AWPROT),
                                   .S_AXI_AWVALID(S_AXI_AWVALID),
                                   .S_AXI_AWREADY(S_AXI_AWREADY),
                                   .S_AXI_WDATA(S_AXI_WDATA),
                                   .S_AXI_WSTRB(S_AXI_WSTRB),
                                   .S_AXI_WVALID(S_AXI_WVALID),
                                   .S_AXI_WREADY(S_AXI_WREADY),
                                   .S_AXI_BRESP(S_AXI_BRESP),
                                   .S_AXI_BVALID(S_AXI_BVALID),
                                   .S_AXI_BREADY(S_AXI_BREADY),
                                   .S_AXI_ARADDR(S_AXI_ARADDR),
                                   .S_AXI_ARPROT(S_AXI_ARPROT),
                                   .S_AXI_ARVALID(S_AXI_ARVALID),
                                   .S_AXI_ARREADY(S_AXI_ARREADY),
                                   .S_AXI_RDATA(S_AXI_RDATA),
                                   .S_AXI_RRESP(S_AXI_RRESP),
                                   .S_AXI_RVALID(S_AXI_RVALID),
                                   .S_AXI_RREADY(S_AXI_RREADY),
                                   .host_interface(host_interface));

    // --- System Memory Mapper ---

    // Mapped interfaces.
    mmio_if control_interface();
    mmio_if processing_element_interface();
    mmio_if memory_interface();

    // Control and signal wires.
    logic system_reset, system_enable, system_execute,
          pe_halted, pe_channels_quiescent, memory_quiescent, system_halted;

    // Bufferent host MMIO interface.
    mmio_if buffered_host_interface();

    // Wiring the buffered host MMIO interface.
    mmio_buffer himb(.clock(S_AXI_ACLK),
                     .reset(~S_AXI_ARESETN),
                     .host_interface(host_interface),
                     .device_interface(buffered_host_interface));

    // Spitting the memory domains up by function.
    processing_element_test_system_mapper petsm(.host_interface(buffered_host_interface),
                                                .control_interface(control_interface),
                                                .processing_element_interface(processing_element_interface),
                                                .memory_interface(memory_interface));

    // Buffered system MMIO interfaces.
    mmio_if buffered_control_interface();
    mmio_if buffered_processing_element_interface();
    mmio_if buffered_memory_interface();

    // Wiring the buffered system MMIO interfaces.
    mmio_buffer cimb(.clock(S_AXI_ACLK),
                     .reset(~S_AXI_ARESETN),
                     .host_interface(control_interface),
                     .device_interface(buffered_control_interface));
    mmio_buffer peimb(.clock(S_AXI_ACLK),
                      .reset(~S_AXI_ARESETN),
                      .host_interface(processing_element_interface),
                      .device_interface(buffered_processing_element_interface));
    mmio_buffer mimb(.clock(S_AXI_ACLK),
                     .reset(~S_AXI_ARESETN),
                     .host_interface(memory_interface),
                     .device_interface(buffered_memory_interface));

    // --- System Control Registers ---

    // System control registers.
    system_control_registers scr(.clock(S_AXI_ACLK),
                                 .reset(~S_AXI_ARESETN),
                                 .host_interface(buffered_control_interface),
                                 .system_reset(system_reset),
                                 .system_enable(system_enable),
                                 .system_execute(system_execute),
                                 .system_halted(system_halted));

    // --- Processing Element ---

    // Links.
    interconnect_link_if input_interconnect_links[3:0]();
    interconnect_link_if output_interconnect_links[3:0]();
    link_if input_links[3:0]();
    link_if output_links[3:0]();

    // Converters.
    genvar i;
    generate
        for (i = 0; i < 4; i++) begin: converter
            interconnect_link_splitter ils
                (.input_link(input_links[i]),
                 .output_interconnect_link(input_interconnect_links[i]));
            interconnect_link_combiner ilc
                (.input_interconnect_link(output_interconnect_links[i]),
                 .output_link(output_links[i]));
        end
    endgenerate

    // Hooking up control signals and channels.
    processing_element pe(.clock(S_AXI_ACLK),
                          .reset(system_reset),
                          .enable(system_enable),
                          .execute(system_execute),
                          .halted(pe_halted),
                          .channels_quiescent(pe_channels_quiescent),
                          .host_interface(buffered_processing_element_interface),
                          .north_input_interconnect_link(input_interconnect_links[0]),
                          .east_input_interconnect_link(input_interconnect_links[1]),
                          .south_input_interconnect_link(input_interconnect_links[2]),
                          .west_input_interconnect_link(input_interconnect_links[3]),
                          .north_output_interconnect_link(output_interconnect_links[0]),
                          .east_output_interconnect_link(output_interconnect_links[1]),
                          .south_output_interconnect_link(output_interconnect_links[2]),
                          .west_output_interconnect_link(output_interconnect_links[3]));

    // Determine the system halt condition.
    assign system_halted = pe_halted && pe_channels_quiescent && memory_quiescent;;

    // Clean-up unused links.
    unused_link_sender uls2(input_links[2]);
    unused_link_sender uls3(input_links[3]);

    // --- Memory ---

    // Two read, one write memory.
    memory_2r_1w #(.DEPTH(TIA_NUM_DATA_MEMORY_WORDS))
        memory(.clock(S_AXI_ACLK),
               .reset(system_reset),
               .enable(1'b1), // Always on, for now.
               .host_interface(buffered_memory_interface),
               .read_index_0_input_link(output_links[0]),
               .read_data_0_output_link(input_links[0]),
               .read_index_1_input_link(output_links[1]),
               .read_data_1_output_link(input_links[1]),
               .write_index_input_link(output_links[2]),
               .write_data_input_link(output_links[3]),
               .quiescent(memory_quiescent));
endmodule
