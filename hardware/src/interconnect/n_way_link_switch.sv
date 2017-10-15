/*
 * Switch a single link between n output links.
 */

`include "interconnect.svh"

module n_way_link_switch
    #(parameter N = 4)
    (input logic enable,
     input logic [$clog2(N):0] setting,
     link_if.receiver input_link,
     link_if.sender output_links [N - 1:0]);

    // Unpacked interfaces.
    logic input_link_req;
    logic input_link_ack;
    logic [TIA_TAG_WIDTH - 1:0] input_link_tag;
    logic [TIA_WORD_WIDTH - 1:0] input_link_data;
    logic output_link_req_signals [N - 1:0];
    logic output_link_ack_signals [N - 1:0];
    logic [TIA_TAG_WIDTH - 1:0] output_link_tag_lines [N - 1:0];
    logic [TIA_WORD_WIDTH - 1:0] output_link_data_lines [N - 1:0];

    // Unpack the link interfaces.
    assign input_link_req = input_link.req;
    assign input_link.ack = input_link_ack;
    assign input_link_tag = input_link.packet.tag;
    assign input_link_data = input_link.packet.data;
    genvar i;
    generate
        for (i = 0; i < N; i++) begin
            assign output_links[i].req = output_link_req_signals[i];
            assign output_link_ack_signals[i] = output_links[i].ack;
            assign output_links[i].packet.tag = output_link_tag_lines[i];
            assign output_links[i].packet.data = output_link_data_lines[i];
        end
    endgenerate

    // Default to disconnected.
    integer j, k;
    always_comb begin
        if (enable) begin
            input_link_ack = output_link_ack_signals[setting];
            for (j = 0; j < N; j++) begin
                if (setting == j) begin
                    output_link_req_signals[j] = input_link_req;
                    output_link_tag_lines[j] = input_link_tag;
                    output_link_data_lines[j] = input_link_data;
                end else begin
                    output_link_req_signals[j] = 0;
                    output_link_tag_lines[j] = {TIA_TAG_WIDTH{1'b0}};
                    output_link_data_lines[j] = {TIA_WORD_WIDTH{1'b0}};
                end
            end
        end else begin
            input_link_ack = 0;
            for (k = 0; k < N; k++) begin
                output_link_req_signals[k] = 0;
                output_link_tag_lines[k] = {TIA_TAG_WIDTH{1'b0}};
                output_link_data_lines[k] = {TIA_WORD_WIDTH{1'b0}};
            end
        end
    end
endmodule
