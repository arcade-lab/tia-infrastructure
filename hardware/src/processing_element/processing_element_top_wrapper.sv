/*
 * Wrapper for Verilog-compatible netlist target for testbenches.
 */

`include "processing_element.svh"

module processing_element_top_wrapper
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

    // Internal wiring.
    logic host_interface_read_req;
    logic host_interface_read_ack;
    logic [TIA_MMIO_INDEX_WIDTH - 1:0] host_interface_read_index;
    logic [TIA_MMIO_DATA_WIDTH - 1:0] host_interface_read_data;
    logic host_interface_write_req;
    logic host_interface_write_ack;
    logic [TIA_MMIO_INDEX_WIDTH - 1:0] host_interface_write_index;
    logic [TIA_MMIO_DATA_WIDTH - 1:0] host_interface_write_data;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] north_input_interconnect_link_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] north_input_interconnect_link_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] north_input_interconnect_link_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] north_input_interconnect_link_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] east_input_interconnect_link_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] east_input_interconnect_link_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] east_input_interconnect_link_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] east_input_interconnect_link_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] south_input_interconnect_link_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] south_input_interconnect_link_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] south_input_interconnect_link_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] south_input_interconnect_link_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] west_input_interconnect_link_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] west_input_interconnect_link_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] west_input_interconnect_link_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] west_input_interconnect_link_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] north_output_interconnect_link_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] north_output_interconnect_link_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] north_output_interconnect_link_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] north_output_interconnect_link_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] east_output_interconnect_link_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] east_output_interconnect_link_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] east_output_interconnect_link_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] east_output_interconnect_link_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] south_output_interconnect_link_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] south_output_interconnect_link_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] south_output_interconnect_link_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] south_output_interconnect_link_acks;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_TAG_WIDTH - 1:0] west_output_interconnect_link_tag_lines;
    logic [TIA_NUM_PHYSICAL_PLANES * TIA_WORD_WIDTH - 1:0] west_output_interconnect_link_data_lines;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] west_output_interconnect_link_reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] west_output_interconnect_link_acks;

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
    assign north_input_interconnect_link_reqs = north_input_interconnect_link.reqs;
    assign north_input_interconnect_link.acks = north_input_interconnect_link_acks;
    assign east_input_interconnect_link_reqs = east_input_interconnect_link.reqs;
    assign east_input_interconnect_link.acks = east_input_interconnect_link_acks;
    assign south_input_interconnect_link_reqs = south_input_interconnect_link.reqs;
    assign south_input_interconnect_link.acks = south_input_interconnect_link_acks;
    assign west_input_interconnect_link_reqs = west_input_interconnect_link.reqs;
    assign west_input_interconnect_link.acks = west_input_interconnect_link_acks;
    genvar i;
    generate
        for (i = 0; i < TIA_NUM_PHYSICAL_PLANES; i++) begin
            assign north_input_interconnect_link_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH] = north_input_interconnect_link.tag_lines[i];
            assign north_input_interconnect_link_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH] = north_input_interconnect_link.data_lines[i];
            assign east_input_interconnect_link_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH] = east_input_interconnect_link.tag_lines[i];
            assign east_input_interconnect_link_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH] = east_input_interconnect_link.data_lines[i];
            assign south_input_interconnect_link_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH] = south_input_interconnect_link.tag_lines[i];
            assign south_input_interconnect_link_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH] = south_input_interconnect_link.data_lines[i];
            assign west_input_interconnect_link_tag_lines[TIA_TAG_WIDTH * i+:TIA_TAG_WIDTH] = west_input_interconnect_link.tag_lines[i];
            assign west_input_interconnect_link_data_lines[TIA_WORD_WIDTH * i+:TIA_WORD_WIDTH] = west_input_interconnect_link.data_lines[i];
        end
    endgenerate

    // Output link conversion.
    assign north_output_interconnect_link.reqs = north_output_interconnect_link_reqs;
    assign north_output_interconnect_link_acks = north_output_interconnect_link.acks;
    assign east_output_interconnect_link.reqs = east_output_interconnect_link_reqs;
    assign east_output_interconnect_link_acks = east_output_interconnect_link.acks;
    assign south_output_interconnect_link.reqs = south_output_interconnect_link_reqs;
    assign south_output_interconnect_link_acks = south_output_interconnect_link.acks;
    assign west_output_interconnect_link.reqs = west_output_interconnect_link_reqs;
    assign west_output_interconnect_link_acks = west_output_interconnect_link.acks;
    genvar j;
    generate
        for (j = 0; j < TIA_NUM_PHYSICAL_PLANES; j++) begin
            assign north_output_interconnect_link.tag_lines[j] = north_output_interconnect_link_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH];
            assign north_output_interconnect_link.data_lines[j] = north_output_interconnect_link_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH];
            assign east_output_interconnect_link.tag_lines[j] = east_output_interconnect_link_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH];
            assign east_output_interconnect_link.data_lines[j] = east_output_interconnect_link_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH];
            assign south_output_interconnect_link.tag_lines[j] = south_output_interconnect_link_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH];
            assign south_output_interconnect_link.data_lines[j] = south_output_interconnect_link_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH];
            assign west_output_interconnect_link.tag_lines[j] = west_output_interconnect_link_tag_lines[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH];
            assign west_output_interconnect_link.data_lines[j] = west_output_interconnect_link_data_lines[TIA_WORD_WIDTH * j+:TIA_WORD_WIDTH];
        end
    endgenerate

    // Top module.
    processing_element_top pet(.clock(clock),
                               .reset(reset),
                               .enable(enable),
                               .execute(execute),
                               .halted(halted),
                               .channels_quiescent(channels_quiescent),
                               .router_quiescent(router_quiescent),
                               .host_interface_read_req(host_interface_read_req),
                               .host_interface_read_ack(host_interface_read_ack),
                               .host_interface_read_index(host_interface_read_index),
                               .host_interface_read_data(host_interface_read_data),
                               .host_interface_write_req(host_interface_write_req),
                               .host_interface_write_ack(host_interface_write_ack),
                               .host_interface_write_index(host_interface_write_index),
                               .host_interface_write_data(host_interface_write_data),
                               .north_input_interconnect_link_tag_lines(north_input_interconnect_link_tag_lines),
                               .north_input_interconnect_link_data_lines(north_input_interconnect_link_data_lines),
                               .north_input_interconnect_link_reqs(north_input_interconnect_link_reqs),
                               .north_input_interconnect_link_acks(north_input_interconnect_link_acks),
                               .east_input_interconnect_link_tag_lines(east_input_interconnect_link_tag_lines),
                               .east_input_interconnect_link_data_lines(east_input_interconnect_link_data_lines),
                               .east_input_interconnect_link_reqs(east_input_interconnect_link_reqs),
                               .east_input_interconnect_link_acks(east_input_interconnect_link_acks),
                               .south_input_interconnect_link_tag_lines(south_input_interconnect_link_tag_lines),
                               .south_input_interconnect_link_data_lines(south_input_interconnect_link_data_lines),
                               .south_input_interconnect_link_reqs(south_input_interconnect_link_reqs),
                               .south_input_interconnect_link_acks(south_input_interconnect_link_acks),
                               .west_input_interconnect_link_tag_lines(west_input_interconnect_link_tag_lines),
                               .west_input_interconnect_link_data_lines(west_input_interconnect_link_data_lines),
                               .west_input_interconnect_link_reqs(west_input_interconnect_link_reqs),
                               .west_input_interconnect_link_acks(west_input_interconnect_link_acks),
                               .north_output_interconnect_link_tag_lines(north_output_interconnect_link_tag_lines),
                               .north_output_interconnect_link_data_lines(north_output_interconnect_link_data_lines),
                               .north_output_interconnect_link_reqs(north_output_interconnect_link_reqs),
                               .north_output_interconnect_link_acks(north_output_interconnect_link_acks),
                               .east_output_interconnect_link_tag_lines(east_output_interconnect_link_tag_lines),
                               .east_output_interconnect_link_data_lines(east_output_interconnect_link_data_lines),
                               .east_output_interconnect_link_reqs(east_output_interconnect_link_reqs),
                               .east_output_interconnect_link_acks(east_output_interconnect_link_acks),
                               .south_output_interconnect_link_tag_lines(south_output_interconnect_link_tag_lines),
                               .south_output_interconnect_link_data_lines(south_output_interconnect_link_data_lines),
                               .south_output_interconnect_link_reqs(south_output_interconnect_link_reqs),
                               .south_output_interconnect_link_acks(south_output_interconnect_link_acks),
                               .west_output_interconnect_link_tag_lines(west_output_interconnect_link_tag_lines),
                               .west_output_interconnect_link_data_lines(west_output_interconnect_link_data_lines),
                               .west_output_interconnect_link_reqs(west_output_interconnect_link_reqs),
                               .west_output_interconnect_link_acks(west_output_interconnect_link_acks));
endmodule
