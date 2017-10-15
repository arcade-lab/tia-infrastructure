/*
 * Module to dequeue the requested input channels.
 */

`include "datapath.svh"

module dequeueing_unit
    (input logic enable,
     input logic [TIA_ICD_WIDTH - 1:0] icd, // Same width.
     output logic [TIA_NUM_INPUT_CHANNELS - 1:0] dequeue_signals); // Same width.

    // --- Combinational Logic ---

    // Generate the requested dequeue signals.
    assign dequeue_signals = enable ? icd : 0;
endmodule
