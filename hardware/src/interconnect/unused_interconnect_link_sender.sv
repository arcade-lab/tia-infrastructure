/*
 * A module to terminate unused reciever links.
 */

`include "interconnect.svh"

module unused_interconnect_link_sender
    (interconnect_link_if.sender interconnect_link);

    // Not synthesized.
    integer i;

    // Never produce any req packets.
    assign interconnect_link.reqs = {TIA_NUM_PHYSICAL_PLANES{1'b0}};
    always_comb begin
        for (i = 0; i < TIA_NUM_PHYSICAL_PLANES; i++) begin
            interconnect_link.tag_lines[i] = 0;
            interconnect_link.data_lines[i] = 0;
        end
    end
endmodule
