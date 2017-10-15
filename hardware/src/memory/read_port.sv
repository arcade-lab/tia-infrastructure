/*
 * Minimal, low-latency read port FSM. Contains a channel endpoint for thre read index.
 */

`include "memory.svh"

module read_port
    (input logic clock, // Positive-edge triggered.
     input logic reset, // Active high.
     input logic enable, // Active high.
     link_if.receiver read_index_input_link,
     link_if.sender read_data_output_link,
     output logic read_enable,
     output logic [TIA_WORD_WIDTH - 1:0] read_index,
     input logic [TIA_WORD_WIDTH - 1:0] read_data,
     output logic quiescent);

    // --- Internal Logic and Wiring ---

    // Input and output channels.
    input_channel_if read_index_input_channel();
    output_channel_if read_data_output_channel();

    // Quiescent status.
    logic riicb_quiescent, rdocb_quiescent;

    // Input and output channel buffers.
    input_channel_buffer riicb(.clock(clock),
                               .reset(reset),
                               .enable(enable),
                               .link(read_index_input_link),
                               .input_channel(read_index_input_channel),
                               .quiescent(riicb_quiescent));
    output_channel_buffer rdocb(.clock(clock),
                                .reset(reset),
                                .enable(enable),
                                .output_channel(read_data_output_channel),
                                .link(read_data_output_link),
                                .quiescent(rdocb_quiescent));

    // FSM state.
    enum logic {STATE_0, STATE_1} current_state, next_state;

    // --- Combinational Logic ---

    // Always keep read enable high to decrease the latency.
    assign read_enable = enable;

    // Wire the incoming read index packet's data to the read index port.
    assign read_index = read_index_input_channel.packet.data;

    // Return the tag used by the index packet.
    assign read_data_output_channel.packet.tag = read_index_input_channel.packet.tag;
    assign read_data_output_channel.packet.data = read_data;

    // Generate the next state.
    always_comb begin
        if (enable) begin
            unique case (current_state)
                STATE_0: begin
                    // If there is a packet available on the read index channel, and room for at
                    // least one more packet on the read data output channel, go to State 1.
                    if (!read_index_input_channel.empty && !read_data_output_channel.full)
                        next_state = STATE_1;
                    else
                        next_state = STATE_0;
                end
                STATE_1: begin
                    // This is the state in which we enqueue and dequeue. Since read_enable has
                    // been kept high, we know that the read data is already available. We can now
                    // return to State 0.
                    next_state = STATE_0;
                end
            endcase
        end else begin
            // If we are disabled, do not change state.
            next_state = current_state;
        end
    end

    // Generate control signals based on the current state.
    always_comb begin
        if (enable) begin
            unique case (current_state)
                STATE_0: begin
                    // Do nothing.
                    read_index_input_channel.dequeue = 0;
                    read_data_output_channel.enqueue = 0;
                end
                STATE_1: begin
                    // Dequeue the address packet, and enqueue the read data.
                    read_index_input_channel.dequeue = 1;
                    read_data_output_channel.enqueue = 1;
                end
            endcase
        end else begin
            // If we are disabled, do nothing.
            read_index_input_channel.dequeue = 0;
            read_data_output_channel.enqueue = 0;
        end
    end

    // Show whether there are any pending reads.
    assign quiescent = riicb_quiescent && rdocb_quiescent;

    // --- Sequential Logic ---

    // Implement state transitions.
    always_ff @(posedge clock) begin
        if (reset) begin
            // Default to State 0.
            current_state <= STATE_0;
        end else if (enable) begin
            // Change states.
            current_state <= next_state;
        end
    end
endmodule
