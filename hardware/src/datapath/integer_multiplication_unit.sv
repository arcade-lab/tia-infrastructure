/*
 * Pipelined multiplier and eventually MAC.
 */

`include "datapath.svh"

module integer_multiplication_unit
    (input logic clock, // Positive-edge triggered.
     input logic reset, // Active high.
     input logic enable, // Active high.
     input logic [TIA_OP_WIDTH - 1:0] op,
     input logic [TIA_WORD_WIDTH - 1:0] operand_0,
     input logic [TIA_WORD_WIDTH - 1:0] operand_1,
     input logic [TIA_WORD_WIDTH - 1:0] operand_2,
     output logic [TIA_WORD_WIDTH - 1:0] result);

    // --- Internal Logic and Wiring --

    // Opcode pipeline register.
    logic [TIA_OP_WIDTH - 1:0] second_stage_op;
    logic signed [TIA_WORD_WIDTH - 1:0] second_stage_operand_0;

    // Operands.
    logic signed [TIA_WORD_WIDTH - 1:0] signed_operand_0, signed_operand_1, signed_operand_2;
    logic [TIA_WORD_WIDTH - 1:0] unsigned_operand_0, unsigned_operand_1, unsigned_operand_2;

    // Factors.
    logic signed [TIA_WORD_WIDTH - 1:0] signed_factor_0, signed_factor_1;
    logic [TIA_WORD_WIDTH - 1:0] unsigned_factor_0, unsigned_factor_1;

    // Products.
    logic signed [2 * TIA_WORD_WIDTH - 1:0] signed_product;
    logic [2 * TIA_WORD_WIDTH - 1:0] unsigned_product;

    // --- Combinational Logic ---

    // Get signed operands.
    assign signed_operand_0 = operand_0;
    assign signed_operand_1 = operand_1;
    assign signed_operand_2 = operand_2;
    assign unsigned_operand_0 = operand_0;
    assign unsigned_operand_1 = operand_1;
    assign unsigned_operand_2 = operand_2;

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
    end

    // Select the correct result.
    always_comb begin
        unique case (second_stage_op)
            TIA_OP_LMUL: result = unsigned_product[TIA_WORD_WIDTH - 1:0];
            `ifdef TIA_HAS_TWO_WORD_PRODUCT_MULTIPLIER
                TIA_OP_SHMUL: result = signed_product[2 * TIA_WORD_WIDTH - 1:TIA_WORD_WIDTH];
                TIA_OP_UHMUL: result = unsigned_product[2 * TIA_WORD_WIDTH - 1:TIA_WORD_WIDTH];
            `endif
            TIA_OP_MAC: result = second_stage_operand_0 + signed_product[TIA_WORD_WIDTH - 1:0];
            default: result = 0;
        endcase
    end

    // Pipeline the opcode and first operand.
    always_ff @(posedge clock) begin
        if (reset) begin
            second_stage_op <= 0;
            second_stage_operand_0 <= 0;
        end else if (enable) begin
            second_stage_op <= op;
            second_stage_operand_0 <= operand_0;
        end
    end

    // Pipeline the multiplication.
    always_ff @(posedge clock) begin
        signed_product <= signed_factor_0 * signed_factor_1;
        unsigned_product <= unsigned_factor_0 * unsigned_factor_1;
    end
endmodule
