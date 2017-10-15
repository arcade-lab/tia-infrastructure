/*
 * System memory mapper.
 */

`ifdef ASIC_SYNTHESIS
    `include "memory.svh"
    `include "mmio.svh"
`elsif FPGA_SYNTHESIS
    `include "memory.svh"
    `include "mmio.svh"
`elsif SIMULATION
    `include "../memory/memory.svh"
    `include "mmio.svh"
`else
    `include "memory.svh"
    `include "mmio.svh"
`endif

module quartet_test_system_mapper
    (mmio_if.device host_interface,
     mmio_if.host control_interface,
     mmio_if.host quartet_interface,
     mmio_if.host memory_interface);

    // --- Local Parameters ---

    // Memory map.
    localparam TIA_CONTROL_BASE_INDEX = 268435456; // 0x40000000 / [bytes / word] (byte -> word addressing).
    localparam TIA_CONTROL_BOUND_INDEX = TIA_CONTROL_BASE_INDEX + TIA_NUM_SYSTEM_CONTROL_REGISTERS;
    localparam TIA_QUARTET_BASE_INDEX = TIA_CONTROL_BOUND_INDEX;
    localparam TIA_QUARTET_BOUND_INDEX = TIA_QUARTET_BASE_INDEX
                                         + 4 * (TIA_NUM_CORE_MONITOR_WORDS
                                                + TIA_NUM_CORE_PERFORMANCE_COUNTERS
                                                + TIA_MAX_NUM_INSTRUCTIONS
                                                   * TIA_MM_INSTRUCTION_WIDTH
                                                   / TIA_WORD_WIDTH
                                                + TIA_NUM_SCRATCHPAD_WORDS);
    localparam TIA_MEMORY_BASE_INDEX = TIA_QUARTET_BOUND_INDEX;
    localparam TIA_MEMORY_BOUND_INDEX = TIA_MEMORY_BASE_INDEX + TIA_NUM_DATA_MEMORY_WORDS;

    // --- Combinational Logic ---

    // Map reads.
    always_comb begin
        if (host_interface.read_req) begin
            if (host_interface.read_index >= TIA_CONTROL_BASE_INDEX
                && host_interface.read_index < TIA_CONTROL_BOUND_INDEX) begin
                control_interface.read_req = host_interface.read_req;
                control_interface.read_index = host_interface.read_index
                                               - TIA_CONTROL_BASE_INDEX;
                host_interface.read_ack = control_interface.read_ack;
                host_interface.read_data = control_interface.read_data;
                quartet_interface.read_req = 0;
                quartet_interface.read_index = 0;
                memory_interface.read_req = 0;
                memory_interface.read_index = 0;
            end else if (host_interface.read_index >= TIA_QUARTET_BASE_INDEX
                         && host_interface.read_index < TIA_QUARTET_BOUND_INDEX) begin
                control_interface.read_req = 0;
                control_interface.read_index = 0;
                quartet_interface.read_req = host_interface.read_req;
                quartet_interface.read_index = host_interface.read_index
                                                          - TIA_QUARTET_BASE_INDEX;
                host_interface.read_ack = quartet_interface.read_ack;
                host_interface.read_data = quartet_interface.read_data;
                memory_interface.read_req = 0;
                memory_interface.read_index = 0;
            end else if (host_interface.read_index >= TIA_MEMORY_BASE_INDEX
                         && host_interface.read_index < TIA_MEMORY_BOUND_INDEX) begin
                control_interface.read_req = 0;
                control_interface.read_index = 0;
                quartet_interface.read_req = 0;
                quartet_interface.read_index = 0;
                memory_interface.read_req = host_interface.read_req;
                memory_interface.read_index = host_interface.read_index - TIA_MEMORY_BASE_INDEX;
                host_interface.read_ack = memory_interface.read_ack;
                host_interface.read_data = memory_interface.read_data;
            end else begin
                host_interface.read_ack = 0;
                host_interface.read_data = 0;
                control_interface.read_req = 0;
                control_interface.read_index = 0;
                quartet_interface.read_req = 0;
                quartet_interface.read_index = 0;
                memory_interface.read_req = 0;
                memory_interface.read_index = 0;
            end
        end else begin
            host_interface.read_ack = 0;
            host_interface.read_data = 0;
            control_interface.read_req = 0;
            control_interface.read_index = 0;
            quartet_interface.read_req = 0;
            quartet_interface.read_index = 0;
            memory_interface.read_req = 0;
            memory_interface.read_index = 0;
        end
    end

    // Map writes.
    always_comb begin
        if (host_interface.write_req) begin
            if (host_interface.write_index >= TIA_CONTROL_BASE_INDEX
                && host_interface.write_index < TIA_CONTROL_BOUND_INDEX) begin
                control_interface.write_req = host_interface.write_req;
                control_interface.write_index = host_interface.write_index
                                                - TIA_CONTROL_BASE_INDEX;
                control_interface.write_data = host_interface.write_data;
                host_interface.write_ack = control_interface.write_ack;
                quartet_interface.write_req = 0;
                quartet_interface.write_index = 0;
                quartet_interface.write_data = 0;
                memory_interface.write_req = 0;
                memory_interface.write_index = 0;
                memory_interface.write_data = 0;
            end else if (host_interface.write_index >= TIA_QUARTET_BASE_INDEX
                         && host_interface.write_index < TIA_QUARTET_BOUND_INDEX) begin
                control_interface.write_req = 0;
                control_interface.write_index = 0;
                control_interface.write_data = 0;
                quartet_interface.write_req = host_interface.write_req;
                quartet_interface.write_index = host_interface.write_index
                                                           - TIA_QUARTET_BASE_INDEX;
                quartet_interface.write_data = host_interface.write_data;
                host_interface.write_ack = quartet_interface.write_ack;
                memory_interface.write_req = 0;
                memory_interface.write_index = 0;
                memory_interface.write_data = 0;
            end else if (host_interface.write_index >= TIA_MEMORY_BASE_INDEX
                         && host_interface.write_index < TIA_MEMORY_BOUND_INDEX) begin
                control_interface.write_req = 0;
                control_interface.write_index = 0;
                control_interface.write_data = 0;
                quartet_interface.write_req = 0;
                quartet_interface.write_index = 0;
                quartet_interface.write_data = 0;
                memory_interface.write_req = host_interface.write_req;
                memory_interface.write_index = host_interface.write_index - TIA_MEMORY_BASE_INDEX;
                memory_interface.write_data = host_interface.write_data;
                host_interface.write_ack = memory_interface.write_ack;
            end else begin
                host_interface.write_ack = 0;
                control_interface.write_req = 0;
                control_interface.write_index = 0;
                control_interface.write_data = 0;
                quartet_interface.write_req = 0;
                quartet_interface.write_index = 0;
                quartet_interface.write_data = 0;
                memory_interface.write_req = 0;
                memory_interface.write_index = 0;
                memory_interface.write_data = 0;
            end
        end else begin
            host_interface.write_ack = 0;
            control_interface.write_req = 0;
            control_interface.write_index = 0;
            control_interface.write_data = 0;
            quartet_interface.write_req = 0;
            quartet_interface.write_index = 0;
            quartet_interface.write_data = 0;
            memory_interface.write_req = 0;
            memory_interface.write_index = 0;
            memory_interface.write_data = 0;
        end
    end
endmodule
