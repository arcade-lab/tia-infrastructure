/*
 * Convert a interconnect link bundle into n local links.
 */

`include "interconnect.svh"

module interconnect_link_receiver_adapter
    (interconnect_link_if.receiver input_interconnect_link,
     link_if.sender output_links [TIA_NUM_PHYSICAL_PLANES - 1:0]);

    // Unpack the interconnect link.
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] acks;
    logic [TIA_TAG_WIDTH - 1:0] tag_lines [TIA_NUM_PHYSICAL_PLANES - 1:0];
    logic [TIA_WORD_WIDTH - 1:0] data_lines [TIA_NUM_PHYSICAL_PLANES - 1:0];
    genvar i;
    generate
        for (i = 0; i < TIA_NUM_PHYSICAL_PLANES; i++) begin
            assign reqs[i] = input_interconnect_link.reqs[i];
            assign input_interconnect_link.acks[i] = acks[i];
            assign tag_lines[i] = input_interconnect_link.tag_lines[i];
            assign data_lines[i] = input_interconnect_link.data_lines[i];
        end
    endgenerate

    // Hook up signals for the output links.
    genvar j;
    generate
        for (j = 0; j < TIA_NUM_PHYSICAL_PLANES; j++) begin
            assign output_links[j].req = reqs[j];
            assign acks[j] = output_links[j].ack;
            assign output_links[j].packet.tag = tag_lines[j];
            assign output_links[j].packet.data = data_lines[j];
        end
    endgenerate
endmodule

