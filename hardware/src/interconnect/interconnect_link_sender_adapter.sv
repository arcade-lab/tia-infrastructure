/*
 * Convert n local links into an interconnect link bundle.
 */

`include "interconnect.svh"

module interconnect_link_sender_adapter
    (link_if.receiver input_links [TIA_NUM_PHYSICAL_PLANES - 1:0],
     interconnect_link_if.sender output_interconnect_link);

    // Unpack the input links.
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] acks;
    logic [TIA_TAG_WIDTH - 1:0] tag_lines [TIA_NUM_PHYSICAL_PLANES - 1:0];
    logic [TIA_WORD_WIDTH - 1:0] data_lines [TIA_NUM_PHYSICAL_PLANES - 1:0];
    genvar i;
    generate
        for (i = 0; i < TIA_NUM_PHYSICAL_PLANES; i++) begin
            assign reqs[i] = input_links[i].req;
            assign input_links[i].ack = acks[i];
            assign tag_lines[i] = input_links[i].packet.tag;
            assign data_lines[i] = input_links[i].packet.data;
        end
    endgenerate

    // Hookup the output interconnect link.
    genvar j;
    generate
        for (j = 0; j < TIA_NUM_PHYSICAL_PLANES; j++) begin
            assign output_interconnect_link.reqs[j] = reqs[j];
            assign acks[j] = output_interconnect_link.acks[j];
            assign output_interconnect_link.tag_lines[j] = tag_lines[j];
            assign output_interconnect_link.data_lines[j] = data_lines[j];
        end
    endgenerate
endmodule

