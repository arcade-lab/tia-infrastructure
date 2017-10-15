/*
 * This module detects issues with multiple instructions possibly retiring in the same cycle. It
 * forbids this by treating it in a way similar to a data hazard in the trigger stage.
 */

`include "control.svh"

module integer_collision_detector
    (input logic [TIA_OP_WIDTH - 1:0] triggered_instruction_op,
     input logic [2:0] dx1_instruction_retiring_stage,
     output logic collision);

    // --- Combinational Logic ---

    // A collision can only occur when a single-cycle instruction is being scheduled the same cycle
    // as a final stage instruction is retiring.
    always_comb begin
        unique case (triggered_instruction_op)
            TIA_OP_NOP, TIA_OP_MOV, TIA_OP_ADD, TIA_OP_SUB, TIA_OP_SL, TIA_OP_ASR, TIA_OP_LSR,
            TIA_OP_EQ, TIA_OP_NE, TIA_OP_SGT, TIA_OP_UGT, TIA_OP_SLT, TIA_OP_ULT, TIA_OP_SGE,
            TIA_OP_UGE, TIA_OP_SLE, TIA_OP_ULE, TIA_OP_BAND, TIA_OP_BNAND, TIA_OP_BOR, TIA_OP_BNOR,
            TIA_OP_BXOR, TIA_OP_BXNOR, TIA_OP_LAND, TIA_OP_LNAND, TIA_OP_LOR, TIA_OP_LNOR,
            TIA_OP_LXOR, TIA_OP_LXNOR, TIA_OP_GB, TIA_OP_SB, TIA_OP_CB, TIA_OP_MB,
            TIA_OP_CLZ, TIA_OP_CTZ, TIA_OP_HALT:
                collision = (dx1_instruction_retiring_stage == 2) ? 1 : 0;
            default:
                collision = 0;
        endcase
    end
endmodule
