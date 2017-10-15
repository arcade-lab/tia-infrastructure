/*
 * Responsible for feeding the operands of the ALU with sources based on the current instruction.
 */

`include "datapath.svh"

module source_fetching_unit
    (input logic [TIA_ST_WIDTH - 1:0] st,
     input logic [TIA_SI_WIDTH - 1:0] si,
     input logic [TIA_IMMEDIATE_WIDTH - 1:0] immediate,
     input logic [TIA_WORD_WIDTH - 1:0] input_channel_data [TIA_NUM_INPUT_CHANNELS - 1:0],
     output logic [TIA_REGISTER_INDEX_WIDTH - 1:0] register_read_index_0,
     output logic [TIA_REGISTER_INDEX_WIDTH - 1:0] register_read_index_1,
     output logic [TIA_REGISTER_INDEX_WIDTH - 1:0] register_read_index_2,
     input logic [TIA_WORD_WIDTH - 1:0] register_read_data_0,
     input logic [TIA_WORD_WIDTH - 1:0] register_read_data_1,
     input logic [TIA_WORD_WIDTH - 1:0] register_read_data_2,
     output logic [TIA_WORD_WIDTH - 1:0] operand_0,
     output logic [TIA_WORD_WIDTH - 1:0] operand_1,
     output logic [TIA_WORD_WIDTH - 1:0] operand_2);

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

    // Assign a value to the first operand.
    always_comb begin
        unique case (st_0)
            TIA_SOURCE_TYPE_NULL: begin
                register_read_index_0 = 0;
                operand_0 = 0;
            end
            TIA_SOURCE_TYPE_IMMEDIATE: begin
                register_read_index_0 = 0;
                operand_0 = immediate;
            end
            TIA_SOURCE_TYPE_CHANNEL: begin
                register_read_index_0 = 0;
                operand_0 = input_channel_data[si_0];
            end
            TIA_SOURCE_TYPE_REGISTER: begin
                register_read_index_0 = si_0;
                operand_0 = register_read_data_0;
            end
            default: begin
                register_read_index_0 = 0;
                operand_0 = 0;
            end
        endcase
    end

    // Assign a value to the second operand.
    always_comb begin
        unique case (st_1)
            TIA_SOURCE_TYPE_NULL: begin
                register_read_index_1 = 0;
                operand_1 = 0;
            end
            TIA_SOURCE_TYPE_IMMEDIATE: begin
                register_read_index_1 = 0;
                operand_1 = immediate;
            end
            TIA_SOURCE_TYPE_CHANNEL: begin
                register_read_index_1 = 0;
                operand_1 = input_channel_data[si_1];
            end
            TIA_SOURCE_TYPE_REGISTER: begin
                register_read_index_1 = si_1;
                operand_1 = register_read_data_1;
            end
            default: begin
                register_read_index_1 = 0;
                operand_1 = 0;
            end
        endcase
    end

    // Assign a value to the third operand.
    always_comb begin
        unique case (st_2)
            TIA_SOURCE_TYPE_NULL: begin
                register_read_index_2 = 0;
                operand_2 = 0;
            end
            TIA_SOURCE_TYPE_IMMEDIATE: begin
                register_read_index_2 = 0;
                operand_2 = immediate;
            end
            TIA_SOURCE_TYPE_CHANNEL: begin
                register_read_index_2 = 0;
                operand_2 = input_channel_data[si_2];
            end
            TIA_SOURCE_TYPE_REGISTER: begin
                register_read_index_2 = si_2;
                operand_2 = register_read_data_2;
            end
            default: begin
                register_read_index_2 = 0;
                operand_2 = 0;
            end
        endcase
    end
endmodule
