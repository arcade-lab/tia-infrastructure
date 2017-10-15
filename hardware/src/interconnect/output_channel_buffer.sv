/*
 * TIA has buffers on both input channels and output channels. This is the output channel buffer.
 * Note that attempts to enqueue to a full output channel will be ignored.
 */

`include "interconnect.svh"

module output_channel_buffer
    #(parameter FIFO_DEPTH = TIA_CHANNEL_BUFFER_FIFO_DEPTH)
    (input logic clock, // Positive-edge triggered.
     input logic reset, // Active high.
     input logic enable, // Active high.
     output_channel_if.receiver output_channel,
     link_if.sender link,
     output logic quiescent);

    // --- Internal Logic and Wiring ---

    // A FIFO queue of packets.
    packet_t fifo [FIFO_DEPTH - 1:0];

    // Internal state.
    logic [$clog2(FIFO_DEPTH) - 1:0] head, tail;
    logic [$clog2(FIFO_DEPTH):0] count;

    // --- Combinational Logic ---

    // Expose the full flag and count on the output channel interface.
    assign output_channel.full = (count == FIFO_DEPTH);
    assign output_channel.count = count;

    // The head of the queue is the current packet on the link, and valid should be raised so long as
    // the FIFO is not empty.
    assign link.packet = fifo[head];
    assign link.req = (count != 0);

    // Show whether we can consider this buffer quiescent.
    assign quiescent = (count == 0);

    // --- Sequential Logic ---

    // Handle enqueues from the output channel and transfers over the link.
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            head <= '0;
            tail <= '0;
            count <= '0;
        end else if (enable) begin
            if (output_channel.enqueue) begin
                if (count != FIFO_DEPTH) begin
                    fifo[tail] <= output_channel.packet;
                    if ((count != 0) && link.ack) begin
                        head <= head + 1;
                        tail <= tail + 1;
                    end else begin
                        tail <= tail + 1;
                        count <= count + 1;
                    end
                end
            end else begin
                if ((count != 0) && link.ack) begin
                    head <= head + 1;
                    count <= count - 1;
                end
            end
        end
    end
endmodule
