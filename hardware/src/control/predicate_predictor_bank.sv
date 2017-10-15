/*
 * A bank of predicate predictors for speculating on the result of predicate datapath writes.
 */

`include "control.svh"

module predicate_predictor_bank
    (input logic clock, // Positive-edge triggered.
     input logic reset, // Active high.
     input logic enable, // Active high.
     input logic datapath_write,
     input logic [TIA_DI_WIDTH - 1:0] datapath_di,
     input logic observed_value,
     output logic [TIA_NUM_PREDICATES - 1:0] predictions);

    // --- Internal Logic and Wiring ---

    logic [$clog2(TIA_NUM_PREDICATES) - 1:0] datapath_write_select;
    logic [TIA_NUM_PREDICATES - 1:0] datapath_write_signals;

    integer i;

    // --- Combinational Logic ---

    assign datapath_write_select = datapath_di[$clog2(TIA_NUM_PREDICATES) - 1:0];

    // Decode the datapath write signal and destination.
    always_comb begin
        for (i = 0; i < TIA_NUM_PREDICATES; i++) begin
            if (i == datapath_write_select)
                datapath_write_signals[i] = datapath_write;
            else
                datapath_write_signals[i] = 0;
        end
    end

    // --- Module Instantiation ---

    // Generate the array of predicate predictors.
    genvar j;
    generate
        for (j = 0; j < TIA_NUM_PREDICATES; j++) begin: pp_gen
            predicate_predictor pp(clock,
                                   reset,
                                   enable,
                                   datapath_write_signals[j],
                                   observed_value,
                                   predictions[j]);
        end
    endgenerate
endmodule
