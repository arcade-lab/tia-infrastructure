/*
 * Precisely update the output channels as full based on the instructions in a single
 * downstream pipeline stage.
 */

`include "control.svh"

module full_information_one_stage_output_channel_full_status_updater
    (input logic [TIA_CHANNEL_BUFFER_COUNT_WIDTH - 1:0] output_channel_counts [TIA_NUM_OUTPUT_CHANNELS - 1:0],
     input logic [TIA_OCI_WIDTH - 1:0] downstream_oci,
     output logic [TIA_NUM_OUTPUT_CHANNELS - 1:0] updated_output_channel_full_status);

    // --- Internal Logic and Wiring ---

    // Not synthesized.
    integer i, j;

    // Intentionally has one bit of extra width for overflow.
    logic [TIA_CHANNEL_BUFFER_COUNT_WIDTH:0] updated_output_channel_counts [TIA_NUM_OUTPUT_CHANNELS - 1:0];

    // --- Combinational Logic ---

    // Sum up the in-flight output channel destinations.
    always_comb begin
        for (i = 0; i < TIA_NUM_OUTPUT_CHANNELS; i++) begin
            if (downstream_oci[i])
                updated_output_channel_counts[i] = output_channel_counts[i] + 1;
            else
                updated_output_channel_counts[i] = output_channel_counts[i];
        end
    end

    // Check to see if the counts have been exceeded.
    always_comb begin
        for (j = 0; j < TIA_NUM_OUTPUT_CHANNELS; j++) begin
            if (updated_output_channel_counts[j] >= TIA_CHANNEL_BUFFER_FIFO_DEPTH)
                updated_output_channel_full_status[j] = 1;
            else
                updated_output_channel_full_status[j] = 0;
        end
    end
endmodule
