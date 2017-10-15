/*
 * Single-cycle integer ALU.
 */

`include "datapath.svh"

module arithmetic_logic_unit
    (input logic [TIA_OP_WIDTH - 1:0] op,
     input logic [TIA_WORD_WIDTH - 1:0] operand_0,
     input logic [TIA_WORD_WIDTH - 1:0] operand_1,
     input logic [TIA_WORD_WIDTH - 1:0] operand_2,
     output logic [TIA_WORD_WIDTH - 1:0] result);

    // --- Internal Logic and Wiring ---

    // Signed and unsigned operands.
    logic signed [TIA_WORD_WIDTH - 1:0] signed_operand_0, signed_operand_1, signed_operand_2;
    logic [TIA_WORD_WIDTH - 1:0] unsigned_operand_0, unsigned_operand_1, unsigned_operand_2;

    // Signed and unsigned results.
    logic signed [TIA_WORD_WIDTH - 1:0] signed_result;
    logic [TIA_WORD_WIDTH - 1:0] unsigned_result;

    // Bit indices and candidate indices for clz and ctz.
    integer i, j, candidate_index_clz, candidate_index_ctz;

    // --- Combinational Logic ---

    // Generate signed and unsigned operands.
    assign signed_operand_0 = operand_0;
    assign signed_operand_1 = operand_1;
    assign signed_operand_2 = operand_2;
    assign unsigned_operand_0 = operand_0;
    assign unsigned_operand_1 = operand_1;
    assign unsigned_operand_2 = operand_2;

    // Generate signed results.
    always_comb begin
        unique case (op)
            // Core integer ISA.
            TIA_OP_ASR: signed_result = signed_operand_0 >>> signed_operand_1;
            TIA_OP_SGT: signed_result = signed_operand_0 > signed_operand_1;
            TIA_OP_SLT: signed_result = signed_operand_0 < signed_operand_1;
            TIA_OP_SGE: signed_result = signed_operand_0 >= signed_operand_1;
            TIA_OP_SLE: signed_result = signed_operand_0 <= signed_operand_1;

            // Default value.
            default: signed_result = 0;
        endcase
    end

    // Generate unsigned results.
    always_comb begin
        unique case (op)
            // Core integer ISA.
            TIA_OP_NOP: unsigned_result = 0;
            TIA_OP_MOV: unsigned_result = unsigned_operand_0;
            TIA_OP_ADD: unsigned_result = unsigned_operand_0 + unsigned_operand_1;
            TIA_OP_SUB: unsigned_result = unsigned_operand_0 - unsigned_operand_1;
            TIA_OP_SL: unsigned_result = unsigned_operand_0 << unsigned_operand_1;
            TIA_OP_LSR: unsigned_result = unsigned_operand_0 >> unsigned_operand_1;
            TIA_OP_EQ: unsigned_result = unsigned_operand_0 == unsigned_operand_1;
            TIA_OP_NE: unsigned_result = unsigned_operand_0 != unsigned_operand_1;
            TIA_OP_UGT: unsigned_result = unsigned_operand_0 > unsigned_operand_1;
            TIA_OP_ULT: unsigned_result = unsigned_operand_0 < unsigned_operand_1;
            TIA_OP_UGE: unsigned_result = unsigned_operand_0 >= unsigned_operand_1;
            TIA_OP_ULE: unsigned_result = unsigned_operand_0 <= unsigned_operand_1;
            TIA_OP_BAND: unsigned_result = unsigned_operand_0 & unsigned_operand_1;
            TIA_OP_BNAND: unsigned_result = ~(unsigned_operand_0 & unsigned_operand_1);
            TIA_OP_BOR: unsigned_result = unsigned_operand_0 | unsigned_operand_1;
            TIA_OP_BNOR: unsigned_result = ~(unsigned_operand_0 | unsigned_operand_1);
            TIA_OP_BXOR: unsigned_result = unsigned_operand_0 ^ unsigned_operand_1;
            TIA_OP_BXNOR: unsigned_result = ~(unsigned_operand_0 ^ unsigned_operand_1);
            TIA_OP_LAND: unsigned_result = unsigned_operand_0 && unsigned_operand_1;
            TIA_OP_LNAND: unsigned_result = !(unsigned_operand_0 && unsigned_operand_1);
            TIA_OP_LOR: unsigned_result = unsigned_operand_0 || unsigned_operand_1;
            TIA_OP_LNOR: unsigned_result = !(unsigned_operand_0 || unsigned_operand_1);
            TIA_OP_LXOR: unsigned_result = !unsigned_operand_0 ^ !unsigned_operand_1;
            TIA_OP_LXNOR: unsigned_result = !(!unsigned_operand_0 ^ !unsigned_operand_1);
            TIA_OP_GB: unsigned_result = unsigned_operand_0[unsigned_operand_1[$clog2(TIA_WORD_WIDTH) - 1:0]];
            TIA_OP_SB: begin
                if (unsigned_operand_2)
                    unsigned_result = unsigned_operand_0 | (1 << unsigned_operand_1[$clog2(TIA_WORD_WIDTH) - 1:0]);
                else
                    unsigned_result = unsigned_operand_0 & ~(1 << unsigned_operand_1[$clog2(TIA_WORD_WIDTH) - 1:0]);
            end
            TIA_OP_CB: unsigned_result = unsigned_operand_0 & ~(1 << unsigned_operand_1[$clog2(TIA_WORD_WIDTH) - 1:0]);
            TIA_OP_MB: unsigned_result = unsigned_operand_0 | (1 << unsigned_operand_1[$clog2(TIA_WORD_WIDTH) - 1:0]);
            TIA_OP_CLZ: begin
                candidate_index_clz = TIA_WORD_WIDTH;
                for (i = TIA_WORD_WIDTH - 1; i >= 0; i--) begin
                    if (unsigned_operand_0[i] == 1) begin
                        candidate_index_clz = i;
                        break;
                    end
                end
                if (unsigned_operand_1) begin
                    if (candidate_index_clz == TIA_WORD_WIDTH)
                        unsigned_result = {TIA_WORD_WIDTH{1'b1}};
                    else
                        unsigned_result = i;
                end else begin
                    if (candidate_index_clz == TIA_WORD_WIDTH)
                        unsigned_result = {TIA_WORD_WIDTH{1'b1}};
                    else
                        unsigned_result = TIA_WORD_WIDTH - 1 - i;
                end
            end
            TIA_OP_CTZ: begin
                candidate_index_ctz = TIA_WORD_WIDTH;
                for (j = 0; j < TIA_WORD_WIDTH; j++) begin
                    if (unsigned_operand_0[j] == 1) begin
                        candidate_index_ctz = j;
                        break;
                    end
                end
                if (candidate_index_ctz == TIA_WORD_WIDTH)
                    unsigned_result = {TIA_WORD_WIDTH{1'b1}};
                else
                    unsigned_result = j;
            end
            TIA_OP_HALT: unsigned_result = 0;

            // Default value.
            default: unsigned_result = 0;
        endcase
    end

    // Forward the signed or unsigned result.
    always_comb begin
        unique case (op)
            // Core integer ISA.
            TIA_OP_ASR, TIA_OP_SGT, TIA_OP_SLT, TIA_OP_SGE, TIA_OP_SLE:
                result = signed_result;
            TIA_OP_NOP, TIA_OP_MOV, TIA_OP_ADD, TIA_OP_SUB, TIA_OP_SL, TIA_OP_LSR, TIA_OP_EQ, TIA_OP_NE,
            TIA_OP_UGT, TIA_OP_ULT, TIA_OP_UGE, TIA_OP_ULE, TIA_OP_BAND, TIA_OP_BNAND, TIA_OP_BOR,
            TIA_OP_BNOR, TIA_OP_BXOR, TIA_OP_BXNOR, TIA_OP_LAND, TIA_OP_LNAND, TIA_OP_LOR, TIA_OP_LNOR,
            TIA_OP_LXOR, TIA_OP_LXNOR, TIA_OP_GB, TIA_OP_SB, TIA_OP_CB, TIA_OP_MB,
            TIA_OP_CLZ, TIA_OP_CTZ, TIA_OP_HALT:
                result = unsigned_result;

            // Default value.
            default: result = 0;
        endcase
    end
endmodule
