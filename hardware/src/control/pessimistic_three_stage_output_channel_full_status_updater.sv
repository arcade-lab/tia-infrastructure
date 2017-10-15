/*
 * Pessimistically update the output channels as full based on the instructions in three downstream
 * pipeline stages.
 */

`include "control.svh"

module pessimistic_three_stage_output_channel_full_status_updater
    (input logic [TIA_NUM_OUTPUT_CHANNELS - 1:0] output_channel_full_status,
     input logic [TIA_OCI_WIDTH - 1:0] first_downstream_oci,
     input logic [TIA_OCI_WIDTH - 1:0] second_downstream_oci,
     input logic [TIA_OCI_WIDTH - 1:0] third_downstream_oci,
     output logic [TIA_NUM_OUTPUT_CHANNELS - 1:0] updated_output_channel_full_status);

    // --- Internal Logic and Wiring ---

    // Not synthesized.
    integer i, j, k;

    // Updated masks originating from the three separate downstream pipeline stages.
    logic [TIA_NUM_OUTPUT_CHANNELS - 1:0] first_downstream_updated_output_channel_full_status,
                                          second_downstream_updated_output_channel_full_status,
                                          third_downstream_updated_output_channel_full_status;

    // --- Combinational Logic ---

    // If any downstream instruction is writing to an output channel, assume that the destination
    // channel is full.
    always_comb begin
        for (i = 0; i < TIA_NUM_OUTPUT_CHANNELS; i++) begin
            if (first_downstream_oci[i])
                first_downstream_updated_output_channel_full_status[i] = 1;
            else
                first_downstream_updated_output_channel_full_status[i] = output_channel_full_status[i];
        end
        for (j = 0; j < TIA_NUM_OUTPUT_CHANNELS; j++) begin
            if (second_downstream_oci[j])
                second_downstream_updated_output_channel_full_status[j] = 1;
            else
                second_downstream_updated_output_channel_full_status[j] = output_channel_full_status[j];
        end
        for (k = 0; k < TIA_NUM_OUTPUT_CHANNELS; k++) begin
            if (third_downstream_oci[k])
                third_downstream_updated_output_channel_full_status[k] = 1;
            else
                third_downstream_updated_output_channel_full_status[k] = output_channel_full_status[k];
        end
    end

    // The updated status we output is just the logical OR of any updates incurred in the three
    // downstream stages.
    assign updated_output_channel_full_status = first_downstream_updated_output_channel_full_status
                                                | second_downstream_updated_output_channel_full_status
                                                | third_downstream_updated_output_channel_full_status;
endmodule
