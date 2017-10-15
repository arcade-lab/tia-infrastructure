/*
 * Pessimistically update the output channels as full based on the instructions in a single
 * downstream pipeline stage.
 */

`include "control.svh"

module pessimistic_one_stage_output_channel_full_status_updater
    (input logic [TIA_NUM_OUTPUT_CHANNELS - 1:0] output_channel_full_status,
     input logic [TIA_OCI_WIDTH - 1:0] downstream_oci,
     output logic [TIA_NUM_OUTPUT_CHANNELS - 1:0] updated_output_channel_full_status);

    // --- Internal Logic and Wiring ---

    // Not synthesized.
    integer i;

    // --- Combinational Logic ---

    // If the instruction is writing to an output channel, assume that the destination channel is
    // full.
    always_comb begin
        for (i = 0; i < TIA_NUM_OUTPUT_CHANNELS; i++) begin
            if (downstream_oci[i])
                updated_output_channel_full_status[i] = 1;
            else
                updated_output_channel_full_status[i] = output_channel_full_status[i];
        end
    end
endmodule
