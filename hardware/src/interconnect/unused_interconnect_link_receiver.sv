/*
 * A module to terminate unused reciever links.
 */

`include "interconnect.svh"

module unused_interconnect_link_receiver
    (interconnect_link_if.receiver interconnect_link);

    // Never ack any packets.
    assign interconnect_link.acks = {TIA_NUM_PHYSICAL_PLANES{1'b0}};
endmodule
