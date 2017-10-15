/*
 * Simple control logic for the execution within a single PE.
 */

`include "control.svh"

module execution_control_unit
    (input logic clock, // Positive-edge triggered.
     input logic reset, // Active high.
     input logic enable, // Active high.
     input logic execute,
     input logic [TIA_OP_WIDTH - 1:0] op,
     input logic [TIA_NUM_INPUT_CHANNELS - 1:0] input_channel_quiescent_status,
     input logic [TIA_NUM_OUTPUT_CHANNELS - 1:0] output_channel_quiescent_status,
     output logic internal_reset, // Active high.
     output logic internal_enable, // Active high.
     output logic halted,
     output logic channels_quiescent);

    // --- Sequential Logic ---

    // Buffer reset and enable.
    always_ff @(posedge clock) begin
        internal_reset <= reset;
        internal_enable <= enable & execute & ~halted;
    end

    // Detect a halt instruction.
    always_ff @(posedge clock) begin
       if (reset)
           halted <= 0;
       else if (enable && execute) begin
           if (op == TIA_OP_HALT)
               halted <= 1;
       end
   end

   // Detect whether the channels are quiescent.
   always_ff @(posedge clock) begin
       if (reset)
           channels_quiescent <= 0;
       else if (enable) begin
           channels_quiescent <= &{input_channel_quiescent_status,
                                   output_channel_quiescent_status};
       end
   end
endmodule
