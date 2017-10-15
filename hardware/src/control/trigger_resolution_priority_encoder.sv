/*
 * A parametrizable length priority encoder for the trigger resolution unit of a PE.
 */

`include "control.svh"

module trigger_resolution_priority_encoder
    (input logic [TIA_MAX_NUM_INSTRUCTIONS - 1:0] trigger_states,
     output logic triggered_instruction_valid,
     output logic [TIA_INSTRUCTION_INDEX_WIDTH - 1:0] triggered_instruction_index);

    // --- Internal Logic and Wiring ---

    // Not synthesized.
    integer i, putative_index;

    // --- Combinational Logic ---

    always_comb begin
        // Set the putative index to a canary in the event that there is no valid trigger in a
        // given cycle. Note this assumes there are 128 or fewer instructions per PE.
        putative_index = TIA_MAX_NUM_INSTRUCTIONS;

        // Find the first instruction with a valid trigger.
        for (i = 0; i < TIA_MAX_NUM_INSTRUCTIONS; i++) begin
            if (trigger_states[i]) begin
                putative_index = i;
                break;
            end
        end

        // Determine if there was a valid trigger.
        if (putative_index == TIA_MAX_NUM_INSTRUCTIONS) begin
            triggered_instruction_valid = 0;
            triggered_instruction_index = 0;
        end else begin
            triggered_instruction_valid = 1;
            triggered_instruction_index = putative_index;
        end
    end
endmodule

