/*
 * A module to encapsulate predicate state and calculate updates based on ALU output and
 * instruction settings. This predicate unit additionally supports speculating on the results of
 * datapath predicate updates.
 */

`include "control.svh"

module speculative_predicate_unit
    (input logic clock, // Positive-edge triggered.
     input logic reset, // Active high.
     input logic enable, // Active high.
     input logic [TIA_DT_WIDTH - 1:0] datapath_dt,
     input logic [TIA_DI_WIDTH - 1:0] datapath_di,
     input logic [TIA_WORD_WIDTH - 1:0] datapath_result,
     input logic [TIA_PUM_WIDTH - 1:0] instruction_pum,
     input logic [TIA_DT_WIDTH - 1:0] instruction_dt,
     input logic [TIA_DI_WIDTH - 1:0] instruction_di,
     input logic [TIA_OP_WIDTH - 1:0] instruction_op,
     input logic [TIA_ICD_WIDTH - 1:0] instruction_icd,
     output logic [TIA_NUM_PREDICATES - 1:0] predicates,
     output logic trigger_override,
     output logic predicate_prediction_hit,
     output logic predicate_prediction_miss);

    // --- Internal Logic and Wiring ---

    // Not synthesized.
    integer i, j;

    // Intermediate datapath pum and final pum.
    logic [2 * TIA_NUM_PREDICATES - 1:0] datapath_pum, pum;
    logic [TIA_NUM_PREDICATES - 1:0] predicate_set_mask, predicate_unset_mask, next_predicates;

    // Prediction logic.
    logic [TIA_NUM_PREDICATES - 1:0] predictions;
    logic speculating;
    logic [TIA_NUM_PREDICATES - 1:0] hit_predicates, miss_predicates, saved_predicates;
    logic prediction, saved_prediction;
    logic begin_speculation, end_speculation;

    // An array of predicate predictors.
    predicate_predictor_bank ppb(.clock(clock),
                                 .reset(reset),
                                 .enable(enable),
                                 .datapath_write(datapath_dt == TIA_DESTINATION_TYPE_PREDICATE),
                                 .datapath_di(datapath_di),
                                 .observed_value(|datapath_result),
                                 .predictions(predictions));

    // --- Combinational Logic ---

    // Lookup the prediction.
    always_comb begin
        if (instruction_dt == TIA_DESTINATION_TYPE_PREDICATE)
            prediction = predictions[instruction_di];
        else
            prediction = 0;
    end

    // Conditions for beginning and ending a speculative section. While we forbid nested
    // speculation, it is possible for one speculative section to elide into the other.
    assign begin_speculation = ((!speculating || (end_speculation && !predicate_prediction_miss))
                                && (instruction_dt == TIA_DESTINATION_TYPE_PREDICATE)
                                && !trigger_override);
    assign end_speculation = (speculating && (datapath_dt == TIA_DESTINATION_TYPE_PREDICATE));

    // Conditions for overriding a triggered instruction externally.
    assign trigger_override = (speculating && (((instruction_dt == TIA_DESTINATION_TYPE_PREDICATE) && !predicate_prediction_hit) // We do not supported nested speculation.
                                               || (instruction_op == TIA_OP_SSW) // No speculative instruction can modify the scratchpad.
                                               || ((|instruction_icd) && !predicate_prediction_hit)));  // No speculative instruction can dequeue from an input channel.


    // Exposed hit and miss signals.
    assign predicate_prediction_hit = (speculating && end_speculation && (saved_prediction == (|datapath_result)));
    assign predicate_prediction_miss = (speculating && end_speculation && (saved_prediction != (|datapath_result)));

    // Calculate the predicates as they would appear should we have a hit or miss.
    always_comb begin
        for (j = 0; j < TIA_NUM_PREDICATES; j++) begin
            if (j == instruction_di) begin
                hit_predicates[j] = prediction;
                miss_predicates[j] = ~prediction;
            end else begin
                hit_predicates[j] = next_predicates[j];
                miss_predicates[j] = next_predicates[j];
            end
        end
    end

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
    // cannot conflict. At the end of speculation, however, knowing we have already incorporated a
    // predicted datapath result, we use only the current instruction's pum as the effective pum.
    assign pum = end_speculation ? instruction_pum : instruction_pum | datapath_pum;

    // Compute the next predicate values.
    assign predicate_set_mask = pum[TIA_NUM_PREDICATES * 2 - 1:TIA_NUM_PREDICATES];
    assign predicate_unset_mask = pum[TIA_NUM_PREDICATES - 1:0];
    assign next_predicates = (predicates | predicate_set_mask) & ~predicate_unset_mask;

    // --- Sequential Logic ---

    // Latch in the prediction and backup predicates in the event of a prediction miss.
    always_ff @(posedge clock) begin
        if (reset) begin
            speculating <= 0;
            saved_prediction <= 0;
            saved_predicates <= 0;
        end else if (enable) begin
            if (begin_speculation) begin
                speculating <= 1;
                saved_prediction <= prediction;
                saved_predicates <= miss_predicates;
            end else if (end_speculation)
                speculating <= 0;
        end
    end

    // Latch in predicates and handle resets.
    always_ff @(posedge clock) begin
        if (reset)
            predicates <= 0;
        else if (enable) begin
            if (begin_speculation)
                predicates <= hit_predicates;
            else if (predicate_prediction_miss)
                predicates <= saved_predicates;
            else if (!trigger_override)
                predicates <= next_predicates;
        end
    end
endmodule
