/*
 * One input link to four output link switch.
 */

`include "interconnect.svh"

module four_way_link_combiner
    (link_if.receiver input_link_0,
     link_if.receiver input_link_1,
     link_if.receiver input_link_2,
     link_if.receiver input_link_3,
     link_if.sender output_link);

    // Only forward a req packet. It is up to software to guarantee that only one of these links is
    // used, so arbitrary priority order is fine. Having an explicit order also guarantees that all
    // control signals are tied high or low at all times.
    always_comb begin
        if (input_link_0.req) begin
            output_link.req = input_link_0.req;
            output_link.packet = input_link_0.packet;
            input_link_0.ack = output_link.ack;
            input_link_1.ack = 0;
            input_link_2.ack = 0;
            input_link_3.ack = 0;
        end else if (input_link_1.req) begin
            output_link.req = input_link_1.req;
            output_link.packet = input_link_1.packet;
            input_link_0.ack = 0;
            input_link_1.ack = output_link.ack;
            input_link_2.ack = 0;
            input_link_3.ack = 0;
        end else if (input_link_2.req) begin
            output_link.req = input_link_2.req;
            output_link.packet = input_link_2.packet;
            input_link_0.ack = 0;
            input_link_1.ack = 0;
            input_link_2.ack = output_link.ack;
            input_link_3.ack = 0;
        end else if (input_link_3.req) begin
            output_link.req = input_link_3.req;
            output_link.packet = input_link_3.packet;
            input_link_0.ack = 0;
            input_link_1.ack = 0;
            input_link_2.ack = 0;
            input_link_3.ack = output_link.ack;
        end else begin
            output_link.req = 0;
            output_link.packet = `NULL_PACKET;
            input_link_0.ack = 0;
            input_link_1.ack = 0;
            input_link_2.ack = 0;
            input_link_3.ack = 0;
        end
    end
endmodule
