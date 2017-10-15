/*
 * A Verilog compatible top-level synthesis target.
 */

`include "processing_element.svh"

module processing_element_top
    (input clock, // Positive-edge triggered.
     input reset, // Active high.
     input enable, // Active high.
     input execute, // Active high.
     output halted, // High when execution finished.
     output channels_quiescent, // High when there are no packets left in the buffers.
     output router_quiescent, // High when there are no packets left in the router buffers.
     // We have to break out the host interface into its constituent signals.
     input host_interface_read_req,
     output host_interface_read_ack,
     input [TIA_MMIO_INDEX_WIDTH - 1:0] host_interface_read_index,
     output [TIA_MMIO_DATA_WIDTH - 1:0] host_interface_read_data,
     input host_interface_write_req,
     output host_interface_write_ack,
     input [TIA_MMIO_INDEX_WIDTH - 1:0] host_interface_write_index,
     input [TIA_MMIO_DATA_WIDTH - 1:0] host_interface_write_data,
     // We have to do the same for the input and output link interfaces.
     input [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] north_input_interconnect_link_tag_lines,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] north_input_interconnect_link_data_lines,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] north_input_interconnect_link_reqs,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] north_input_interconnect_link_acks,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] east_input_interconnect_link_tag_lines,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] east_input_interconnect_link_data_lines,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] east_input_interconnect_link_reqs,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] east_input_interconnect_link_acks,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] south_input_interconnect_link_tag_lines,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] south_input_interconnect_link_data_lines,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] south_input_interconnect_link_reqs,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] south_input_interconnect_link_acks,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] west_input_interconnect_link_tag_lines,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] west_input_interconnect_link_data_lines,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] west_input_interconnect_link_reqs,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] west_input_interconnect_link_acks,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] north_output_interconnect_link_tag_lines,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] north_output_interconnect_link_data_lines,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] north_output_interconnect_link_reqs,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] north_output_interconnect_link_acks,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] east_output_interconnect_link_tag_lines,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] east_output_interconnect_link_data_lines,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] east_output_interconnect_link_reqs,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] east_output_interconnect_link_acks,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] south_output_interconnect_link_tag_lines,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] south_output_interconnect_link_data_lines,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] south_output_interconnect_link_reqs,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] south_output_interconnect_link_acks,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] west_output_interconnect_link_tag_lines,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] west_output_interconnect_link_data_lines,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] west_output_interconnect_link_reqs,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] west_output_interconnect_link_acks);

    // Wrap the host interface.
    mmio_if host_interface();
    assign host_interface.read_req = host_interface_read_req;
    assign host_interface_read_ack = host_interface.read_ack;
    assign host_interface.read_index = host_interface_read_index;
    assign host_interface_read_data = host_interface.read_data;
    assign host_interface.write_req = host_interface_write_req;
    assign host_interface_write_ack = host_interface.write_ack;
    assign host_interface.write_index = host_interface_write_index;
    assign host_interface.write_data = host_interface_write_data;

    // Wrap the input interconnect links.
    interconnect_link_if north_input_interconnect_link();
    interconnect_link_if east_input_interconnect_link();
    interconnect_link_if south_input_interconnect_link();
    interconnect_link_if west_input_interconnect_link();
    assign north_input_interconnect_link.reqs = north_input_interconnect_link_reqs;
    assign north_input_interconnect_link_acks = north_input_interconnect_link.acks;
    assign east_input_interconnect_link.reqs = east_input_interconnect_link_reqs;
    assign east_input_interconnect_link_acks = east_input_interconnect_link.acks;
    assign south_input_interconnect_link.reqs = south_input_interconnect_link_reqs;
    assign south_input_interconnect_link_acks = south_input_interconnect_link.acks;
    assign west_input_interconnect_link.reqs = west_input_interconnect_link_reqs;
    assign west_input_interconnect_link_acks = west_input_interconnect_link.acks;
    genvar i;
    generate
        for (i = 0; i < TIA_NUM_PHYSICAL_PLANES; i++) begin
            assign north_input_interconnect_link.tag_lines[i] = north_input_interconnect_link_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH];
            assign north_input_interconnect_link.data_lines[i] = north_input_interconnect_link_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH];
            assign east_input_interconnect_link.tag_lines[i] = east_input_interconnect_link_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH];
            assign east_input_interconnect_link.data_lines[i] = east_input_interconnect_link_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH];
            assign south_input_interconnect_link.tag_lines[i] = south_input_interconnect_link_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH];
            assign south_input_interconnect_link.data_lines[i] = south_input_interconnect_link_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH];
            assign west_input_interconnect_link.tag_lines[i] = west_input_interconnect_link_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH];
            assign west_input_interconnect_link.data_lines[i] = west_input_interconnect_link_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH];
        end
    endgenerate

    // Wrap the output links.
    interconnect_link_if north_output_interconnect_link();
    interconnect_link_if east_output_interconnect_link();
    interconnect_link_if south_output_interconnect_link();
    interconnect_link_if west_output_interconnect_link();
    assign north_output_interconnect_link_reqs = north_output_interconnect_link.reqs;
    assign north_output_interconnect_link.acks = north_output_interconnect_link_acks;
    assign east_output_interconnect_link_reqs = east_output_interconnect_link.reqs;
    assign east_output_interconnect_link.acks = east_output_interconnect_link_acks;
    assign south_output_interconnect_link_reqs = south_output_interconnect_link.reqs;
    assign south_output_interconnect_link.acks = south_output_interconnect_link_acks;
    assign west_output_interconnect_link_reqs = west_output_interconnect_link.reqs;
    assign west_output_interconnect_link.acks = west_output_interconnect_link_acks;
    genvar j;
    generate
        for (j = 0; j < TIA_NUM_PHYSICAL_PLANES; j++) begin
            assign north_output_interconnect_link_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH] = north_output_interconnect_link.tag_lines[j];
            assign north_output_interconnect_link_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH] = north_output_interconnect_link.data_lines[j];
            assign east_output_interconnect_link_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH] = east_output_interconnect_link.tag_lines[j];
            assign east_output_interconnect_link_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH] = east_output_interconnect_link.data_lines[j];
            assign south_output_interconnect_link_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH] = south_output_interconnect_link.tag_lines[j];
            assign south_output_interconnect_link_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH] = south_output_interconnect_link.data_lines[j];
            assign west_output_interconnect_link_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH] = west_output_interconnect_link.tag_lines[j];
            assign west_output_interconnect_link_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH] = west_output_interconnect_link.data_lines[j];
        end
    endgenerate

    // Target.
    processing_element pe(.clock(clock),
                          .reset(reset),
                          .enable(enable),
                          .execute(execute),
                          .halted(halted),
                          .channels_quiescent(channels_quiescent),
                          .router_quiescent(router_quiescent),
                          .host_interface(host_interface),
                          .north_input_interconnect_link(north_input_interconnect_link),
                          .east_input_interconnect_link(east_input_interconnect_link),
                          .south_input_interconnect_link(south_input_interconnect_link),
                          .west_input_interconnect_link(west_input_interconnect_link),
                          .north_output_interconnect_link(north_output_interconnect_link),
                          .east_output_interconnect_link(east_output_interconnect_link),
                          .south_output_interconnect_link(south_output_interconnect_link),
                          .west_output_interconnect_link(west_output_interconnect_link));
endmodule
