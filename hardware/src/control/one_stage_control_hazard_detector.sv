/*
 * Detect a control hazard in one downstream pipeline stage.
 */

`include "control.svh"

module one_stage_control_hazard_detector
    (input [TIA_DT_WIDTH - 1:0] downstream_dt,
     output hazard);

    // --- Combinational Logic ---

    // Simply determine if there is a predicate destination downstream.
    assign hazard = (downstream_dt == TIA_DESTINATION_TYPE_PREDICATE);
endmodule
