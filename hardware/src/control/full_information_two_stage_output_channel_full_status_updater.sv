/*
 * Precisely update the output channels as full based on the instructions in two downstream
 * pipeline stages.
 */

`include "control.svh"

module full_information_two_stage_output_channel_full_status_updater
    (input logic [TIA_CHANNEL_BUFFER_COUNT_WIDTH - 1:0] output_channel_counts [TIA_NUM_OUTPUT_CHANNELS - 1:0],
     input logic [TIA_OCI_WIDTH - 1:0] first_downstream_oci,
     input logic [TIA_OCI_WIDTH - 1:0] second_downstream_oci,
     output logic [TIA_NUM_OUTPUT_CHANNELS - 1:0] updated_output_channel_full_status);

    // --- Internal Logic and Wiring ---

    // Not synthesized.
    integer i, j, k;

    // Intentionally has one bit of extra width for overflow.
    logic [TIA_CHANNEL_BUFFER_COUNT_WIDTH:0] first_downstream_updated_output_channel_counts [TIA_NUM_OUTPUT_CHANNELS - 1:0];
    logic [TIA_CHANNEL_BUFFER_COUNT_WIDTH:0] second_downstream_updated_output_channel_counts [TIA_NUM_OUTPUT_CHANNELS - 1:0];

    // --- Combinational Logic ---

    // Sum up the in-flight output channel destinations.
    always_comb begin
        for (i = 0; i < TIA_NUM_OUTPUT_CHANNELS; i++) begin
            if (first_downstream_oci[i])
                first_downstream_updated_output_channel_counts[i] = output_channel_counts[i] + 1;
            else
                first_downstream_updated_output_channel_counts[i] = output_channel_counts[i];
        end
        for (j = 0; j < TIA_NUM_OUTPUT_CHANNELS; j++) begin
            if (second_downstream_oci[j])
                second_downstream_updated_output_channel_counts[j] = first_downstream_updated_output_channel_counts[j] + 1;
            else
                second_downstream_updated_output_channel_counts[j] = first_downstream_updated_output_channel_counts[j];
        end
    end

    // Check to see if the counts have been exceeded.
    always_comb begin
        for (k = 0; k < TIA_NUM_OUTPUT_CHANNELS; k++) begin
            if (second_downstream_updated_output_channel_counts[k] >= TIA_CHANNEL_BUFFER_FIFO_DEPTH)
                updated_output_channel_full_status[k] = 1;
            else
                updated_output_channel_full_status[k] = 0;
        end
    end
endmodule
