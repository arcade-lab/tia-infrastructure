/*
 * One input link to four output link switch.
 */

`include "interconnect.svh"

module four_way_link_switch
    (input logic enable,
     input logic [1:0] setting,
     link_if.receiver input_link,
     link_if.sender output_link_0,
     link_if.sender output_link_1,
     link_if.sender output_link_2,
     link_if.sender output_link_3);

    // Connect the relevant output channel if enabled.
    always_comb begin
        if (enable) begin
            case (setting)
                0: begin
                    input_link.ack = output_link_0.ack;
                    output_link_0.req = input_link.req;
                    output_link_0.packet = input_link.packet;
                    output_link_1.req = 0;
                    output_link_1.packet = `NULL_PACKET;
                    output_link_2.req = 0;
                    output_link_2.packet = `NULL_PACKET;
                    output_link_3.req = 0;
                    output_link_3.packet = `NULL_PACKET;
                end
                1: begin
                    input_link.ack = output_link_1.ack;
                    output_link_0.req = 0;
                    output_link_0.packet = `NULL_PACKET;
                    output_link_1.req = input_link.req;
                    output_link_1.packet = input_link.packet;
                    output_link_2.req = 0;
                    output_link_2.packet = `NULL_PACKET;
                    output_link_3.req = 0;
                    output_link_3.packet = `NULL_PACKET;
                end
                2: begin
                    input_link.ack = output_link_2.ack;
                    output_link_0.req = 0;
                    output_link_0.packet = `NULL_PACKET;
                    output_link_1.req = 0;
                    output_link_1.packet = `NULL_PACKET;
                    output_link_2.req = input_link.req;
                    output_link_2.packet = input_link.packet;
                    output_link_3.req = 0;
                    output_link_3.packet = `NULL_PACKET;
                end
                3: begin
                    input_link.ack = output_link_3.ack;
                    output_link_0.req = 0;
                    output_link_0.packet = `NULL_PACKET;
                    output_link_1.req = 0;
                    output_link_1.packet = `NULL_PACKET;
                    output_link_2.req = 0;
                    output_link_2.packet = `NULL_PACKET;
                    output_link_3.req = input_link.req;
                    output_link_3.packet = input_link.packet;
                end
                default: begin
                    input_link.ack = 0;
                    output_link_0.req = 0;
                    output_link_0.packet = `NULL_PACKET;
                    output_link_1.req = 0;
                    output_link_1.packet = `NULL_PACKET;
                    output_link_2.req = 0;
                    output_link_2.packet = `NULL_PACKET;
                    output_link_3.req = 0;
                    output_link_3.packet = `NULL_PACKET;
                end
            endcase
        end else begin
            input_link.ack = 0;
            output_link_0.req = 0;
            output_link_0.packet = `NULL_PACKET;
            output_link_1.req = 0;
            output_link_1.packet = `NULL_PACKET;
            output_link_2.req = 0;
            output_link_2.packet = `NULL_PACKET;
            output_link_3.req = 0;
            output_link_3.packet = `NULL_PACKET;
        end
    end
endmodule
