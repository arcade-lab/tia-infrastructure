/*
 * Simple link circuit connection.
 */

`include "interconnect.svh"

module link_connector
    (link_if.receiver sender,
     link_if.sender receiver);

    // Circuit connection.
    assign sender.ack = receiver.ack;
    assign receiver.req = sender.req;
    assign receiver.packet = sender.packet;
endmodule
