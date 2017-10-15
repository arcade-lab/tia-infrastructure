/*
 * Duplicate a single local link over an interconnect link bundle. To be used to connect
 * peripherals to the mesh.
 */

`include "interconnect.svh"

module interconnect_link_combiner
    (interconnect_link_if.receiver input_interconnect_link,
     link_if.sender output_link);

    // Unpacked interfaces.
    logic input_interconnect_link_req_signals [TIA_NUM_PHYSICAL_PLANES - 1:0];
    logic input_interconnect_link_ack_signals [TIA_NUM_PHYSICAL_PLANES - 1:0];
    logic [TIA_TAG_WIDTH - 1:0] input_interconnect_link_tag_lines [TIA_NUM_PHYSICAL_PLANES - 1:0];
    logic [TIA_WORD_WIDTH - 1:0] input_interconnect_link_data_lines [TIA_NUM_PHYSICAL_PLANES - 1:0];
    logic output_link_req;
    logic output_link_ack;
    logic [TIA_TAG_WIDTH - 1:0] output_link_tag;
    logic [TIA_WORD_WIDTH - 1:0] output_link_data;

    // Unpack the link interfaces.
    assign output_link.req = output_link_req;
    assign output_link_ack = output_link.ack;
    assign output_link.packet.tag = output_link_tag;
    assign output_link.packet.data = output_link_data;
    genvar i;
    generate
        for (i = 0; i < TIA_NUM_PHYSICAL_PLANES; i++) begin
            assign input_interconnect_link_req_signals[i] = input_interconnect_link.reqs[i];
            assign input_interconnect_link.acks[i] = input_interconnect_link_ack_signals[i];
            assign input_interconnect_link_tag_lines[i] = input_interconnect_link.tag_lines[i];
            assign input_interconnect_link_data_lines[i] = input_interconnect_link.data_lines[i];
        end
    endgenerate

    // Arbitrary priority select. It is up to software to guarantee that only one of these links is
    // used, so arbitrary priority order is fine. Having an explicit order also guarantees that all
    // control signals are tied high or low at all times.
    integer j, k, l, hit;
    always_comb begin
        hit = TIA_NUM_PHYSICAL_PLANES;
        for (j = 0; j < TIA_NUM_PHYSICAL_PLANES; j++) begin
            if (input_interconnect_link_req_signals[j]) begin
                hit = j;
                break;
            end
        end
        if (hit == TIA_NUM_PHYSICAL_PLANES) begin
            output_link_req = 0;
            output_link_tag = {TIA_TAG_WIDTH{1'b0}};
            output_link_data = {TIA_WORD_WIDTH{1'b0}};
            for (k = 0; k < TIA_NUM_PHYSICAL_PLANES; k++)
                input_interconnect_link_ack_signals[k] = 0;
        end else begin
            output_link_req = input_interconnect_link_req_signals[hit];
            output_link_tag = input_interconnect_link_tag_lines[hit];
            output_link_data = input_interconnect_link_data_lines[hit];
            for (l = 0; l < TIA_NUM_PHYSICAL_PLANES; l++) begin
                if (l == hit)
                    input_interconnect_link_ack_signals[l] = output_link_ack;
                else
                    input_interconnect_link_ack_signals[l] = 0;
            end
        end
    end
endmodule

