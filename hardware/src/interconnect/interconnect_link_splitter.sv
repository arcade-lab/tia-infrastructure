/*
 * Duplicate a single local link over an interconnect link bundle. To be used to connect
 * peripherals to the mesh.
 */

`include "interconnect.svh"

module interconnect_link_splitter
    (link_if.receiver input_link,
     interconnect_link_if.sender output_interconnect_link);

    // Internal wiring.
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] acks;
    logic [TIA_TAG_WIDTH - 1:0] tag_lines [TIA_NUM_PHYSICAL_PLANES - 1:0];
    logic [TIA_WORD_WIDTH - 1:0] data_lines [TIA_NUM_PHYSICAL_PLANES - 1:0];

    // Connect the input link.
    assign reqs = {TIA_NUM_PHYSICAL_PLANES{input_link.req}};
    assign input_link.ack = |output_interconnect_link.acks;
    genvar i;
    generate
        for (i = 0; i < TIA_NUM_PHYSICAL_PLANES; i++) begin
            assign tag_lines[i] = input_link.packet.tag;
            assign data_lines[i] = input_link.packet.data;
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

