/*
 * In designs with split trigger and decode stages, it is necessary to make sure the trigger stage
 * sees the tag from the next item after the head of an input channel buffer, in the event that
 * there is a pending dequeue waiting in the decode stage. Exposing this next tag to the trigger
 * resolution unit guarantees the same execution patterns as a single-cycle design.
 */

`include "interconnect.svh"

module input_channel_tag_lookahead_unit
    (input logic [TIA_NUM_INPUT_CHANNELS - 1:0] pending_dequeue_signals,
     input logic [TIA_TAG_WIDTH - 1:0] original_tags [TIA_NUM_INPUT_CHANNELS - 1:0],
     input logic [TIA_TAG_WIDTH - 1:0] next_tags [TIA_NUM_INPUT_CHANNELS - 1:0],
     output logic [TIA_TAG_WIDTH - 1:0] resolved_tags [TIA_NUM_INPUT_CHANNELS - 1:0]);

    // --- Internal Logic and Wiring ---

    // Not synthesized.
    integer i;

    // --- Combinational Logic ---

    // Multiplex the two possible tags.
    always_comb begin
        for (i = 0; i < TIA_NUM_INPUT_CHANNELS; i++)
            resolved_tags[i] = pending_dequeue_signals[i] ? next_tags[i] : original_tags[i];
    end
endmodule
