/*
 * Wrapper for Verilog-compatible netlist target for testbenches.
 */

`include "block.svh"

module block_top_wrapper
    (input logic clock, // Positive-edge triggered.
     input logic reset, // Active high.
     input logic enable, // Active high.
     input logic execute, // Active high.
     output logic halted, // High when execution finished.
     output logic channels_quiescent, // High when there are no packets left in the channel buffers.
     output logic routers_quiescent, // High when there are no packets left in the router buffers.
     mmio_if.device host_interface,
     interconnect_link_if.receiver north_input_interconnect_links [3:0],
     interconnect_link_if.receiver east_input_interconnect_links [3:0],
     interconnect_link_if.receiver south_input_interconnect_links [3:0],
     interconnect_link_if.receiver west_input_interconnect_links [3:0],
     interconnect_link_if.sender north_output_interconnect_links [3:0],
     interconnect_link_if.sender east_output_interconnect_links [3:0],
     interconnect_link_if.sender south_output_interconnect_links [3:0],
     interconnect_link_if.sender west_output_interconnect_links [3:0]);

    // Internal wiring.
    logic host_interface_read_req;
    logic host_interface_read_ack;
    logic [TIA_MMIO_INDEX_WIDTH - 1:0] host_interface_read_index;
    logic [TIA_MMIO_DATA_WIDTH - 1:0] host_interface_read_data;
    logic host_interface_write_req;
    logic host_interface_write_ack;
    logic [TIA_MMIO_INDEX_WIDTH - 1:0] host_interface_write_index;
    logic [TIA_MMIO_DATA_WIDTH - 1:0] host_interface_write_data;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] north_input_interconnect_link_0_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] north_input_interconnect_link_0_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] north_input_interconnect_link_0_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] north_input_interconnect_link_0_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] north_input_interconnect_link_1_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] north_input_interconnect_link_1_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] north_input_interconnect_link_1_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] north_input_interconnect_link_1_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] north_input_interconnect_link_2_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] north_input_interconnect_link_2_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] north_input_interconnect_link_2_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] north_input_interconnect_link_2_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] north_input_interconnect_link_3_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] north_input_interconnect_link_3_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] north_input_interconnect_link_3_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] north_input_interconnect_link_3_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] east_input_interconnect_link_0_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] east_input_interconnect_link_0_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] east_input_interconnect_link_0_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] east_input_interconnect_link_0_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] east_input_interconnect_link_1_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] east_input_interconnect_link_1_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] east_input_interconnect_link_1_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] east_input_interconnect_link_1_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:2] east_input_interconnect_link_2_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:2] east_input_interconnect_link_2_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:2] east_input_interconnect_link_2_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:2] east_input_interconnect_link_2_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:2] east_input_interconnect_link_3_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] east_input_interconnect_link_3_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] east_input_interconnect_link_3_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] east_input_interconnect_link_3_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] south_input_interconnect_link_0_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] south_input_interconnect_link_0_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] south_input_interconnect_link_0_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] south_input_interconnect_link_0_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] south_input_interconnect_link_1_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] south_input_interconnect_link_1_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] south_input_interconnect_link_1_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] south_input_interconnect_link_1_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] south_input_interconnect_link_2_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] south_input_interconnect_link_2_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] south_input_interconnect_link_2_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] south_input_interconnect_link_2_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] south_input_interconnect_link_3_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] south_input_interconnect_link_3_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] south_input_interconnect_link_3_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] south_input_interconnect_link_3_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] west_input_interconnect_link_0_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] west_input_interconnect_link_0_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] west_input_interconnect_link_0_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] west_input_interconnect_link_0_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] west_input_interconnect_link_1_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] west_input_interconnect_link_1_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] west_input_interconnect_link_1_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] west_input_interconnect_link_1_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] west_input_interconnect_link_2_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] west_input_interconnect_link_2_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] west_input_interconnect_link_2_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] west_input_interconnect_link_2_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] west_input_interconnect_link_3_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] west_input_interconnect_link_3_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] west_input_interconnect_link_3_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] west_input_interconnect_link_3_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] north_output_interconnect_link_0_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] north_output_interconnect_link_0_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] north_output_interconnect_link_0_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] north_output_interconnect_link_0_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] north_output_interconnect_link_1_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] north_output_interconnect_link_1_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] north_output_interconnect_link_1_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] north_output_interconnect_link_1_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] north_output_interconnect_link_2_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] north_output_interconnect_link_2_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] north_output_interconnect_link_2_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] north_output_interconnect_link_2_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] north_output_interconnect_link_3_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] north_output_interconnect_link_3_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] north_output_interconnect_link_3_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] north_output_interconnect_link_3_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] east_output_interconnect_link_0_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] east_output_interconnect_link_0_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] east_output_interconnect_link_0_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] east_output_interconnect_link_0_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] east_output_interconnect_link_1_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] east_output_interconnect_link_1_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] east_output_interconnect_link_1_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] east_output_interconnect_link_1_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] east_output_interconnect_link_2_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] east_output_interconnect_link_2_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] east_output_interconnect_link_2_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] east_output_interconnect_link_2_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] east_output_interconnect_link_3_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] east_output_interconnect_link_3_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] east_output_interconnect_link_3_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] east_output_interconnect_link_3_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] south_output_interconnect_link_0_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] south_output_interconnect_link_0_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] south_output_interconnect_link_0_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] south_output_interconnect_link_0_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] south_output_interconnect_link_1_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] south_output_interconnect_link_1_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] south_output_interconnect_link_1_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] south_output_interconnect_link_1_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] south_output_interconnect_link_2_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] south_output_interconnect_link_2_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] south_output_interconnect_link_2_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] south_output_interconnect_link_2_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] south_output_interconnect_link_3_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] south_output_interconnect_link_3_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] south_output_interconnect_link_3_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] south_output_interconnect_link_3_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] west_output_interconnect_link_0_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] west_output_interconnect_link_0_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] west_output_interconnect_link_0_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] west_output_interconnect_link_0_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] west_output_interconnect_link_1_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] west_output_interconnect_link_1_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] west_output_interconnect_link_1_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] west_output_interconnect_link_1_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] west_output_interconnect_link_2_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] west_output_interconnect_link_2_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] west_output_interconnect_link_2_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] west_output_interconnect_link_2_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] west_output_interconnect_link_3_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] west_output_interconnect_link_3_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] west_output_interconnect_link_3_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] west_output_interconnect_link_3_acks;

    // Host interface conversion.
    assign host_interface_read_req = host_interface.read_req;
    assign host_interface.read_ack = host_interface_read_ack;
    assign host_interface_read_index = host_interface.read_index;
    assign host_interface.read_data = host_interface_read_data;
    assign host_interface_write_req = host_interface.write_req;
    assign host_interface.write_ack = host_interface_write_ack;
    assign host_interface_write_index = host_interface.write_index;
    assign host_interface_write_data = host_interface.write_data;

    // Input link conversion.
    assign north_input_interconnect_link_0_reqs = north_input_interconnect_links[0].reqs;
    assign north_input_interconnect_links[0].acks = north_input_interconnect_link_0_acks;
    assign east_input_interconnect_link_0_reqs = east_input_interconnect_links[0].reqs;
    assign east_input_interconnect_links[0].acks = east_input_interconnect_link_0_acks;
    assign south_input_interconnect_link_0_reqs = south_input_interconnect_links[0].reqs;
    assign south_input_interconnect_links[0].acks = south_input_interconnect_link_0_acks;
    assign west_input_interconnect_link_0_reqs = west_input_interconnect_links[0].reqs;
    assign west_input_interconnect_links[0].acks = west_input_interconnect_link_0_acks;
    assign north_input_interconnect_link_1_reqs = north_input_interconnect_links[1].reqs;
    assign north_input_interconnect_links[1].acks = north_input_interconnect_link_1_acks;
    assign east_input_interconnect_link_1_reqs = east_input_interconnect_links[1].reqs;
    assign east_input_interconnect_links[1].acks = east_input_interconnect_link_1_acks;
    assign south_input_interconnect_link_1_reqs = south_input_interconnect_links[1].reqs;
    assign south_input_interconnect_links[1].acks = south_input_interconnect_link_1_acks;
    assign west_input_interconnect_link_1_reqs = west_input_interconnect_links[1].reqs;
    assign west_input_interconnect_links[1].acks = west_input_interconnect_link_1_acks;
    assign north_input_interconnect_link_2_reqs = north_input_interconnect_links[2].reqs;
    assign north_input_interconnect_links[2].acks = north_input_interconnect_link_2_acks;
    assign east_input_interconnect_link_2_reqs = east_input_interconnect_links[2].reqs;
    assign east_input_interconnect_links[2].acks = east_input_interconnect_link_2_acks;
    assign south_input_interconnect_link_2_reqs = south_input_interconnect_links[2].reqs;
    assign south_input_interconnect_links[2].acks = south_input_interconnect_link_2_acks;
    assign west_input_interconnect_link_2_reqs = west_input_interconnect_links[2].reqs;
    assign west_input_interconnect_links[2].acks = west_input_interconnect_link_2_acks;
    assign north_input_interconnect_link_3_reqs = north_input_interconnect_links[3].reqs;
    assign north_input_interconnect_links[3].acks = north_input_interconnect_link_3_acks;
    assign east_input_interconnect_link_3_reqs = east_input_interconnect_links[3].reqs;
    assign east_input_interconnect_links[3].acks = east_input_interconnect_link_3_acks;
    assign south_input_interconnect_link_3_reqs = south_input_interconnect_links[3].reqs;
    assign south_input_interconnect_links[3].acks = south_input_interconnect_link_3_acks;
    assign west_input_interconnect_link_3_reqs = west_input_interconnect_links[3].reqs;
    assign west_input_interconnect_links[3].acks = west_input_interconnect_link_3_acks;
    genvar i;
    generate
        for (i = 0; i < TIA_NUM_PHYSICAL_PLANES; i++) begin
            assign north_input_interconnect_link_0_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH] = north_input_interconnect_links[0].tag_lines[i];
            assign north_input_interconnect_link_0_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH] = north_input_interconnect_links[0].data_lines[i];
            assign east_input_interconnect_link_0_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH] = east_input_interconnect_links[0].tag_lines[i];
            assign east_input_interconnect_link_0_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH] = east_input_interconnect_links[0].data_lines[i];
            assign south_input_interconnect_link_0_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH] = south_input_interconnect_links[0].tag_lines[i];
            assign south_input_interconnect_link_0_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH] = south_input_interconnect_links[0].data_lines[i];
            assign west_input_interconnect_link_0_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH] = west_input_interconnect_links[0].tag_lines[i];
            assign west_input_interconnect_link_0_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH] = west_input_interconnect_links[0].data_lines[i];
            assign north_input_interconnect_link_1_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH] = north_input_interconnect_links[1].tag_lines[i];
            assign north_input_interconnect_link_1_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH] = north_input_interconnect_links[1].data_lines[i];
            assign east_input_interconnect_link_1_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH] = east_input_interconnect_links[1].tag_lines[i];
            assign east_input_interconnect_link_1_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH] = east_input_interconnect_links[1].data_lines[i];
            assign south_input_interconnect_link_1_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH] = south_input_interconnect_links[1].tag_lines[i];
            assign south_input_interconnect_link_1_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH] = south_input_interconnect_links[1].data_lines[i];
            assign west_input_interconnect_link_1_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH] = west_input_interconnect_links[1].tag_lines[i];
            assign west_input_interconnect_link_1_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH] = west_input_interconnect_links[1].data_lines[i];
            assign north_input_interconnect_link_2_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH] = north_input_interconnect_links[2].tag_lines[i];
            assign north_input_interconnect_link_2_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH] = north_input_interconnect_links[2].data_lines[i];
            assign east_input_interconnect_link_2_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH] = east_input_interconnect_links[2].tag_lines[i];
            assign east_input_interconnect_link_2_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH] = east_input_interconnect_links[2].data_lines[i];
            assign south_input_interconnect_link_2_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH] = south_input_interconnect_links[2].tag_lines[i];
            assign south_input_interconnect_link_2_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH] = south_input_interconnect_links[2].data_lines[i];
            assign west_input_interconnect_link_2_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH] = west_input_interconnect_links[2].tag_lines[i];
            assign west_input_interconnect_link_2_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH] = west_input_interconnect_links[2].data_lines[i];
            assign north_input_interconnect_link_3_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH] = north_input_interconnect_links[3].tag_lines[i];
            assign north_input_interconnect_link_3_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH] = north_input_interconnect_links[3].data_lines[i];
            assign east_input_interconnect_link_3_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH] = east_input_interconnect_links[3].tag_lines[i];
            assign east_input_interconnect_link_3_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH] = east_input_interconnect_links[3].data_lines[i];
            assign south_input_interconnect_link_3_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH] = south_input_interconnect_links[3].tag_lines[i];
            assign south_input_interconnect_link_3_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH] = south_input_interconnect_links[3].data_lines[i];
            assign west_input_interconnect_link_3_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH] = west_input_interconnect_links[3].tag_lines[i];
            assign west_input_interconnect_link_3_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH] = west_input_interconnect_links[3].data_lines[i];
        end
    endgenerate

    // Output link conversion.
    assign north_output_interconnect_links[0].reqs = north_output_interconnect_link_0_reqs;
    assign north_output_interconnect_link_0_acks = north_output_interconnect_links[0].acks;
    assign east_output_interconnect_links[0].reqs = east_output_interconnect_link_0_reqs;
    assign east_output_interconnect_link_0_acks = east_output_interconnect_links[0].acks;
    assign south_output_interconnect_links[0].reqs = south_output_interconnect_link_0_reqs;
    assign south_output_interconnect_link_0_acks = south_output_interconnect_links[0].acks;
    assign west_output_interconnect_links[0].reqs = west_output_interconnect_link_0_reqs;
    assign west_output_interconnect_link_0_acks = west_output_interconnect_links[0].acks;
    assign north_output_interconnect_links[1].reqs = north_output_interconnect_link_1_reqs;
    assign north_output_interconnect_link_1_acks = north_output_interconnect_links[1].acks;
    assign east_output_interconnect_links[1].reqs = east_output_interconnect_link_1_reqs;
    assign east_output_interconnect_link_1_acks = east_output_interconnect_links[1].acks;
    assign south_output_interconnect_links[1].reqs = south_output_interconnect_link_1_reqs;
    assign south_output_interconnect_link_1_acks = south_output_interconnect_links[1].acks;
    assign west_output_interconnect_links[1].reqs = west_output_interconnect_link_1_reqs;
    assign west_output_interconnect_link_1_acks = west_output_interconnect_links[1].acks;
    assign north_output_interconnect_links[2].reqs = north_output_interconnect_link_2_reqs;
    assign north_output_interconnect_link_2_acks = north_output_interconnect_links[2].acks;
    assign east_output_interconnect_links[2].reqs = east_output_interconnect_link_2_reqs;
    assign east_output_interconnect_link_2_acks = east_output_interconnect_links[2].acks;
    assign south_output_interconnect_links[2].reqs = south_output_interconnect_link_2_reqs;
    assign south_output_interconnect_link_2_acks = south_output_interconnect_links[2].acks;
    assign west_output_interconnect_links[2].reqs = west_output_interconnect_link_2_reqs;
    assign west_output_interconnect_link_2_acks = west_output_interconnect_links[2].acks;
    assign north_output_interconnect_links[3].reqs = north_output_interconnect_link_3_reqs;
    assign north_output_interconnect_link_3_acks = north_output_interconnect_links[3].acks;
    assign east_output_interconnect_links[3].reqs = east_output_interconnect_link_3_reqs;
    assign east_output_interconnect_link_3_acks = east_output_interconnect_links[3].acks;
    assign south_output_interconnect_links[3].reqs = south_output_interconnect_link_3_reqs;
    assign south_output_interconnect_link_3_acks = south_output_interconnect_links[3].acks;
    assign west_output_interconnect_links[3].reqs = west_output_interconnect_link_3_reqs;
    assign west_output_interconnect_link_3_acks = west_output_interconnect_links[3].acks;
    genvar j;
    generate
        for (j = 0; j < TIA_NUM_PHYSICAL_PLANES; j++) begin
            assign north_output_interconnect_links[0].tag_lines[j] = north_output_interconnect_link_0_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH];
            assign north_output_interconnect_links[0].data_lines[j] = north_output_interconnect_link_0_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH];
            assign east_output_interconnect_links[0].tag_lines[j] = east_output_interconnect_link_0_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH];
            assign east_output_interconnect_links[0].data_lines[j] = east_output_interconnect_link_0_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH];
            assign south_output_interconnect_links[0].tag_lines[j] = south_output_interconnect_link_0_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH];
            assign south_output_interconnect_links[0].data_lines[j] = south_output_interconnect_link_0_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH];
            assign west_output_interconnect_links[0].tag_lines[j] = west_output_interconnect_link_0_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH];
            assign west_output_interconnect_links[0].data_lines[j] = west_output_interconnect_link_0_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH];
            assign north_output_interconnect_links[1].tag_lines[j] = north_output_interconnect_link_1_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH];
            assign north_output_interconnect_links[1].data_lines[j] = north_output_interconnect_link_1_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH];
            assign east_output_interconnect_links[1].tag_lines[j] = east_output_interconnect_link_1_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH];
            assign east_output_interconnect_links[1].data_lines[j] = east_output_interconnect_link_1_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH];
            assign south_output_interconnect_links[1].tag_lines[j] = south_output_interconnect_link_1_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH];
            assign south_output_interconnect_links[1].data_lines[j] = south_output_interconnect_link_1_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH];
            assign west_output_interconnect_links[1].tag_lines[j] = west_output_interconnect_link_1_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH];
            assign west_output_interconnect_links[1].data_lines[j] = west_output_interconnect_link_1_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH];
            assign north_output_interconnect_links[2].tag_lines[j] = north_output_interconnect_link_2_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH];
            assign north_output_interconnect_links[2].data_lines[j] = north_output_interconnect_link_2_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH];
            assign east_output_interconnect_links[2].tag_lines[j] = east_output_interconnect_link_2_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH];
            assign east_output_interconnect_links[2].data_lines[j] = east_output_interconnect_link_2_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH];
            assign south_output_interconnect_links[2].tag_lines[j] = south_output_interconnect_link_2_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH];
            assign south_output_interconnect_links[2].data_lines[j] = south_output_interconnect_link_2_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH];
            assign west_output_interconnect_links[2].tag_lines[j] = west_output_interconnect_link_2_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH];
            assign west_output_interconnect_links[2].data_lines[j] = west_output_interconnect_link_2_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH];
            assign north_output_interconnect_links[3].tag_lines[j] = north_output_interconnect_link_3_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH];
            assign north_output_interconnect_links[3].data_lines[j] = north_output_interconnect_link_3_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH];
            assign east_output_interconnect_links[3].tag_lines[j] = east_output_interconnect_link_3_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH];
            assign east_output_interconnect_links[3].data_lines[j] = east_output_interconnect_link_3_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH];
            assign south_output_interconnect_links[3].tag_lines[j] = south_output_interconnect_link_3_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH];
            assign south_output_interconnect_links[3].data_lines[j] = south_output_interconnect_link_3_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH];
            assign west_output_interconnect_links[3].tag_lines[j] = west_output_interconnect_link_3_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH];
            assign west_output_interconnect_links[3].data_lines[j] = west_output_interconnect_link_3_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH];
        end
    endgenerate

    // Top module.
    block_top bt(.clock(clock),
                 .reset(reset),
                 .enable(enable),
                 .execute(execute),
                 .halted(halted),
                 .channels_quiescent(channels_quiescent),
                 .routers_quiescent(routers_quiescent),
                 .host_interface_read_req(host_interface_read_req),
                 .host_interface_read_ack(host_interface_read_ack),
                 .host_interface_read_index(host_interface_read_index),
                 .host_interface_read_data(host_interface_read_data),
                 .host_interface_write_req(host_interface_write_req),
                 .host_interface_write_ack(host_interface_write_ack),
                 .host_interface_write_index(host_interface_write_index),
                 .host_interface_write_data(host_interface_write_data),
                 .north_input_interconnect_link_0_tag_lines(north_input_interconnect_link_0_tag_lines),
                 .north_input_interconnect_link_0_data_lines(north_input_interconnect_link_0_data_lines),
                 .north_input_interconnect_link_0_reqs(north_input_interconnect_link_0_reqs),
                 .north_input_interconnect_link_0_acks(north_input_interconnect_link_0_acks),
                 .north_input_interconnect_link_1_tag_lines(north_input_interconnect_link_1_tag_lines),
                 .north_input_interconnect_link_1_data_lines(north_input_interconnect_link_1_data_lines),
                 .north_input_interconnect_link_1_reqs(north_input_interconnect_link_1_reqs),
                 .north_input_interconnect_link_1_acks(north_input_interconnect_link_1_acks),
                 .north_input_interconnect_link_2_tag_lines(north_input_interconnect_link_2_tag_lines),
                 .north_input_interconnect_link_2_data_lines(north_input_interconnect_link_2_data_lines),
                 .north_input_interconnect_link_2_reqs(north_input_interconnect_link_2_reqs),
                 .north_input_interconnect_link_2_acks(north_input_interconnect_link_2_acks),
                 .north_input_interconnect_link_3_tag_lines(north_input_interconnect_link_3_tag_lines),
                 .north_input_interconnect_link_3_data_lines(north_input_interconnect_link_3_data_lines),
                 .north_input_interconnect_link_3_reqs(north_input_interconnect_link_3_reqs),
                 .north_input_interconnect_link_3_acks(north_input_interconnect_link_3_acks),
                 .east_input_interconnect_link_0_tag_lines(east_input_interconnect_link_0_tag_lines),
                 .east_input_interconnect_link_0_data_lines(east_input_interconnect_link_0_data_lines),
                 .east_input_interconnect_link_0_reqs(east_input_interconnect_link_0_reqs),
                 .east_input_interconnect_link_0_acks(east_input_interconnect_link_0_acks),
                 .east_input_interconnect_link_1_tag_lines(east_input_interconnect_link_1_tag_lines),
                 .east_input_interconnect_link_1_data_lines(east_input_interconnect_link_1_data_lines),
                 .east_input_interconnect_link_1_reqs(east_input_interconnect_link_1_reqs),
                 .east_input_interconnect_link_1_acks(east_input_interconnect_link_1_acks),
                 .east_input_interconnect_link_2_tag_lines(east_input_interconnect_link_2_tag_lines),
                 .east_input_interconnect_link_2_data_lines(east_input_interconnect_link_2_data_lines),
                 .east_input_interconnect_link_2_reqs(east_input_interconnect_link_2_reqs),
                 .east_input_interconnect_link_2_acks(east_input_interconnect_link_2_acks),
                 .east_input_interconnect_link_3_tag_lines(east_input_interconnect_link_3_tag_lines),
                 .east_input_interconnect_link_3_data_lines(east_input_interconnect_link_3_data_lines),
                 .east_input_interconnect_link_3_reqs(east_input_interconnect_link_3_reqs),
                 .east_input_interconnect_link_3_acks(east_input_interconnect_link_3_acks),
                 .south_input_interconnect_link_0_tag_lines(south_input_interconnect_link_0_tag_lines),
                 .south_input_interconnect_link_0_data_lines(south_input_interconnect_link_0_data_lines),
                 .south_input_interconnect_link_0_reqs(south_input_interconnect_link_0_reqs),
                 .south_input_interconnect_link_0_acks(south_input_interconnect_link_0_acks),
                 .south_input_interconnect_link_1_tag_lines(south_input_interconnect_link_1_tag_lines),
                 .south_input_interconnect_link_1_data_lines(south_input_interconnect_link_1_data_lines),
                 .south_input_interconnect_link_1_reqs(south_input_interconnect_link_1_reqs),
                 .south_input_interconnect_link_1_acks(south_input_interconnect_link_1_acks),
                 .south_input_interconnect_link_2_tag_lines(south_input_interconnect_link_2_tag_lines),
                 .south_input_interconnect_link_2_data_lines(south_input_interconnect_link_2_data_lines),
                 .south_input_interconnect_link_2_reqs(south_input_interconnect_link_2_reqs),
                 .south_input_interconnect_link_2_acks(south_input_interconnect_link_2_acks),
                 .south_input_interconnect_link_3_tag_lines(south_input_interconnect_link_3_tag_lines),
                 .south_input_interconnect_link_3_data_lines(south_input_interconnect_link_3_data_lines),
                 .south_input_interconnect_link_3_reqs(south_input_interconnect_link_3_reqs),
                 .south_input_interconnect_link_3_acks(south_input_interconnect_link_3_acks),
                 .west_input_interconnect_link_0_tag_lines(west_input_interconnect_link_0_tag_lines),
                 .west_input_interconnect_link_0_data_lines(west_input_interconnect_link_0_data_lines),
                 .west_input_interconnect_link_0_reqs(west_input_interconnect_link_0_reqs),
                 .west_input_interconnect_link_0_acks(west_input_interconnect_link_0_acks),
                 .west_input_interconnect_link_1_tag_lines(west_input_interconnect_link_1_tag_lines),
                 .west_input_interconnect_link_1_data_lines(west_input_interconnect_link_1_data_lines),
                 .west_input_interconnect_link_1_reqs(west_input_interconnect_link_1_reqs),
                 .west_input_interconnect_link_1_acks(west_input_interconnect_link_1_acks),
                 .west_input_interconnect_link_2_tag_lines(west_input_interconnect_link_2_tag_lines),
                 .west_input_interconnect_link_2_data_lines(west_input_interconnect_link_2_data_lines),
                 .west_input_interconnect_link_2_reqs(west_input_interconnect_link_2_reqs),
                 .west_input_interconnect_link_2_acks(west_input_interconnect_link_2_acks),
                 .west_input_interconnect_link_3_tag_lines(west_input_interconnect_link_3_tag_lines),
                 .west_input_interconnect_link_3_data_lines(west_input_interconnect_link_3_data_lines),
                 .west_input_interconnect_link_3_reqs(west_input_interconnect_link_3_reqs),
                 .west_input_interconnect_link_3_acks(west_input_interconnect_link_3_acks),
                 .north_output_interconnect_link_0_tag_lines(north_output_interconnect_link_0_tag_lines),
                 .north_output_interconnect_link_0_data_lines(north_output_interconnect_link_0_data_lines),
                 .north_output_interconnect_link_0_reqs(north_output_interconnect_link_0_reqs),
                 .north_output_interconnect_link_0_acks(north_output_interconnect_link_0_acks),
                 .north_output_interconnect_link_1_tag_lines(north_output_interconnect_link_1_tag_lines),
                 .north_output_interconnect_link_1_data_lines(north_output_interconnect_link_1_data_lines),
                 .north_output_interconnect_link_1_reqs(north_output_interconnect_link_1_reqs),
                 .north_output_interconnect_link_1_acks(north_output_interconnect_link_1_acks),
                 .north_output_interconnect_link_2_tag_lines(north_output_interconnect_link_2_tag_lines),
                 .north_output_interconnect_link_2_data_lines(north_output_interconnect_link_2_data_lines),
                 .north_output_interconnect_link_2_reqs(north_output_interconnect_link_2_reqs),
                 .north_output_interconnect_link_2_acks(north_output_interconnect_link_2_acks),
                 .north_output_interconnect_link_3_tag_lines(north_output_interconnect_link_3_tag_lines),
                 .north_output_interconnect_link_3_data_lines(north_output_interconnect_link_3_data_lines),
                 .north_output_interconnect_link_3_reqs(north_output_interconnect_link_3_reqs),
                 .north_output_interconnect_link_3_acks(north_output_interconnect_link_3_acks),
                 .east_output_interconnect_link_0_tag_lines(east_output_interconnect_link_0_tag_lines),
                 .east_output_interconnect_link_0_data_lines(east_output_interconnect_link_0_data_lines),
                 .east_output_interconnect_link_0_reqs(east_output_interconnect_link_0_reqs),
                 .east_output_interconnect_link_0_acks(east_output_interconnect_link_0_acks),
                 .east_output_interconnect_link_1_tag_lines(east_output_interconnect_link_1_tag_lines),
                 .east_output_interconnect_link_1_data_lines(east_output_interconnect_link_1_data_lines),
                 .east_output_interconnect_link_1_reqs(east_output_interconnect_link_1_reqs),
                 .east_output_interconnect_link_1_acks(east_output_interconnect_link_1_acks),
                 .east_output_interconnect_link_2_tag_lines(east_output_interconnect_link_2_tag_lines),
                 .east_output_interconnect_link_2_data_lines(east_output_interconnect_link_2_data_lines),
                 .east_output_interconnect_link_2_reqs(east_output_interconnect_link_2_reqs),
                 .east_output_interconnect_link_2_acks(east_output_interconnect_link_2_acks),
                 .east_output_interconnect_link_3_tag_lines(east_output_interconnect_link_3_tag_lines),
                 .east_output_interconnect_link_3_data_lines(east_output_interconnect_link_3_data_lines),
                 .east_output_interconnect_link_3_reqs(east_output_interconnect_link_3_reqs),
                 .east_output_interconnect_link_3_acks(east_output_interconnect_link_3_acks),
                 .south_output_interconnect_link_0_tag_lines(south_output_interconnect_link_0_tag_lines),
                 .south_output_interconnect_link_0_data_lines(south_output_interconnect_link_0_data_lines),
                 .south_output_interconnect_link_0_reqs(south_output_interconnect_link_0_reqs),
                 .south_output_interconnect_link_0_acks(south_output_interconnect_link_0_acks),
                 .south_output_interconnect_link_1_tag_lines(south_output_interconnect_link_1_tag_lines),
                 .south_output_interconnect_link_1_data_lines(south_output_interconnect_link_1_data_lines),
                 .south_output_interconnect_link_1_reqs(south_output_interconnect_link_1_reqs),
                 .south_output_interconnect_link_1_acks(south_output_interconnect_link_1_acks),
                 .south_output_interconnect_link_2_tag_lines(south_output_interconnect_link_2_tag_lines),
                 .south_output_interconnect_link_2_data_lines(south_output_interconnect_link_2_data_lines),
                 .south_output_interconnect_link_2_reqs(south_output_interconnect_link_2_reqs),
                 .south_output_interconnect_link_2_acks(south_output_interconnect_link_2_acks),
                 .south_output_interconnect_link_3_tag_lines(south_output_interconnect_link_3_tag_lines),
                 .south_output_interconnect_link_3_data_lines(south_output_interconnect_link_3_data_lines),
                 .south_output_interconnect_link_3_reqs(south_output_interconnect_link_3_reqs),
                 .south_output_interconnect_link_3_acks(south_output_interconnect_link_3_acks),
                 .west_output_interconnect_link_0_tag_lines(west_output_interconnect_link_0_tag_lines),
                 .west_output_interconnect_link_0_data_lines(west_output_interconnect_link_0_data_lines),
                 .west_output_interconnect_link_0_reqs(west_output_interconnect_link_0_reqs),
                 .west_output_interconnect_link_0_acks(west_output_interconnect_link_0_acks),
                 .west_output_interconnect_link_1_tag_lines(west_output_interconnect_link_1_tag_lines),
                 .west_output_interconnect_link_1_data_lines(west_output_interconnect_link_1_data_lines),
                 .west_output_interconnect_link_1_reqs(west_output_interconnect_link_1_reqs),
                 .west_output_interconnect_link_1_acks(west_output_interconnect_link_1_acks),
                 .west_output_interconnect_link_2_tag_lines(west_output_interconnect_link_2_tag_lines),
                 .west_output_interconnect_link_2_data_lines(west_output_interconnect_link_2_data_lines),
                 .west_output_interconnect_link_2_reqs(west_output_interconnect_link_2_reqs),
                 .west_output_interconnect_link_2_acks(west_output_interconnect_link_2_acks),
                 .west_output_interconnect_link_3_tag_lines(west_output_interconnect_link_3_tag_lines),
                 .west_output_interconnect_link_3_data_lines(west_output_interconnect_link_3_data_lines),
                 .west_output_interconnect_link_3_reqs(west_output_interconnect_link_3_reqs),
                 .west_output_interconnect_link_3_acks(west_output_interconnect_link_3_acks));
endmodule
