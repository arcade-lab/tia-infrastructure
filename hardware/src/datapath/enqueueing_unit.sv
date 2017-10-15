/*
 * Module to handle firing the enqueue signals and making sure that the output
 * channels have the propert tags.
 */

`include "datapath.svh"

module enqueueing_unit
    (input logic enable,
     input logic [TIA_OCI_WIDTH - 1:0] oci,
     input logic [TIA_OCT_WIDTH - 1:0] oct,
     output logic [TIA_NUM_OUTPUT_CHANNELS - 1:0] enqueue_signals,
     output logic [TIA_OCT_WIDTH - 1:0] output_channel_tags [TIA_NUM_OUTPUT_CHANNELS - 1:0]);

    // --- Internal Logic and Wiring ---

    // Not synthesized.
    integer i, j;

    // --- Combinational Logic ---

    // Generate the requested enqueue signal and accompanying tag.
    assign enqueue_signals = enable ? oci : 0;
    always_comb begin
        if (enable) begin
            for (i = 0; i < TIA_NUM_OUTPUT_CHANNELS; i++)
                output_channel_tags[i] = enqueue_signals[i] ? oct : 0;
        end else begin
            for (j = 0; j < TIA_NUM_OUTPUT_CHANNELS; j++)
                output_channel_tags[j] = 0;
        end
    end
endmodule
