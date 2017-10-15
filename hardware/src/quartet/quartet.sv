/*
 * A quartet (four PEs) module.
 */

`include "quartet.svh"

module quartet
    (input logic clock, // Positive-edge triggered.
     input logic reset, // Active high.
     input logic enable, // Active high.
     input logic execute, // Active high.
     output logic halted, // High when execution finished.
     output logic channels_quiescent, // High when there are no packets left in the channel buffers.
     output logic routers_quiescent, // High when there are no packets left in the router buffers.
     mmio_if.device host_interface,
     interconnect_link_if.receiver north_input_interconnect_links [1:0],
     interconnect_link_if.receiver south_input_interconnect_links [1:0],
     interconnect_link_if.receiver east_input_interconnect_links [1:0],
     interconnect_link_if.receiver west_input_interconnect_links [1:0],
     interconnect_link_if.sender north_output_interconnect_links [1:0],
     interconnect_link_if.sender south_output_interconnect_links [1:0],
     interconnect_link_if.sender east_output_interconnect_links [1:0],
     interconnect_link_if.sender west_output_interconnect_links [1:0]);

    // --- Control Signal Wiring and Buffering ---

    // Buffer the external reset.
    logic buffered_reset;
    always_ff @(posedge clock)
        buffered_reset <= reset;

    // Buffer the external enable.
    logic buffered_enable;
    always_ff @(posedge clock)
        buffered_enable <= enable;

    // Buffer the external execute signal.
    logic buffered_execute;
    always_ff @(posedge clock)
        buffered_execute <= execute;

    // Buffer the halted signal.
    logic pe_0_halted, pe_1_halted, pe_2_halted, pe_3_halted;
    always_ff @(posedge clock) begin
        halted <= (pe_0_halted
                   && pe_1_halted
                   && pe_2_halted
                   && pe_3_halted);
    end

    // Buffer the channels quiescent signal.
    logic pe_0_channels_quiescent, pe_1_channels_quiescent,
          pe_2_channels_quiescent, pe_3_channels_quiescent;
    always_ff @(posedge clock) begin
        channels_quiescent <= (pe_0_channels_quiescent
                               && pe_1_channels_quiescent
                               && pe_2_channels_quiescent
                               && pe_3_channels_quiescent);
    end

    // Buffer the routers quiescent signal.
    logic pe_0_router_quiescent, pe_1_router_quiescent,
          pe_2_router_quiescent, pe_3_router_quiescent;
    always_ff @(posedge clock) begin
        routers_quiescent <= (pe_0_router_quiescent
                              && pe_1_router_quiescent
                              && pe_2_router_quiescent
                              && pe_3_router_quiescent);
    end

    // --- MMIO Mapping and Buffering ---

    // Buffer the host interface.
    mmio_if buffered_host_interface();
    mmio_buffer himb(.clock(clock),
                     .reset(reset),
                     .host_interface(host_interface),
                     .device_interface(buffered_host_interface));

    // Split the MMIO interface between the four PEs.
    mmio_if pe_0_interface();
    mmio_if pe_1_interface();
    mmio_if pe_2_interface();
    mmio_if pe_3_interface();
    four_way_address_space_splitter #(.NUM_SUBSPACE_WORDS(TIA_NUM_PROCESSING_ELEMENT_ADDRESS_SPACE_WORDS))
           fwass(.host_interface(buffered_host_interface),
                 .first_device_interface(pe_0_interface),
                 .second_device_interface(pe_1_interface),
                 .third_device_interface(pe_2_interface),
                 .fourth_device_interface(pe_3_interface));

    // --- Processing Element Array ---

    // Interconnect links.
    interconnect_link_if northbound_interconnect_links[1:0]();
    interconnect_link_if eastbound_interconnect_links[1:0]();
    interconnect_link_if southbound_interconnect_links[1:0]();
    interconnect_link_if westbound_interconnect_links[1:0]();

    // Hooking up control signals and links.
    processing_element pe_0(.clock(clock),
                            .reset(buffered_reset),
                            .enable(buffered_enable),
                            .execute(buffered_execute),
                            .halted(pe_0_halted),
                            .channels_quiescent(pe_0_channels_quiescent),
                            .router_quiescent(pe_0_router_quiescent),
                            .host_interface(pe_0_interface),
                            .north_input_interconnect_link(north_input_interconnect_links[0]),
                            .east_input_interconnect_link(westbound_interconnect_links[0]),
                            .south_input_interconnect_link(northbound_interconnect_links[0]),
                            .west_input_interconnect_link(west_input_interconnect_links[0]),
                            .north_output_interconnect_link(north_output_interconnect_links[0]),
                            .east_output_interconnect_link(eastbound_interconnect_links[0]),
                            .south_output_interconnect_link(southbound_interconnect_links[0]),
                            .west_output_interconnect_link(west_output_interconnect_links[0]));
    processing_element pe_1(.clock(clock),
                            .reset(buffered_reset),
                            .enable(buffered_enable),
                            .execute(buffered_execute),
                            .halted(pe_1_halted),
                            .channels_quiescent(pe_1_channels_quiescent),
                            .router_quiescent(pe_1_router_quiescent),
                            .host_interface(pe_1_interface),
                            .north_input_interconnect_link(north_input_interconnect_links[1]),
                            .east_input_interconnect_link(east_input_interconnect_links[0]),
                            .south_input_interconnect_link(northbound_interconnect_links[1]),
                            .west_input_interconnect_link(eastbound_interconnect_links[0]),
                            .north_output_interconnect_link(north_output_interconnect_links[1]),
                            .east_output_interconnect_link(east_output_interconnect_links[0]),
                            .south_output_interconnect_link(southbound_interconnect_links[1]),
                            .west_output_interconnect_link(westbound_interconnect_links[0]));
    processing_element pe_2(.clock(clock),
                            .reset(buffered_reset),
                            .enable(buffered_enable),
                            .execute(buffered_execute),
                            .halted(pe_2_halted),
                            .channels_quiescent(pe_2_channels_quiescent),
                            .router_quiescent(pe_2_router_quiescent),
                            .host_interface(pe_2_interface),
                            .north_input_interconnect_link(southbound_interconnect_links[0]),
                            .east_input_interconnect_link(westbound_interconnect_links[1]),
                            .south_input_interconnect_link(south_input_interconnect_links[0]),
                            .west_input_interconnect_link(west_input_interconnect_links[1]),
                            .north_output_interconnect_link(northbound_interconnect_links[0]),
                            .east_output_interconnect_link(eastbound_interconnect_links[1]),
                            .south_output_interconnect_link(south_output_interconnect_links[0]),
                            .west_output_interconnect_link(west_output_interconnect_links[1]));
    processing_element pe_3(.clock(clock),
                            .reset(buffered_reset),
                            .enable(buffered_enable),
                            .execute(buffered_execute),
                            .halted(pe_3_halted),
                            .channels_quiescent(pe_3_channels_quiescent),
                            .router_quiescent(pe_3_router_quiescent),
                            .host_interface(pe_3_interface),
                            .north_input_interconnect_link(southbound_interconnect_links[1]),
                            .east_input_interconnect_link(east_input_interconnect_links[1]),
                            .south_input_interconnect_link(south_input_interconnect_links[1]),
                            .west_input_interconnect_link(eastbound_interconnect_links[1]),
                            .north_output_interconnect_link(northbound_interconnect_links[1]),
                            .east_output_interconnect_link(east_output_interconnect_links[1]),
                            .south_output_interconnect_link(south_output_interconnect_links[1]),
                            .west_output_interconnect_link(westbound_interconnect_links[1]));
endmodule
