/*
 * Link buffers for pipelined communication over the interconnect links.
 */

`include "interconnect.svh"

module link_buffer
    #(parameter FIFO_DEPTH = TIA_LINK_BUFFER_FIFO_DEPTH)
    (input logic clock, // Positive-edge triggered.
     input logic reset, // Active high.
     input logic enable, // Active high.
     output logic quiescent,
     link_if.receiver input_link,
     link_if.sender output_link);

    // --- Internal Logic and Wiring ---

    // A FIFO queue of packets.
    packet_t [FIFO_DEPTH - 1:0] fifo;

    // Internal state.
    logic [$clog2(FIFO_DEPTH) - 1:0] head, tail;
    logic [$clog2(FIFO_DEPTH):0] count;

    // --- Combinational Logic ---

    // We can only receive new packets if there is room left in the buffer.
    assign input_link.ack = (input_link.req && count != FIFO_DEPTH);

    // Offer req packets to the downstream link.
    assign output_link.packet = fifo[head];
    assign output_link.req = (count != 0);

    // Show whether we can consider this buffer quiescent.
    assign quiescent = (count == 0);

    // --- Sequential Logic ---

    // Latch in and release packets from the head and tail.
    always_ff @(posedge clock) begin
        if (reset) begin
           head <= 0;
           tail <= 0;
           count <= 0;
        end else if (enable) begin
            if (input_link.ack) begin
                fifo[tail] <= input_link.packet;
                if (output_link.req && output_link.ack) begin
                    head <= head + 1;
                    tail <= tail + 1;
                end else begin
                    tail <= tail + 1;
                    count <= count + 1;
                end
            end else begin
                if (output_link.req && output_link.ack) begin
                    head <= head + 1;
                    count <= count - 1;
                end
            end
        end
    end
endmodule
