/*
 * A Verilog compatible top-level synthesis target.
 */

`include "block.svh"

module block_top
    (input clock, // Positive-edge triggered.
     input reset, // Active high.
     input enable, // Active high.
     input execute, // Active high.
     output halted, // High when execution finished.
     output channels_quiescent, // High when there are no packets left in the buffers.
     output routers_quiescent, // High when there are no packets left in the router buffers.
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
     input [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] north_input_interconnect_link_0_tag_lines,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] north_input_interconnect_link_0_data_lines,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] north_input_interconnect_link_0_reqs,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] north_input_interconnect_link_0_acks,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] north_input_interconnect_link_1_tag_lines,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] north_input_interconnect_link_1_data_lines,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] north_input_interconnect_link_1_reqs,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] north_input_interconnect_link_1_acks,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] north_input_interconnect_link_2_tag_lines,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] north_input_interconnect_link_2_data_lines,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] north_input_interconnect_link_2_reqs,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] north_input_interconnect_link_2_acks,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] north_input_interconnect_link_3_tag_lines,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] north_input_interconnect_link_3_data_lines,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] north_input_interconnect_link_3_reqs,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] north_input_interconnect_link_3_acks,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] east_input_interconnect_link_0_tag_lines,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] east_input_interconnect_link_0_data_lines,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] east_input_interconnect_link_0_reqs,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] east_input_interconnect_link_0_acks,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] east_input_interconnect_link_1_tag_lines,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] east_input_interconnect_link_1_data_lines,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] east_input_interconnect_link_1_reqs,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] east_input_interconnect_link_1_acks,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] east_input_interconnect_link_2_tag_lines,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] east_input_interconnect_link_2_data_lines,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] east_input_interconnect_link_2_reqs,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] east_input_interconnect_link_2_acks,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] east_input_interconnect_link_3_tag_lines,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] east_input_interconnect_link_3_data_lines,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] east_input_interconnect_link_3_reqs,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] east_input_interconnect_link_3_acks,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] south_input_interconnect_link_0_tag_lines,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] south_input_interconnect_link_0_data_lines,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] south_input_interconnect_link_0_reqs,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] south_input_interconnect_link_0_acks,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] south_input_interconnect_link_1_tag_lines,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] south_input_interconnect_link_1_data_lines,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] south_input_interconnect_link_1_reqs,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] south_input_interconnect_link_1_acks,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] south_input_interconnect_link_2_tag_lines,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] south_input_interconnect_link_2_data_lines,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] south_input_interconnect_link_2_reqs,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] south_input_interconnect_link_2_acks,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] south_input_interconnect_link_3_tag_lines,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] south_input_interconnect_link_3_data_lines,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] south_input_interconnect_link_3_reqs,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] south_input_interconnect_link_3_acks,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] west_input_interconnect_link_0_tag_lines,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] west_input_interconnect_link_0_data_lines,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] west_input_interconnect_link_0_reqs,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] west_input_interconnect_link_0_acks,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] west_input_interconnect_link_1_tag_lines,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] west_input_interconnect_link_1_data_lines,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] west_input_interconnect_link_1_reqs,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] west_input_interconnect_link_1_acks,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] west_input_interconnect_link_2_tag_lines,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] west_input_interconnect_link_2_data_lines,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] west_input_interconnect_link_2_reqs,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] west_input_interconnect_link_2_acks,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] west_input_interconnect_link_3_tag_lines,
     input [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] west_input_interconnect_link_3_data_lines,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] west_input_interconnect_link_3_reqs,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] west_input_interconnect_link_3_acks,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] north_output_interconnect_link_0_tag_lines,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] north_output_interconnect_link_0_data_lines,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] north_output_interconnect_link_0_reqs,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] north_output_interconnect_link_0_acks,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] north_output_interconnect_link_1_tag_lines,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] north_output_interconnect_link_1_data_lines,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] north_output_interconnect_link_1_reqs,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] north_output_interconnect_link_1_acks,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] north_output_interconnect_link_2_tag_lines,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] north_output_interconnect_link_2_data_lines,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] north_output_interconnect_link_2_reqs,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] north_output_interconnect_link_2_acks,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] north_output_interconnect_link_3_tag_lines,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] north_output_interconnect_link_3_data_lines,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] north_output_interconnect_link_3_reqs,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] north_output_interconnect_link_3_acks,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] east_output_interconnect_link_0_tag_lines,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] east_output_interconnect_link_0_data_lines,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] east_output_interconnect_link_0_reqs,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] east_output_interconnect_link_0_acks,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] east_output_interconnect_link_1_tag_lines,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] east_output_interconnect_link_1_data_lines,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] east_output_interconnect_link_1_reqs,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] east_output_interconnect_link_1_acks,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] east_output_interconnect_link_2_tag_lines,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] east_output_interconnect_link_2_data_lines,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] east_output_interconnect_link_2_reqs,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] east_output_interconnect_link_2_acks,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] east_output_interconnect_link_3_tag_lines,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] east_output_interconnect_link_3_data_lines,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] east_output_interconnect_link_3_reqs,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] east_output_interconnect_link_3_acks,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] south_output_interconnect_link_0_tag_lines,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] south_output_interconnect_link_0_data_lines,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] south_output_interconnect_link_0_reqs,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] south_output_interconnect_link_0_acks,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] south_output_interconnect_link_1_tag_lines,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] south_output_interconnect_link_1_data_lines,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] south_output_interconnect_link_1_reqs,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] south_output_interconnect_link_1_acks,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] south_output_interconnect_link_2_tag_lines,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] south_output_interconnect_link_2_data_lines,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] south_output_interconnect_link_2_reqs,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] south_output_interconnect_link_2_acks,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] south_output_interconnect_link_3_tag_lines,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] south_output_interconnect_link_3_data_lines,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] south_output_interconnect_link_3_reqs,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] south_output_interconnect_link_3_acks,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] west_output_interconnect_link_0_tag_lines,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] west_output_interconnect_link_0_data_lines,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] west_output_interconnect_link_0_reqs,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] west_output_interconnect_link_0_acks,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] west_output_interconnect_link_1_tag_lines,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] west_output_interconnect_link_1_data_lines,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] west_output_interconnect_link_1_reqs,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] west_output_interconnect_link_1_acks,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] west_output_interconnect_link_2_tag_lines,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] west_output_interconnect_link_2_data_lines,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] west_output_interconnect_link_2_reqs,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] west_output_interconnect_link_2_acks,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] west_output_interconnect_link_3_tag_lines,
     output [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] west_output_interconnect_link_3_data_lines,
     output [TIA_NUM_PHYSICAL_PLANES - 1:0] west_output_interconnect_link_3_reqs,
     input [TIA_NUM_PHYSICAL_PLANES - 1:0] west_output_interconnect_link_3_acks);

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
    interconnect_link_if north_input_interconnect_links[3:0]();
    interconnect_link_if east_input_interconnect_links[3:0]();
    interconnect_link_if south_input_interconnect_links[3:0]();
    interconnect_link_if west_input_interconnect_links[3:0]();
    assign north_input_interconnect_links[0].reqs = north_input_interconnect_link_0_reqs;
    assign north_input_interconnect_link_0_acks = north_input_interconnect_links[0].acks;
    assign east_input_interconnect_links[0].reqs = east_input_interconnect_link_0_reqs;
    assign east_input_interconnect_link_0_acks = east_input_interconnect_links[0].acks;
    assign south_input_interconnect_links[0].reqs = south_input_interconnect_link_0_reqs;
    assign south_input_interconnect_link_0_acks = south_input_interconnect_links[0].acks;
    assign west_input_interconnect_links[0].reqs = west_input_interconnect_link_0_reqs;
    assign west_input_interconnect_link_0_acks = west_input_interconnect_links[0].acks;
    assign north_input_interconnect_links[1].reqs = north_input_interconnect_link_1_reqs;
    assign north_input_interconnect_link_1_acks = north_input_interconnect_links[1].acks;
    assign east_input_interconnect_links[1].reqs = east_input_interconnect_link_1_reqs;
    assign east_input_interconnect_link_1_acks = east_input_interconnect_links[1].acks;
    assign south_input_interconnect_links[1].reqs = south_input_interconnect_link_1_reqs;
    assign south_input_interconnect_link_1_acks = south_input_interconnect_links[1].acks;
    assign west_input_interconnect_links[1].reqs = west_input_interconnect_link_1_reqs;
    assign west_input_interconnect_link_1_acks = west_input_interconnect_links[1].acks;
    assign north_input_interconnect_links[2].reqs = north_input_interconnect_link_2_reqs;
    assign north_input_interconnect_link_2_acks = north_input_interconnect_links[2].acks;
    assign east_input_interconnect_links[2].reqs = east_input_interconnect_link_2_reqs;
    assign east_input_interconnect_link_2_acks = east_input_interconnect_links[2].acks;
    assign south_input_interconnect_links[2].reqs = south_input_interconnect_link_2_reqs;
    assign south_input_interconnect_link_2_acks = south_input_interconnect_links[2].acks;
    assign west_input_interconnect_links[2].reqs = west_input_interconnect_link_2_reqs;
    assign west_input_interconnect_link_2_acks = west_input_interconnect_links[2].acks;
    assign north_input_interconnect_links[3].reqs = north_input_interconnect_link_3_reqs;
    assign north_input_interconnect_link_3_acks = north_input_interconnect_links[3].acks;
    assign east_input_interconnect_links[3].reqs = east_input_interconnect_link_3_reqs;
    assign east_input_interconnect_link_3_acks = east_input_interconnect_links[3].acks;
    assign south_input_interconnect_links[3].reqs = south_input_interconnect_link_3_reqs;
    assign south_input_interconnect_link_3_acks = south_input_interconnect_links[3].acks;
    assign west_input_interconnect_links[3].reqs = west_input_interconnect_link_3_reqs;
    assign west_input_interconnect_link_3_acks = west_input_interconnect_links[3].acks;
    genvar i;
    generate
        for (i = 0; i < TIA_NUM_PHYSICAL_PLANES; i++) begin
            assign north_input_interconnect_links[0].tag_lines[i] = north_input_interconnect_link_0_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH];
            assign north_input_interconnect_links[0].data_lines[i] = north_input_interconnect_link_0_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH];
            assign east_input_interconnect_links[0].tag_lines[i] = east_input_interconnect_link_0_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH];
            assign east_input_interconnect_links[0].data_lines[i] = east_input_interconnect_link_0_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH];
            assign south_input_interconnect_links[0].tag_lines[i] = south_input_interconnect_link_0_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH];
            assign south_input_interconnect_links[0].data_lines[i] = south_input_interconnect_link_0_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH];
            assign west_input_interconnect_links[0].tag_lines[i] = west_input_interconnect_link_0_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH];
            assign west_input_interconnect_links[0].data_lines[i] = west_input_interconnect_link_0_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH];
            assign north_input_interconnect_links[1].tag_lines[i] = north_input_interconnect_link_1_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH];
            assign north_input_interconnect_links[1].data_lines[i] = north_input_interconnect_link_1_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH];
            assign east_input_interconnect_links[1].tag_lines[i] = east_input_interconnect_link_1_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH];
            assign east_input_interconnect_links[1].data_lines[i] = east_input_interconnect_link_1_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH];
            assign south_input_interconnect_links[1].tag_lines[i] = south_input_interconnect_link_1_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH];
            assign south_input_interconnect_links[1].data_lines[i] = south_input_interconnect_link_1_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH];
            assign west_input_interconnect_links[1].tag_lines[i] = west_input_interconnect_link_1_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH];
            assign west_input_interconnect_links[1].data_lines[i] = west_input_interconnect_link_1_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH];
            assign north_input_interconnect_links[2].tag_lines[i] = north_input_interconnect_link_2_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH];
            assign north_input_interconnect_links[2].data_lines[i] = north_input_interconnect_link_2_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH];
            assign east_input_interconnect_links[2].tag_lines[i] = east_input_interconnect_link_2_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH];
            assign east_input_interconnect_links[2].data_lines[i] = east_input_interconnect_link_2_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH];
            assign south_input_interconnect_links[2].tag_lines[i] = south_input_interconnect_link_2_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH];
            assign south_input_interconnect_links[2].data_lines[i] = south_input_interconnect_link_2_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH];
            assign west_input_interconnect_links[2].tag_lines[i] = west_input_interconnect_link_2_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH];
            assign west_input_interconnect_links[2].data_lines[i] = west_input_interconnect_link_2_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH];
            assign north_input_interconnect_links[3].tag_lines[i] = north_input_interconnect_link_3_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH];
            assign north_input_interconnect_links[3].data_lines[i] = north_input_interconnect_link_3_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH];
            assign east_input_interconnect_links[3].tag_lines[i] = east_input_interconnect_link_3_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH];
            assign east_input_interconnect_links[3].data_lines[i] = east_input_interconnect_link_3_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH];
            assign south_input_interconnect_links[3].tag_lines[i] = south_input_interconnect_link_3_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH];
            assign south_input_interconnect_links[3].data_lines[i] = south_input_interconnect_link_3_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH];
            assign west_input_interconnect_links[3].tag_lines[i] = west_input_interconnect_link_3_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH];
            assign west_input_interconnect_links[3].data_lines[i] = west_input_interconnect_link_3_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH];
        end
    endgenerate

    // Wrap the output links.
    interconnect_link_if north_output_interconnect_links[3:0]();
    interconnect_link_if east_output_interconnect_links[3:0]();
    interconnect_link_if south_output_interconnect_links[3:0]();
    interconnect_link_if west_output_interconnect_links[3:0]();
    assign north_output_interconnect_link_0_reqs = north_output_interconnect_links[0].reqs;
    assign north_output_interconnect_links[0].acks = north_output_interconnect_link_0_acks;
    assign east_output_interconnect_link_0_reqs = east_output_interconnect_links[0].reqs;
    assign east_output_interconnect_links[0].acks = east_output_interconnect_link_0_acks;
    assign south_output_interconnect_link_0_reqs = south_output_interconnect_links[0].reqs;
    assign south_output_interconnect_links[0].acks = south_output_interconnect_link_0_acks;
    assign west_output_interconnect_link_0_reqs = west_output_interconnect_links[0].reqs;
    assign west_output_interconnect_links[0].acks = west_output_interconnect_link_0_acks;
    assign north_output_interconnect_link_1_reqs = north_output_interconnect_links[1].reqs;
    assign north_output_interconnect_links[1].acks = north_output_interconnect_link_1_acks;
    assign east_output_interconnect_link_1_reqs = east_output_interconnect_links[1].reqs;
    assign east_output_interconnect_links[1].acks = east_output_interconnect_link_1_acks;
    assign south_output_interconnect_link_1_reqs = south_output_interconnect_links[1].reqs;
    assign south_output_interconnect_links[1].acks = south_output_interconnect_link_1_acks;
    assign west_output_interconnect_link_1_reqs = west_output_interconnect_links[1].reqs;
    assign west_output_interconnect_links[1].acks = west_output_interconnect_link_1_acks;
    assign north_output_interconnect_link_2_reqs = north_output_interconnect_links[2].reqs;
    assign north_output_interconnect_links[2].acks = north_output_interconnect_link_2_acks;
    assign east_output_interconnect_link_2_reqs = east_output_interconnect_links[2].reqs;
    assign east_output_interconnect_links[2].acks = east_output_interconnect_link_2_acks;
    assign south_output_interconnect_link_2_reqs = south_output_interconnect_links[2].reqs;
    assign south_output_interconnect_links[2].acks = south_output_interconnect_link_2_acks;
    assign west_output_interconnect_link_2_reqs = west_output_interconnect_links[2].reqs;
    assign west_output_interconnect_links[2].acks = west_output_interconnect_link_2_acks;
    assign north_output_interconnect_link_3_reqs = north_output_interconnect_links[3].reqs;
    assign north_output_interconnect_links[3].acks = north_output_interconnect_link_3_acks;
    assign east_output_interconnect_link_3_reqs = east_output_interconnect_links[3].reqs;
    assign east_output_interconnect_links[3].acks = east_output_interconnect_link_3_acks;
    assign south_output_interconnect_link_3_reqs = south_output_interconnect_links[3].reqs;
    assign south_output_interconnect_links[3].acks = south_output_interconnect_link_3_acks;
    assign west_output_interconnect_link_3_reqs = west_output_interconnect_links[3].reqs;
    assign west_output_interconnect_links[3].acks = west_output_interconnect_link_3_acks;
    genvar j;
    generate
        for (j = 0; j < TIA_NUM_PHYSICAL_PLANES; j++) begin
            assign north_output_interconnect_link_0_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH] = north_output_interconnect_links[0].tag_lines[j];
            assign north_output_interconnect_link_0_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH] = north_output_interconnect_links[0].data_lines[j];
            assign east_output_interconnect_link_0_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH] = east_output_interconnect_links[0].tag_lines[j];
            assign east_output_interconnect_link_0_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH] = east_output_interconnect_links[0].data_lines[j];
            assign south_output_interconnect_link_0_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH] = south_output_interconnect_links[0].tag_lines[j];
            assign south_output_interconnect_link_0_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH] = south_output_interconnect_links[0].data_lines[j];
            assign west_output_interconnect_link_0_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH] = west_output_interconnect_links[0].tag_lines[j];
            assign west_output_interconnect_link_0_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH] = west_output_interconnect_links[0].data_lines[j];
            assign north_output_interconnect_link_1_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH] = north_output_interconnect_links[1].tag_lines[j];
            assign north_output_interconnect_link_1_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH] = north_output_interconnect_links[1].data_lines[j];
            assign east_output_interconnect_link_1_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH] = east_output_interconnect_links[1].tag_lines[j];
            assign east_output_interconnect_link_1_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH] = east_output_interconnect_links[1].data_lines[j];
            assign south_output_interconnect_link_1_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH] = south_output_interconnect_links[1].tag_lines[j];
            assign south_output_interconnect_link_1_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH] = south_output_interconnect_links[1].data_lines[j];
            assign west_output_interconnect_link_1_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH] = west_output_interconnect_links[1].tag_lines[j];
            assign west_output_interconnect_link_1_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH] = west_output_interconnect_links[1].data_lines[j];
            assign north_output_interconnect_link_2_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH] = north_output_interconnect_links[2].tag_lines[j];
            assign north_output_interconnect_link_2_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH] = north_output_interconnect_links[2].data_lines[j];
            assign east_output_interconnect_link_2_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH] = east_output_interconnect_links[2].tag_lines[j];
            assign east_output_interconnect_link_2_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH] = east_output_interconnect_links[2].data_lines[j];
            assign south_output_interconnect_link_2_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH] = south_output_interconnect_links[2].tag_lines[j];
            assign south_output_interconnect_link_2_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH] = south_output_interconnect_links[2].data_lines[j];
            assign west_output_interconnect_link_2_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH] = west_output_interconnect_links[2].tag_lines[j];
            assign west_output_interconnect_link_2_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH] = west_output_interconnect_links[2].data_lines[j];
            assign north_output_interconnect_link_3_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH] = north_output_interconnect_links[3].tag_lines[j];
            assign north_output_interconnect_link_3_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH] = north_output_interconnect_links[3].data_lines[j];
            assign east_output_interconnect_link_3_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH] = east_output_interconnect_links[3].tag_lines[j];
            assign east_output_interconnect_link_3_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH] = east_output_interconnect_links[3].data_lines[j];
            assign south_output_interconnect_link_3_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH] = south_output_interconnect_links[3].tag_lines[j];
            assign south_output_interconnect_link_3_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH] = south_output_interconnect_links[3].data_lines[j];
            assign west_output_interconnect_link_3_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH] = west_output_interconnect_links[3].tag_lines[j];
            assign west_output_interconnect_link_3_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH] = west_output_interconnect_links[3].data_lines[j];
        end
    endgenerate

    // Target.
    block block(.clock(clock),
                .reset(reset),
                .enable(enable),
                .execute(execute),
                .halted(halted),
                .channels_quiescent(channels_quiescent),
                .routers_quiescent(routers_quiescent),
                .host_interface(host_interface),
                .north_input_interconnect_links(north_input_interconnect_links),
                .east_input_interconnect_links(east_input_interconnect_links),
                .south_input_interconnect_links(south_input_interconnect_links),
                .west_input_interconnect_links(west_input_interconnect_links),
                .north_output_interconnect_links(north_output_interconnect_links),
                .east_output_interconnect_links(east_output_interconnect_links),
                .south_output_interconnect_links(south_output_interconnect_links),
                .west_output_interconnect_links(west_output_interconnect_links));
endmodule
