/*
 * A module to encapsulate predicate state and calculate updates based on ALU output and
 * instruction settings.
 */

`include "control.svh"

module predicate_unit
    (input logic clock, // Positive-edge triggered.
     input logic reset, // Active high.
     input logic enable, // Active high.
     input logic [TIA_DT_WIDTH - 1:0] datapath_dt,
     input logic [TIA_DI_WIDTH - 1:0] datapath_di,
     input logic [TIA_WORD_WIDTH - 1:0] datapath_result,
     input logic [TIA_PUM_WIDTH - 1:0] instruction_pum,
     output logic [TIA_NUM_PREDICATES - 1:0] predicates);

    // --- Internal Logic and Wiring ---

    // Not synthesized.
    integer i;

    // Intermediate datapath pum and final pum.
    logic [2 * TIA_NUM_PREDICATES - 1:0] datapath_pum, pum;
    logic [TIA_NUM_PREDICATES - 1:0] predicate_set_mask, predicate_unset_mask, next_predicates;

    // --- Combinational Logic ---

    // Generate the datapath pum.
    always_comb begin
        // If the instruction is modifying a destination...
        if (datapath_dt == TIA_DESTINATION_TYPE_PREDICATE) begin
            // Update the datapath's true and false pum segment according to the destination
            // index. All other indices have a pum value of zero (no change).
            for (i = 0; i < TIA_NUM_PREDICATES; i++) begin
                if (i == datapath_di) begin
                    datapath_pum[i + TIA_NUM_PREDICATES] = |datapath_result; // True pum.
                    datapath_pum[i] = ~|datapath_result; // False pum.
                end else begin
                    datapath_pum[i + TIA_NUM_PREDICATES] = 0; // True pum.
                    datapath_pum[i] = 0; // False pum.
                end
            end
        end else begin
            // Keep the mask empty so as not to change the pum if the instruction does not have
            // a predicate destination.
            datapath_pum = 0;
        end
    end

    // The pum is the bitwise OR of the two constituent pums, since the assembler guarantees they
    // cannot conflict.
    assign pum = instruction_pum | datapath_pum;

    // Compute the next predicate values.
    assign predicate_set_mask = pum[TIA_NUM_PREDICATES * 2 - 1:TIA_NUM_PREDICATES];
    assign predicate_unset_mask = pum[TIA_NUM_PREDICATES - 1:0];
    assign next_predicates = (predicates | predicate_set_mask) & ~predicate_unset_mask;

    // --- Sequential Logic ---

    // Latch in predicates and handle resets.
    always_ff @(posedge clock) begin
        if (reset)
            predicates <= 0;
        else if (enable)
            predicates <= next_predicates;
    end
endmodule
