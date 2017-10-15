/*
 * Instruction memory which looks up all instruction fields for an instruction at a given index
 * with zero latency.
 */

`include "instruction.svh"

module instruction_memory
    (input logic clock, // Positive-edge triggered.
     input logic enable, // Active high.
     mmio_if.device host_interface,
     output trigger_t triggers[TIA_MAX_NUM_INSTRUCTIONS - 1:0],
     input logic triggered_instruction_valid,
     input logic [TIA_INSTRUCTION_INDEX_WIDTH - 1:0] triggered_instruction_index,
     output datapath_instruction_t triggered_datapath_instruction);

    // --- Internal Logic and Wiring ---

    // Not synthesized.
    integer i;

    // Storage for the memory mapped instructions.
    mm_instruction_t mm_instructions [TIA_MAX_NUM_INSTRUCTIONS - 1:0];

    // Indexes into the instruction array.
    logic [TIA_INSTRUCTION_INDEX_WIDTH - 1:0] instruction_write_index;
    logic [$clog2(TIA_MM_INSTRUCTION_WIDTH / TIA_MMIO_DATA_WIDTH) - 1:0] word_write_index;

    // --- Combinational Logic ---

    // Expose relevant portions of the memory-mapped instructions as triggers.
    always_comb begin
        for (i = 0; i < TIA_MAX_NUM_INSTRUCTIONS; i++) begin
            triggers[i].vi = mm_instructions[i].vi;
            triggers[i].ptm = mm_instructions[i].ptm;
            triggers[i].ici = mm_instructions[i].ici;
            triggers[i].ictb = mm_instructions[i].ictb;
            triggers[i].ictv = mm_instructions[i].ictv;
            triggers[i].oci = mm_instructions[i].oci;
        end
    end

    // Figure out which instruction we are writing to.
    assign instruction_write_index
        =  host_interface.write_index >> $clog2(TIA_MM_INSTRUCTION_WIDTH / TIA_MMIO_DATA_WIDTH);
    assign word_write_index
        = host_interface.write_index[$clog2(TIA_MM_INSTRUCTION_WIDTH / TIA_MMIO_DATA_WIDTH) - 1:0];

    // Read data is always null (instruction memory is write only).
    assign host_interface.read_data = 0;
    assign host_interface.read_ack = host_interface.read_req;

    // Writes to instruction memory have no latency.
    assign host_interface.write_ack = host_interface.write_req;

    // Expose the selected triggered datapath instruction, if valid.
    always_comb begin
        if (triggered_instruction_valid) begin
            triggered_datapath_instruction.vi = 1; // We already know it is valid.
            triggered_datapath_instruction.op = mm_instructions[triggered_instruction_index].op;
            triggered_datapath_instruction.st = mm_instructions[triggered_instruction_index].st;
            triggered_datapath_instruction.si = mm_instructions[triggered_instruction_index].si;
            triggered_datapath_instruction.dt = mm_instructions[triggered_instruction_index].dt;
            triggered_datapath_instruction.di = mm_instructions[triggered_instruction_index].di;
            triggered_datapath_instruction.oci = mm_instructions[triggered_instruction_index].oci;
            triggered_datapath_instruction.oct = mm_instructions[triggered_instruction_index].oct;
            triggered_datapath_instruction.icd = mm_instructions[triggered_instruction_index].icd;
            triggered_datapath_instruction.pum = mm_instructions[triggered_instruction_index].pum;
            if (TIA_IMMEDIATE_WIDTH < TIA_WORD_WIDTH) begin
                // Extend the immediate sign.
                triggered_datapath_instruction.immediate = {{(TIA_WORD_WIDTH - TIA_IMMEDIATE_WIDTH)
                                                             {mm_instructions[triggered_instruction_index].immediate[TIA_IMMEDIATE_WIDTH + 1]}},
                                                            mm_instructions[triggered_instruction_index].immediate};
            end else
                // Immediate width and word width already match.
                triggered_datapath_instruction.immediate = mm_instructions[triggered_instruction_index].immediate;
        end else
            triggered_datapath_instruction = 0;
    end

    // --- Sequential Logic ---

    // Write to memory using the host interface.
    always_ff @(posedge clock) begin
        if (enable && host_interface.write_req) begin
            mm_instructions[instruction_write_index][TIA_MMIO_DATA_WIDTH * word_write_index+:TIA_MMIO_DATA_WIDTH]
                = host_interface.write_data; // Non-blocking syntax due to ModelSim.
        end
    end
endmodule
