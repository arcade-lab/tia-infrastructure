/*
 * Combined core/router unit.
 */

`include "processing_element.svh"

module processing_element
    (input logic clock, // Positive-edge triggered.
     input logic reset, // Active high.
     input logic enable, // Active high.
     input logic execute, // Active high.
     output logic halted, // High when execution finished.
     output logic channels_quiescent, // High when there are no packets left in the channel buffers.
     output logic router_quiescent, // High when there are no packets left in the router buffers.
     mmio_if.device host_interface,
     interconnect_link_if.receiver north_input_interconnect_link,
     interconnect_link_if.receiver east_input_interconnect_link,
     interconnect_link_if.receiver south_input_interconnect_link,
     interconnect_link_if.receiver west_input_interconnect_link,
     interconnect_link_if.sender north_output_interconnect_link,
     interconnect_link_if.sender east_output_interconnect_link,
     interconnect_link_if.sender south_output_interconnect_link,
     interconnect_link_if.sender west_output_interconnect_link);

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
    logic halted_signal;
    always_ff @(posedge clock)
        halted <= halted_signal;

    // Buffer the channels quiescent signal.
    logic channels_quiescent_signal;
    always_ff @(posedge clock)
        channels_quiescent <= channels_quiescent_signal;

    // Buffer the routers quiescent signal.
    logic router_quiescent_signal;
    always_ff @(posedge clock)
        router_quiescent <= router_quiescent_signal;

    // --- MMIO Mapping and Buffering ---

    // Buffer the host interface.
    mmio_if buffered_host_interface();
    mmio_buffer himb(.clock(clock),
                     .reset(reset),
                     .host_interface(host_interface),
                     .device_interface(buffered_host_interface));

    // Internal MMIO bus.
    mmio_if core_interface();
    mmio_if router_interface();

    // Memory map.
    processing_element_mapper pemap(.host_interface(buffered_host_interface),
                                    .core_interface(core_interface),
                                    .router_interface(router_interface));

    // Internal links.
    link_if input_channel_links[TIA_NUM_INPUT_CHANNELS - 1:0]();
    link_if output_channel_links[TIA_NUM_OUTPUT_CHANNELS - 1:0]();

    // Processing element core.
    `TIA_CORE core(.clock(clock),
                   .reset(buffered_reset),
                   .enable(buffered_enable),
                   .execute(buffered_execute),
                   .halted(halted_signal),
                   .channels_quiescent(channels_quiescent_signal),
                   .host_interface(core_interface),
                   .input_channel_links(input_channel_links),
                   .output_channel_links(output_channel_links));

    // Processing element router.
    `TIA_ROUTER router(.clock(clock),
                       .reset(reset),
                       .enable(enable),
                       .quiescent(router_quiescent_signal),
                       .host_interface(router_interface),
                       .north_input_interconnect_link(north_input_interconnect_link),
                       .east_input_interconnect_link(east_input_interconnect_link),
                       .south_input_interconnect_link(south_input_interconnect_link),
                       .west_input_interconnect_link(west_input_interconnect_link),
                       .north_output_interconnect_link(north_output_interconnect_link),
                       .east_output_interconnect_link(east_output_interconnect_link),
                       .south_output_interconnect_link(south_output_interconnect_link),
                       .west_output_interconnect_link(west_output_interconnect_link),
                       .input_channel_links(input_channel_links),
                       .output_channel_links(output_channel_links));
endmodule

