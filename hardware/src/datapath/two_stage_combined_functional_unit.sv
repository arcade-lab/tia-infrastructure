/*
 * Two-stage combined functional unit.
 */

`include "datapath.svh"

// TODO: make more synthesis friendly for retiming.

module two_stage_combined_functional_unit
    (input logic clock, // Postive-edge triggered.
     input logic reset, // Active high.
     input logic enable, // Active high.
     input logic [TIA_OP_WIDTH - 1:0] op,
     input logic [TIA_WORD_WIDTH - 1:0] operand_0,
     input logic [TIA_WORD_WIDTH - 1:0] operand_1,
     input logic [TIA_WORD_WIDTH - 1:0] operand_2,
     output logic [TIA_WORD_WIDTH - 1:0] result);

    // --- Internal Logic and Wiring ---

    // Signed and unsigned operands.
    logic signed [TIA_WORD_WIDTH - 1:0] signed_operand_0, signed_operand_1, signed_operand_2;
    logic [TIA_WORD_WIDTH - 1:0] unsigned_operand_0, unsigned_operand_1, unsigned_operand_2;

    // Factors.
    logic signed [TIA_WORD_WIDTH - 1:0] signed_factor_0, signed_factor_1;
    logic [TIA_WORD_WIDTH - 1:0] unsigned_factor_0, unsigned_factor_1;

    // Signed and unsigned results.
    logic signed [TIA_WORD_WIDTH - 1:0] signed_result;
    logic [TIA_WORD_WIDTH - 1:0] unsigned_result;

    // Products.
    logic signed [2 * TIA_WORD_WIDTH - 1:0] signed_product;
    logic [2 * TIA_WORD_WIDTH - 1:0] unsigned_product;

    // Bit indices and candidate indices for clz and ctz.
    integer i, j, candidate_index_clz, candidate_index_ctz;

    // First-stage result.
    logic [TIA_WORD_WIDTH - 1:0] first_stage_result;

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

    // Assign factors and perform the multiplication.
    always_comb begin
        unique case (op)
            TIA_OP_SHMUL: begin
                signed_factor_0 = signed_operand_0;
                signed_factor_1 = signed_operand_1;
                unsigned_factor_0 = 0;
                unsigned_factor_1 = 0;
            end
            TIA_OP_LMUL, TIA_OP_UHMUL: begin
                signed_factor_0 = 0;
                signed_factor_1 = 0;
                unsigned_factor_0 = unsigned_operand_0;
                unsigned_factor_1 = unsigned_operand_1;
            end
            TIA_OP_MAC: begin
                signed_factor_0 = operand_1;
                signed_factor_1 = operand_2;
                unsigned_factor_0 = 0;
                unsigned_factor_1 = 0;
            end
            default: begin
                signed_factor_0 = 0;
                signed_factor_1 = 0;
                unsigned_factor_0 = 0;
                unsigned_factor_1 = 0;
            end
        endcase
        signed_product = signed_factor_0 * signed_factor_1;
        unsigned_product = unsigned_factor_0 * unsigned_factor_1;
    end

    // Forward the result.
    always_comb begin
        unique case (op)
            // Core integer ISA.
            TIA_OP_ASR, TIA_OP_SGT, TIA_OP_SLT, TIA_OP_SGE, TIA_OP_SLE:
                first_stage_result = signed_result;
            TIA_OP_NOP, TIA_OP_MOV, TIA_OP_ADD, TIA_OP_SUB, TIA_OP_SL, TIA_OP_LSR, TIA_OP_EQ, TIA_OP_NE,
            TIA_OP_UGT, TIA_OP_ULT, TIA_OP_UGE, TIA_OP_ULE, TIA_OP_BAND, TIA_OP_BNAND, TIA_OP_BOR,
            TIA_OP_BNOR, TIA_OP_BXOR, TIA_OP_BXNOR, TIA_OP_LAND, TIA_OP_LNAND, TIA_OP_LOR, TIA_OP_LNOR,
            TIA_OP_LXOR, TIA_OP_LXNOR, TIA_OP_GB, TIA_OP_SB, TIA_OP_CB, TIA_OP_MB,
            TIA_OP_CLZ, TIA_OP_CTZ, TIA_OP_HALT:
                first_stage_result = unsigned_result;

            // Multiplication.
            TIA_OP_LMUL: first_stage_result = unsigned_product[TIA_WORD_WIDTH - 1:0];
            `ifdef TIA_HAS_TWO_WORD_PRODUCT_MULTIPLIER
                TIA_OP_SHMUL: first_stage_result = signed_product[2 * TIA_WORD_WIDTH - 1:TIA_WORD_WIDTH];
                TIA_OP_UHMUL: first_stage_result = unsigned_product[2 * TIA_WORD_WIDTH - 1:TIA_WORD_WIDTH];
            `endif
            TIA_OP_MAC: first_stage_result = signed_operand_0 + signed_product[TIA_WORD_WIDTH - 1:0];

            // Default value.
            default: first_stage_result = 0;
        endcase
    end

    // Rely on register retiming for effective arithmetic pipelining.
    always_ff @(posedge clock) begin
        if (reset)
            result <= 0;
        else if (enable)
            result <= first_stage_result;
    end
endmodule
