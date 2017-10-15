/*
 * Minimal, low-latency write port FSM. Contains two channel endpoints for the write index and the
 * write data.
 */

`include "memory.svh"

module write_port
    (input logic clock, // Positive-edge triggered.
     input logic reset, // Active high.
     input logic enable, // Active high.
     link_if.receiver write_index_input_link,
     link_if.receiver write_data_input_link,
     output logic write_enable,
     output logic [TIA_WORD_WIDTH - 1:0] write_index,
     output logic [TIA_WORD_WIDTH - 1:0] write_data,
     output logic quiescent);

    // --- Local Parameters ---

    // FSM encoding.
    localparam TIA_WRITE_PORT_STATE_WIDTH = 1;
    localparam TIA_WRITE_PORT_STATE_0 = 0;
    localparam TIA_WRITE_PORT_STATE_1 = 1;

    // --- Internal Logic and Wiring ---

    // Input channels.
    input_channel_if write_index_input_channel();
    input_channel_if write_data_input_channel();

    // Quiescent status.
    logic wiicb_quiescent, wdicb_quiescent;

    // Input channel buffers.
    input_channel_buffer wiicb(.clock(clock),
                               .reset(reset),
                               .enable(enable),
                               .link(write_index_input_link),
                               .input_channel(write_index_input_channel),
                               .quiescent(wiicb_quiescent));
    input_channel_buffer wdicb(.clock(clock),
                               .reset(reset),
                               .enable(enable),
                               .link(write_data_input_link),
                               .input_channel(write_data_input_channel),
                               .quiescent(wdicb_quiescent));

    // FSM state.
    logic [TIA_WRITE_PORT_STATE_WIDTH - 1:0] current_state, next_state;

    // XXX: Debug.
    logic write_index_input_channel_dequeue, write_data_input_channel_dequeue;
    assign write_index_input_channel_dequeue = write_index_input_channel.dequeue;
    assign write_data_input_channel_dequeue = write_data_input_channel.dequeue;

    // Wire the incoming write index packet's data to the write index port.
    assign write_index = write_index_input_channel.packet.data;

    // Wire the incoming write data packet's data to the write data port.
    assign write_data = write_data_input_channel.packet.data;

    // --- Combinational Logic ---

    // Write enabled.
    assign write_enable = !write_index_input_channel.empty && !write_data_input_channel.empty;
    assign write_index_input_channel.dequeue = write_enable;
    assign write_data_input_channel.dequeue = write_enable;

    // Show whether there are any pending writes.
    assign quiescent = wiicb_quiescent && wdicb_quiescent;
endmodule
