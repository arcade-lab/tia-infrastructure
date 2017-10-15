/*
 * A module to terminate unused reciever links.
 */

`include "interconnect.svh"

module unused_link_sender
    (link_if.sender link);

    // Never produce any req packets.
    assign link.req = 0;
    assign link.packet.tag = 0;
    assign link.packet.data = 0;
endmodule
