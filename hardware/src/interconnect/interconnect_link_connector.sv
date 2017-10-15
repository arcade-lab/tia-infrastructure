/*
* Connect and interconnect link sender to a receiver.
 */

`include "interconnect.svh"

module interconnect_link_connector
    (interconnect_link_if.receiver input_interconnect_link,
     interconnect_link_if.sender output_interconnect_link);

    // Unpacked interfaces.
    logic input_interconnect_link_req_signals [TIA_NUM_PHYSICAL_PLANES - 1:0];
    logic input_interconnect_link_ack_signals [TIA_NUM_PHYSICAL_PLANES - 1:0];
    logic [TIA_TAG_WIDTH - 1:0] input_interconnect_link_tag_lines [TIA_NUM_PHYSICAL_PLANES - 1:0];
    logic [TIA_WORD_WIDTH - 1:0] input_interconnect_link_data_lines [TIA_NUM_PHYSICAL_PLANES - 1:0];
    logic output_interconnect_link_req_signals [TIA_NUM_PHYSICAL_PLANES - 1:0];
    logic output_interconnect_link_ack_signals [TIA_NUM_PHYSICAL_PLANES - 1:0];
    logic [TIA_TAG_WIDTH - 1:0] output_interconnect_link_tag_lines [TIA_NUM_PHYSICAL_PLANES - 1:0];
    logic [TIA_WORD_WIDTH - 1:0] output_interconnect_link_data_lines [TIA_NUM_PHYSICAL_PLANES - 1:0];

    // Unpack the interfaces.
    genvar i;
    generate
        for (i = 0; i < TIA_NUM_PHYSICAL_PLANES; i++) begin
            assign input_interconnect_link_req_signals[i] = input_interconnect_link.reqs[i];
            assign input_interconnect_link.acks[i] = input_interconnect_link_ack_signals[i];
            assign input_interconnect_link_tag_lines[i] = input_interconnect_link.tag_lines[i];
            assign input_interconnect_link_data_lines[i] = input_interconnect_link.data_lines[i];
        end
    endgenerate
    genvar j;
    generate
        for (j = 0; j < TIA_NUM_PHYSICAL_PLANES; j++) begin
            assign output_interconnect_link.reqs[j] = output_interconnect_link_req_signals[j];
            assign output_interconnect_link_ack_signals[j] = output_interconnect_link.acks[j];
            assign output_interconnect_link.tag_lines[j] = output_interconnect_link_tag_lines[j];
            assign output_interconnect_link.data_lines[j] = output_interconnect_link_data_lines[j];
        end
    endgenerate

    // Connect the interfaces.
    genvar k;
    generate
        for (k = 0; k < TIA_NUM_PHYSICAL_PLANES; k++) begin
            assign output_interconnect_link_req_signals[k] = input_interconnect_link_req_signals[k];
            assign input_interconnect_link_ack_signals[k] = output_interconnect_link_ack_signals[k];
            assign output_interconnect_link_tag_lines[k] = input_interconnect_link_tag_lines[k];
            assign output_interconnect_link_data_lines[k] = input_interconnect_link_data_lines[k];
        end
    endgenerate
endmodule

