/*
 * Detect RAW data hazards between two subsequent pipeline stages in a design with more than one
 * execute stage.
 */

`include "control.svh"

module data_hazard_detector
    (input [TIA_ST_WIDTH - 1:0] current_st,
     input [TIA_SI_WIDTH - 1:0] current_si,
     input [TIA_DT_WIDTH - 1:0] downstream_dt,
     input [TIA_DI_WIDTH - 1:0] downstream_di,
     output hazard);

    // --- Internal Logic and Wiring ---

    // Individual source types and indices.
    logic [TIA_SINGLE_ST_WIDTH - 1:0] current_st_0, current_st_1, current_st_2;
    logic [TIA_SINGLE_SI_WIDTH - 1:0] current_si_0, current_si_1, current_si_2;

    // Hazards in each operand.
    logic operand_0_raw_hazard, operand_1_raw_hazard, operand_2_raw_hazard;

    // --- Combinational Logic ---

    // Separate the source types and source destinations from the pre-SDU instruction for later use.
    assign current_st_0 = current_st[TIA_SINGLE_ST_WIDTH - 1:0];
    assign current_st_1 = current_st[2* TIA_SINGLE_ST_WIDTH - 1:TIA_SINGLE_ST_WIDTH];
    assign current_st_2 = current_st[TIA_ST_WIDTH - 1:2 * TIA_SINGLE_ST_WIDTH];
    assign current_si_0 = current_si[TIA_SINGLE_SI_WIDTH - 1:0];
    assign current_si_1 = current_si[2 * TIA_SINGLE_SI_WIDTH - 1:TIA_SINGLE_SI_WIDTH];
    assign current_si_2 = current_si[TIA_SI_WIDTH - 1:2 * TIA_SINGLE_SI_WIDTH];

    // Determine if there is a hazard centered on operand 0.
    assign operand_0_raw_hazard = (current_st_0 == TIA_SOURCE_TYPE_REGISTER
                                   && downstream_dt == TIA_DESTINATION_TYPE_REGISTER
                                   && current_si_0 == downstream_di);
    assign operand_1_raw_hazard = (current_st_1 == TIA_SOURCE_TYPE_REGISTER
                                   && downstream_dt == TIA_DESTINATION_TYPE_REGISTER
                                   && current_si_1 == downstream_di);
    assign operand_2_raw_hazard = (current_st_2 == TIA_SOURCE_TYPE_REGISTER
                                   && downstream_dt == TIA_DESTINATION_TYPE_REGISTER
                                   && current_si_2 == downstream_di);

    // Either operand may trigger the hazard signal.
    assign hazard = operand_0_raw_hazard | operand_1_raw_hazard | operand_2_raw_hazard;
endmodule
