/*
 * Combine n links into a single link using a priority ordering.
 */

`include "interconnect.svh"

module n_way_link_combiner
    #(parameter N = 4)
    (link_if.receiver input_links [N - 1:0],
     link_if.sender output_link);

    // Unpacked interfaces.
    logic input_link_req_signals [N - 1:0];
    logic input_link_ack_signals [N - 1:0];
    logic [TIA_TAG_WIDTH - 1:0] input_link_tag_lines [N - 1:0];
    logic [TIA_WORD_WIDTH - 1:0] input_link_data_lines [N - 1:0];
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
        for (i = 0; i < N; i++) begin
            assign input_link_req_signals[i] = input_links[i].req;
            assign input_links[i].ack = input_link_ack_signals[i];
            assign input_link_tag_lines[i] = input_links[i].packet.tag;
            assign input_link_data_lines[i] = input_links[i].packet.data;
        end
    endgenerate

    // Arbitrary priority select. It is up to software to guarantee that only one of these links is
    // used, so arbitrary priority order is fine. Having an explicit order also guarantees that all
    // control signals are tied high or low at all times.
    integer j, k, l, hit;
    always_comb begin
        hit = N;
        for (j = 0; j < N; j++) begin
            if (input_link_req_signals[j]) begin
                hit = j;
                break;
            end
        end
        if (hit == N) begin
            output_link_req = 0;
            output_link_tag = {TIA_TAG_WIDTH{1'b0}};
            output_link_data = {TIA_WORD_WIDTH{1'b0}};
            for (k = 0; k < N; k++)
                input_link_ack_signals[k] = 0;
        end else begin
            output_link_req = input_link_req_signals[hit];
            output_link_tag = input_link_tag_lines[hit];
            output_link_data = input_link_data_lines[hit];
            for (l = 0; l < N; l++) begin
                if (l == hit)
                    input_link_ack_signals[l] = output_link_ack;
                else
                    input_link_ack_signals[l] = 0;
            end
        end
    end
endmodule
