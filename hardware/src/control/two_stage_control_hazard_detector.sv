/*
 * Detect a control hazard in two downstream pipeline stages.
 */

`include "control.svh"

module two_stage_control_hazard_detector
    (input [TIA_DT_WIDTH - 1:0] first_downstream_dt,
     input [TIA_DT_WIDTH - 1:0] second_downstream_dt,
     output hazard);

    // --- Combinational Logic ---

    // Simply determine if there is a predicate destination downstream.
    assign hazard = (first_downstream_dt == TIA_DESTINATION_TYPE_PREDICATE
                     || second_downstream_dt == TIA_DESTINATION_TYPE_PREDICATE);
endmodule
