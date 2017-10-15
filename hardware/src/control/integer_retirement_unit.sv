/*
 * A module for determining the datapath result and which instruction is retiring in a given cycle
 * as an input to the destination routing unit.
 */

`include "control.svh"

module integer_retirement_unit
    (input logic [2:0] dx1_instruction_retiring_stage,
     input functional_unit_t dx1_functional_unit,
     input logic [2:0] x2_instruction_retiring_stage,
     input functional_unit_t x2_functional_unit,
     input datapath_instruction_t dx1_datapath_instruction,
     input datapath_instruction_t x2_datapath_instruction,
     input logic [TIA_WORD_WIDTH - 1:0] alu_result,
     input logic [TIA_WORD_WIDTH - 1:0] sm_result,
     input logic [TIA_WORD_WIDTH - 1:0] imu_result,
     output datapath_instruction_t retiring_datapath_instruction,
     output logic [TIA_WORD_WIDTH - 1:0] datapath_result);

    // --- Combinational Logic ---

    // Multiplex between instructions and functional unit results.
    always_comb begin
        if (x2_instruction_retiring_stage == 2) begin
            retiring_datapath_instruction = x2_datapath_instruction;
            unique case (x2_functional_unit)
                SM:
                    datapath_result = sm_result;
                IMU:
                    datapath_result = imu_result;
                // Note: more cases to come which will make the case statement less trivial.
                default:
                    datapath_result = alu_result;
            endcase
        end else if (dx1_instruction_retiring_stage == 1) begin
            retiring_datapath_instruction = dx1_datapath_instruction;
            // Note: more cases to come which will make the case statement less trivial.
            datapath_result = alu_result;
        end else begin
            retiring_datapath_instruction = 0;
            datapath_result = alu_result;
        end
    end
endmodule
