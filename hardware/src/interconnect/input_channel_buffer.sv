/*
 * TIA has buffers on both input and output channels. This is the input channel buffer.
 * Note that attempts to dequeue from an empty input channel will be ignored.
 */

`include "interconnect.svh"

module input_channel_buffer
    #(parameter FIFO_DEPTH = TIA_CHANNEL_BUFFER_FIFO_DEPTH)
    (input logic clock, // Positive-edge triggered.
     input logic reset, // Active high.
     input logic enable, // Active high.
     link_if.receiver link,
     input_channel_if.sender input_channel,
     output logic quiescent);

    // --- Internal Logic and Wiring ---

    // A FIFO queue of packets.
    packet_t fifo [FIFO_DEPTH - 1:0];

    // Interal state.
    logic [$clog2(FIFO_DEPTH) - 1:0] head, tail, neck;
    logic [$clog2(FIFO_DEPTH):0] count;

    // --- Combinational Logic ---

    // Expose the head of the queue for peeking as well as the next tag, and define the empty flag
    // and count.
    assign input_channel.packet = fifo[head];
    assign neck = head + 1;
    assign input_channel.next_packet = (count > 1) ? fifo[neck] : 0;
    assign input_channel.empty = (count == 0);
    assign input_channel.count = count;

    // As long as the FIFO is not full, we can take more packets so ack should be high.
    assign link.ack = (count != FIFO_DEPTH);

    // Show whether we can consider this buffer quiescent.
    assign quiescent = input_channel.empty;

    // --- Sequential Logic ---

    // Handle dequeues from the input channel and transfers over the link.
    always_ff @(posedge clock) begin
        if (reset) begin
            head <= '0;
            tail <= '0;
            count <= '0;
        end else if (enable) begin
            if (input_channel.dequeue) begin
                if (count != 0) begin
                    if (link.req && (count != FIFO_DEPTH)) begin
                        fifo[tail] <= link.packet;
                        head <= head + 1;
                        tail <= tail + 1;
                    end else begin
                        head <= head + 1;
                        count <= count - 1;
                    end
                end
            end else begin
                if (link.req && (count != FIFO_DEPTH)) begin
                    fifo[tail] <= link.packet;
                    tail <= tail + 1;
                    count <= count + 1;
                end
            end
        end
    end
endmodule
