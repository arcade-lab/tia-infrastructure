/*
 * Responsible for forwarding operands from ALU output to the TR/EX pipeline register.
 */

`include "datapath.svh"

module operand_forwarding_unit
    (input logic enable,
     input logic [TIA_ST_WIDTH - 1:0] st,
     input logic [TIA_SI_WIDTH - 1:0] si,
     input logic [TIA_DT_WIDTH - 1:0] downstream_dt,
     input logic [TIA_DI_WIDTH - 1:0] downstream_di,
     input logic [TIA_WORD_WIDTH - 1:0] downstream_result,
     input logic [TIA_WORD_WIDTH - 1:0] pre_ofu_operand_0,
     input logic [TIA_WORD_WIDTH - 1:0] pre_ofu_operand_1,
     input logic [TIA_WORD_WIDTH - 1:0] pre_ofu_operand_2,
     output logic [TIA_WORD_WIDTH - 1:0] post_ofu_operand_0,
     output logic [TIA_WORD_WIDTH - 1:0] post_ofu_operand_1,
     output logic [TIA_WORD_WIDTH - 1:0] post_ofu_operand_2);

    // --- Internal Logic and Wiring ---

    // Individual source types and indices.
    logic [TIA_SINGLE_ST_WIDTH - 1:0] st_0, st_1, st_2;
    logic [TIA_SINGLE_SI_WIDTH - 1:0] si_0, si_1, si_2;

    // --- Combinational Logic ---

    // Generate source types for each operand.
    assign st_0 = st[TIA_SINGLE_ST_WIDTH - 1:0];
    assign st_1 = st[2 * TIA_SINGLE_ST_WIDTH - 1:TIA_SINGLE_ST_WIDTH];
    assign st_2 = st[TIA_ST_WIDTH - 1:2 * TIA_SINGLE_ST_WIDTH];

    // Generate source indices for each operand.
    assign si_0 = si[TIA_SINGLE_SI_WIDTH - 1:0];
    assign si_1 = si[2 * TIA_SINGLE_SI_WIDTH - 1:TIA_SINGLE_SI_WIDTH];
    assign si_2 = si[TIA_SI_WIDTH - 1:2 * TIA_SINGLE_SI_WIDTH];

    // Handle forwarding to the first operand.
    always_comb begin
        if (enable) begin
            if (st_0 == TIA_SOURCE_TYPE_REGISTER
                && downstream_dt == TIA_DESTINATION_TYPE_REGISTER
                && si_0 == downstream_di)
                post_ofu_operand_0 = downstream_result;
            else
                post_ofu_operand_0 = pre_ofu_operand_0;
        end else
            post_ofu_operand_0 = pre_ofu_operand_0;
    end

    // Handle forwarding to the second operand.
    always_comb begin
        if (enable) begin
            if (st_1 == TIA_SOURCE_TYPE_REGISTER
                && downstream_dt == TIA_DESTINATION_TYPE_REGISTER
                && si_1 == downstream_di)
                post_ofu_operand_1 = downstream_result;
            else
                post_ofu_operand_1 = pre_ofu_operand_1;
        end else
            post_ofu_operand_1 = pre_ofu_operand_1;
    end

    // Handle forwarding to the third operand.
    always_comb begin
        if (enable) begin
            if (st_2 == TIA_SOURCE_TYPE_REGISTER
                && downstream_dt == TIA_DESTINATION_TYPE_REGISTER
                && si_2 == downstream_di)
                post_ofu_operand_2 = downstream_result;
            else
                post_ofu_operand_2 = pre_ofu_operand_2;
        end else
            post_ofu_operand_2 = pre_ofu_operand_2;
    end
endmodule
