/*
 * This module addresses a somewhat obscure data dependency unique to the triggered instruction
 * architecture. With separate trigger and decode stages (where decode is also responsible for
 * fetching sources), it is possible for an instruction to trigger incorrectly assuming that an
 * input channel (whose head is only to be dequeued in the decode stage) is non-empty when in fact
 * it is. Furthermore, this can also lead to the same item being "consumed" twice. This module
 * looks at the channel buffer counts to determine if this is indeed the case.
 */

`include "control.svh"

module full_information_one_stage_input_channel_empty_status_updater
    (input logic [TIA_CHANNEL_BUFFER_COUNT_WIDTH - 1:0] input_channel_counts [TIA_NUM_INPUT_CHANNELS - 1:0],
     input logic [TIA_ICD_WIDTH - 1:0] downstream_icd,
     output logic [TIA_NUM_INPUT_CHANNELS - 1:0] updated_input_channel_empty_status);

    // --- Internal Logic and Wiring ---

    // Not synthesized.
    integer i, j;

    // Split indices of channels to dequeue.
    logic [TIA_CHANNEL_BUFFER_COUNT_WIDTH - 1:0] updated_input_channel_counts [TIA_NUM_INPUT_CHANNELS - 1:0];

    // --- Combinational Logic ---

    // If there is a downstream dequeue, decrement the input channel count accordingly.
    always_comb begin
        for (i = 0; i < TIA_NUM_INPUT_CHANNELS; i++) begin
            if (downstream_icd[i]) begin
                if (input_channel_counts[i] == 0)
                    updated_input_channel_counts[i] = 0;
                else
                    updated_input_channel_counts[i] = input_channel_counts[i] - 1;
            end else
                updated_input_channel_counts[i] = input_channel_counts[i];
        end
    end

    // Generate the updated input channel empty status vector.
    always_comb begin
        for (j = 0; j < TIA_NUM_INPUT_CHANNELS; j++) begin
            if (updated_input_channel_counts[j] == 0)
                updated_input_channel_empty_status[j] = 1;
            else
                updated_input_channel_empty_status[j] = 0;
        end
    end
endmodule
