/*
 * The combined trigger resolution unit performs the scheduling of instructions relative to their
 * priority by checking their trigger segments against the current architecutral state.
 */

`include "control.svh"

module trigger_resolution_unit
    (input logic enable, // Active high.
     input logic execute, // Active high.
     input logic halted, // Active high.
     input trigger_t triggers [TIA_MAX_NUM_INSTRUCTIONS - 1:0],
     input logic [TIA_NUM_PREDICATES - 1:0] predicates,
     input logic [TIA_NUM_INPUT_CHANNELS - 1:0] input_channel_empty_status,
     input logic [TIA_TAG_WIDTH - 1:0] input_channel_tags [TIA_NUM_INPUT_CHANNELS - 1:0],
     input logic [TIA_NUM_OUTPUT_CHANNELS - 1:0] output_channel_full_status,
     output logic triggered_instruction_valid,
     output logic [TIA_INSTRUCTION_INDEX_WIDTH - 1:0] triggered_instruction_index);

    // --- Internal Logic and Wiring ---

    // Valid and invalid trigger states.
    logic [TIA_MAX_NUM_INSTRUCTIONS - 1:0] trigger_states;

    // Halt-insensitive valid instruction signal.
    logic halt_insensitive_triggered_instruction_valid;

    // Give each instruction a trigger resolver, and wire it up.
    genvar i;
    generate
        for (i = 0; i < TIA_MAX_NUM_INSTRUCTIONS; i++) begin: tr
            trigger_resolver tr(.trigger(triggers[i]),
                                .predicates(predicates),
                                .input_channel_empty_status(input_channel_empty_status),
                                .input_channel_tags(input_channel_tags),
                                .output_channel_full_status(output_channel_full_status),
                                .valid(trigger_states[i]));
        end
    endgenerate

    // Wire the output of the trigger resolvers into the priority encoder.
    trigger_resolution_priority_encoder trpe(.trigger_states(trigger_states),
                                             .triggered_instruction_valid(halt_insensitive_triggered_instruction_valid),
                                             .triggered_instruction_index(triggered_instruction_index));

    // --- Combinational Logic ---

    // Negate the trigger if we are halted.
    assign triggered_instruction_valid = enable && execute && halt_insensitive_triggered_instruction_valid && !halted;
endmodule
