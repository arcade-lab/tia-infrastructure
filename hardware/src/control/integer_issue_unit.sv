/*
 * At the beginning of the decode stage, this ROM LUT will determine when an instruction will
 * retire and what functional unit it will use.
 */

`include "control.svh"

module integer_issue_unit
    (input logic [TIA_OP_WIDTH - 1:0] dx1_instruction_op,
     output logic [2:0] retiring_stage,
     output functional_unit_t functional_unit);

    // --- Combinational Logic ---

    // LUT-style ROM.
    always_comb begin
        unique case (dx1_instruction_op)
            TIA_OP_NOP, TIA_OP_MOV, TIA_OP_ADD, TIA_OP_SUB, TIA_OP_SL, TIA_OP_ASR, TIA_OP_LSR,
            TIA_OP_EQ, TIA_OP_NE, TIA_OP_SGT, TIA_OP_UGT, TIA_OP_SLT, TIA_OP_ULT, TIA_OP_SGE,
            TIA_OP_UGE, TIA_OP_SLE, TIA_OP_ULE, TIA_OP_BAND, TIA_OP_BNAND, TIA_OP_BOR, TIA_OP_BNOR,
            TIA_OP_BXOR, TIA_OP_BXNOR, TIA_OP_LAND, TIA_OP_LNAND, TIA_OP_LOR, TIA_OP_LNOR,
            TIA_OP_LXOR,TIA_OP_LXNOR, TIA_OP_GB, TIA_OP_SB, TIA_OP_CB, TIA_OP_MB,
            TIA_OP_CLZ, TIA_OP_CTZ, TIA_OP_HALT: begin
                retiring_stage = 1;
                functional_unit = ALU;
            end
            TIA_OP_LSW, TIA_OP_SSW: begin
                retiring_stage = 2;
                functional_unit = SM;
            end
            TIA_OP_LMUL, TIA_OP_SHMUL, TIA_OP_UHMUL, TIA_OP_MAC: begin
                retiring_stage = 2;
                functional_unit = IMU;
            end
            default: begin
                retiring_stage = 1;
                functional_unit = ALU;
            end
        endcase
    end
endmodule
