/*
 * A block (four quartets) module.
 */

`include "block.svh"

module block
    (input logic clock, // Positive-edge triggered.
     input logic reset, // Active high.
     input logic enable, // Active high.
     input logic execute, // Active high.
     output logic halted, // High when execution finished.
     output logic channels_quiescent, // High when there are no packets left in the channel buffers.
     output logic routers_quiescent, // High when there are no packets left in the router buffers.
     mmio_if.device host_interface,
     interconnect_link_if.receiver north_input_interconnect_links [3:0],
     interconnect_link_if.receiver south_input_interconnect_links [3:0],
     interconnect_link_if.receiver east_input_interconnect_links [3:0],
     interconnect_link_if.receiver west_input_interconnect_links [3:0],
     interconnect_link_if.sender north_output_interconnect_links [3:0],
     interconnect_link_if.sender south_output_interconnect_links [3:0],
     interconnect_link_if.sender east_output_interconnect_links [3:0],
     interconnect_link_if.sender west_output_interconnect_links [3:0]);

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
    logic quartet_0_halted, quartet_1_halted, quartet_2_halted, quartet_3_halted;
    always_ff @(posedge clock) begin
        halted <= (quartet_0_halted
                   && quartet_1_halted
                   && quartet_2_halted
                   && quartet_3_halted);
    end

    // Buffer the channels quiescent signal.
    logic quartet_0_channels_quiescent, quartet_1_channels_quiescent,
          quartet_2_channels_quiescent, quartet_3_channels_quiescent;
    always_ff @(posedge clock) begin
        channels_quiescent <= (quartet_0_channels_quiescent
                               && quartet_1_channels_quiescent
                               && quartet_2_channels_quiescent
                               && quartet_3_channels_quiescent);
    end

    // Buffer the routers quiescent signal.
    logic quartet_0_routers_quiescent, quartet_1_routers_quiescent,
          quartet_2_routers_quiescent, quartet_3_routers_quiescent;
    always_ff @(posedge clock) begin
        routers_quiescent <= (quartet_0_routers_quiescent
                              && quartet_1_routers_quiescent
                              && quartet_2_routers_quiescent
                              && quartet_3_routers_quiescent);
    end

    // --- MMIO Mapping and Buffering ---

    // Buffer the host interface.
    mmio_if buffered_host_interface();
    mmio_buffer himb(.clock(clock),
                     .reset(reset),
                     .host_interface(host_interface),
                     .device_interface(buffered_host_interface));

    // Split the MMIO interface between the four quartets.
    mmio_if quartet_0_interface();
    mmio_if quartet_1_interface();
    mmio_if quartet_2_interface();
    mmio_if quartet_3_interface();
    four_way_address_space_splitter #(.NUM_SUBSPACE_WORDS(TIA_NUM_QUARTET_ADDRESS_SPACE_WORDS))
           fwass(.host_interface(buffered_host_interface),
                 .first_device_interface(quartet_0_interface),
                 .second_device_interface(quartet_1_interface),
                 .third_device_interface(quartet_2_interface),
                 .fourth_device_interface(quartet_3_interface));

    // --- Quartet Array ---

    // Interconnect links.
    interconnect_link_if northbound_interconnect_links[3:0]();
    interconnect_link_if eastbound_interconnect_links[3:0]();
    interconnect_link_if southbound_interconnect_links[3:0]();
    interconnect_link_if westbound_interconnect_links[3:0]();

    // Hooking up control signals and links.
    quartet quartet_0(.clock(clock),
                      .reset(buffered_reset),
                      .enable(buffered_enable),
                      .execute(buffered_execute),
                      .halted(quartet_0_halted),
                      .channels_quiescent(quartet_0_channels_quiescent),
                      .routers_quiescent(quartet_0_routers_quiescent),
                      .host_interface(quartet_0_interface),
                      .north_input_interconnect_links(north_input_interconnect_links[1:0]),
                      .east_input_interconnect_links(westbound_interconnect_links[1:0]),
                      .south_input_interconnect_links(northbound_interconnect_links[1:0]),
                      .west_input_interconnect_links(west_input_interconnect_links[1:0]),
                      .north_output_interconnect_links(north_output_interconnect_links[1:0]),
                      .east_output_interconnect_links(eastbound_interconnect_links[1:0]),
                      .south_output_interconnect_links(southbound_interconnect_links[1:0]),
                      .west_output_interconnect_links(west_output_interconnect_links[1:0]));
    quartet quartet_1(.clock(clock),
                      .reset(buffered_reset),
                      .enable(buffered_enable),
                      .execute(buffered_execute),
                      .halted(quartet_1_halted),
                      .channels_quiescent(quartet_1_channels_quiescent),
                      .routers_quiescent(quartet_1_routers_quiescent),
                      .host_interface(quartet_1_interface),
                      .north_input_interconnect_links(north_input_interconnect_links[3:2]),
                      .east_input_interconnect_links(east_input_interconnect_links[1:0]),
                      .south_input_interconnect_links(northbound_interconnect_links[3:2]),
                      .west_input_interconnect_links(eastbound_interconnect_links[1:0]),
                      .north_output_interconnect_links(north_output_interconnect_links[3:2]),
                      .east_output_interconnect_links(east_output_interconnect_links[1:0]),
                      .south_output_interconnect_links(southbound_interconnect_links[3:2]),
                      .west_output_interconnect_links(westbound_interconnect_links[1:0]));
    quartet quartet_2(.clock(clock),
                      .reset(buffered_reset),
                      .enable(buffered_enable),
                      .execute(buffered_execute),
                      .halted(quartet_2_halted),
                      .channels_quiescent(quartet_2_channels_quiescent),
                      .routers_quiescent(quartet_2_routers_quiescent),
                      .host_interface(quartet_2_interface),
                      .north_input_interconnect_links(southbound_interconnect_links[1:0]),
                      .east_input_interconnect_links(westbound_interconnect_links[3:2]),
                      .south_input_interconnect_links(south_input_interconnect_links[1:0]),
                      .west_input_interconnect_links(west_input_interconnect_links[3:2]),
                      .north_output_interconnect_links(northbound_interconnect_links[1:0]),
                      .east_output_interconnect_links(eastbound_interconnect_links[3:2]),
                      .south_output_interconnect_links(south_output_interconnect_links[1:0]),
                      .west_output_interconnect_links(west_output_interconnect_links[3:2]));
    quartet quartet_3(.clock(clock),
                      .reset(buffered_reset),
                      .enable(buffered_enable),
                      .execute(buffered_execute),
                      .halted(quartet_3_halted),
                      .channels_quiescent(quartet_3_channels_quiescent),
                      .routers_quiescent(quartet_3_routers_quiescent),
                      .host_interface(quartet_3_interface),
                      .north_input_interconnect_links(southbound_interconnect_links[3:2]),
                      .east_input_interconnect_links(east_input_interconnect_links[3:2]),
                      .south_input_interconnect_links(south_input_interconnect_links[3:2]),
                      .west_input_interconnect_links(eastbound_interconnect_links[3:2]),
                      .north_output_interconnect_links(northbound_interconnect_links[3:2]),
                      .east_output_interconnect_links(east_output_interconnect_links[3:2]),
                      .south_output_interconnect_links(south_output_interconnect_links[3:2]),
                      .west_output_interconnect_links(westbound_interconnect_links[3:2]));
endmodule
