/*
 * Software router.
 */

`include "interconnect.svh"

module software_router
    (input logic clock, // Positive-edge triggered.
     input logic reset, // Active high.
     input logic enable, // Active high.
     output logic quiescent, // High when the router is quiescent.
     mmio_if.device host_interface,
     interconnect_link_if.receiver north_input_interconnect_link,
     interconnect_link_if.receiver east_input_interconnect_link,
     interconnect_link_if.receiver south_input_interconnect_link,
     interconnect_link_if.receiver west_input_interconnect_link,
     interconnect_link_if.sender north_output_interconnect_link,
     interconnect_link_if.sender east_output_interconnect_link,
     interconnect_link_if.sender south_output_interconnect_link,
     interconnect_link_if.sender west_output_interconnect_link,
     link_if.sender input_channel_links [TIA_NUM_INPUT_CHANNELS - 1:0],
     link_if.receiver output_channel_links [TIA_NUM_OUTPUT_CHANNELS - 1:0]);

    // Router has no internal state.
    assign quiescent = 1;

    // There are no settings.
    unused_host_interface uhi(host_interface);

    // Use splitters and combiners to map from channels to the interconnect links.
    interconnect_link_combiner nilc(.input_interconnect_link(north_input_interconnect_link),
                                    .output_link(input_channel_links[0]));
    interconnect_link_combiner eilc(.input_interconnect_link(east_input_interconnect_link),
                                    .output_link(input_channel_links[1]));
    interconnect_link_combiner silc(.input_interconnect_link(south_input_interconnect_link),
                                    .output_link(input_channel_links[2]));
    interconnect_link_combiner wilc(.input_interconnect_link(west_input_interconnect_link),
                                    .output_link(input_channel_links[3]));
    interconnect_link_splitter nils(.input_link(output_channel_links[0]),
                                    .output_interconnect_link(north_output_interconnect_link));
    interconnect_link_splitter eils(.input_link(output_channel_links[1]),
                                    .output_interconnect_link(east_output_interconnect_link));
    interconnect_link_splitter sils(.input_link(output_channel_links[2]),
                                    .output_interconnect_link(south_output_interconnect_link));
    interconnect_link_splitter wils(.input_link(output_channel_links[3]),
                                    .output_interconnect_link(west_output_interconnect_link));
endmodule
