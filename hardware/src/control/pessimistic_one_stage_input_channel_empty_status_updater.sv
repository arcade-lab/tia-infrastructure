/*
 * This module addresses a somewhat obscure data dependency unique to the triggered instruction
 * architecture. With separate trigger and decode stages (where decode is also responsible for
 * fetching sources), it is possible for an instruction to trigger incorrectly assuming that an
 * input channel (whose head is only to be dequeued in the decode stage) is non-empty when in fact
 * it is. Furthermore, this can also lead to the same item being "consumed" twice. This module
 * does not look at the channel buffer counts and assumes the worst.
 */

`include "control.svh"

module pessimistic_one_stage_input_channel_empty_status_updater
    (input logic [TIA_NUM_INPUT_CHANNELS - 1:0] input_channel_empty_status,
     input logic [TIA_ICD_WIDTH - 1:0] downstream_icd,
     output logic [TIA_NUM_INPUT_CHANNELS - 1:0] updated_input_channel_empty_status);

    // --- Combinational Logic ---

    // OR in any updated statuses.
    assign updated_input_channel_empty_status = input_channel_empty_status
                                                | downstream_icd;
endmodule
