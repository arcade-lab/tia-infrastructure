/*
 * A module to terminate unused reciever links.
 */

`include "interconnect.svh"

module unused_link_receiver
    (link_if.receiver link);

    // Never ack any packets.
    assign link.ack = 0;
endmodule
