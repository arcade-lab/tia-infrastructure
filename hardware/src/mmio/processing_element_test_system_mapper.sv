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

module processing_element_test_system_mapper
    (mmio_if.device host_interface,
     mmio_if.host control_interface,
     mmio_if.host processing_element_interface,
     mmio_if.host memory_interface);

    // --- Local Parameters ---

    // Memory map.
    localparam CONTROL_BASE_INDEX = 268435456; // 0x40000000 / [bytes / word] (byte -> word addressing).
    localparam CONTROL_BOUND_INDEX = CONTROL_BASE_INDEX + TIA_NUM_SYSTEM_CONTROL_REGISTERS;
    localparam PROCESSING_ELEMENT_BASE_INDEX = CONTROL_BOUND_INDEX;
    localparam PROCESSING_ELEMENT_BOUND_INDEX = PROCESSING_ELEMENT_BASE_INDEX
                                                + TIA_NUM_PROCESSING_ELEMENT_ADDRESS_SPACE_WORDS;
    localparam MEMORY_BASE_INDEX = PROCESSING_ELEMENT_BOUND_INDEX;
    localparam MEMORY_BOUND_INDEX = MEMORY_BASE_INDEX + TIA_NUM_DATA_MEMORY_WORDS;

    // --- Combinational Logic ---

    // Map reads.
    always_comb begin
        if (host_interface.read_req) begin
            if (host_interface.read_index >= CONTROL_BASE_INDEX
                && host_interface.read_index < CONTROL_BOUND_INDEX) begin
                control_interface.read_req = host_interface.read_req;
                control_interface.read_index = host_interface.read_index
                                               - CONTROL_BASE_INDEX;
                host_interface.read_ack = control_interface.read_ack;
                host_interface.read_data = control_interface.read_data;
                processing_element_interface.read_req = 0;
                processing_element_interface.read_index = 0;
                memory_interface.read_req = 0;
                memory_interface.read_index = 0;
            end else if (host_interface.read_index >= PROCESSING_ELEMENT_BASE_INDEX
                         && host_interface.read_index < PROCESSING_ELEMENT_BOUND_INDEX) begin
                control_interface.read_req = 0;
                control_interface.read_index = 0;
                processing_element_interface.read_req = host_interface.read_req;
                processing_element_interface.read_index = host_interface.read_index
                                                          - PROCESSING_ELEMENT_BASE_INDEX;
                host_interface.read_ack = processing_element_interface.read_ack;
                host_interface.read_data = processing_element_interface.read_data;
                memory_interface.read_req = 0;
                memory_interface.read_index = 0;
            end else if (host_interface.read_index >= MEMORY_BASE_INDEX
                         && host_interface.read_index < MEMORY_BOUND_INDEX) begin
                control_interface.read_req = 0;
                control_interface.read_index = 0;
                processing_element_interface.read_req = 0;
                processing_element_interface.read_index = 0;
                memory_interface.read_req = host_interface.read_req;
                memory_interface.read_index = host_interface.read_index - MEMORY_BASE_INDEX;
                host_interface.read_ack = memory_interface.read_ack;
                host_interface.read_data = memory_interface.read_data;
            end else begin
                host_interface.read_ack = 0;
                host_interface.read_data = 0;
                control_interface.read_req = 0;
                control_interface.read_index = 0;
                processing_element_interface.read_req = 0;
                processing_element_interface.read_index = 0;
                memory_interface.read_req = 0;
                memory_interface.read_index = 0;
            end
        end else begin
            host_interface.read_ack = 0;
            host_interface.read_data = 0;
            control_interface.read_req = 0;
            control_interface.read_index = 0;
            processing_element_interface.read_req = 0;
            processing_element_interface.read_index = 0;
            memory_interface.read_req = 0;
            memory_interface.read_index = 0;
        end
    end

    // Map writes.
    always_comb begin
        if (host_interface.write_req) begin
            if (host_interface.write_index >= CONTROL_BASE_INDEX
                && host_interface.write_index < CONTROL_BOUND_INDEX) begin
                control_interface.write_req = host_interface.write_req;
                control_interface.write_index = host_interface.write_index
                                                - CONTROL_BASE_INDEX;
                control_interface.write_data = host_interface.write_data;
                host_interface.write_ack = control_interface.write_ack;
                processing_element_interface.write_req = 0;
                processing_element_interface.write_index = 0;
                processing_element_interface.write_data = 0;
                memory_interface.write_req = 0;
                memory_interface.write_index = 0;
                memory_interface.write_data = 0;
            end else if (host_interface.write_index >= PROCESSING_ELEMENT_BASE_INDEX
                         && host_interface.write_index < PROCESSING_ELEMENT_BOUND_INDEX) begin
                control_interface.write_req = 0;
                control_interface.write_index = 0;
                control_interface.write_data = 0;
                processing_element_interface.write_req = host_interface.write_req;
                processing_element_interface.write_index = host_interface.write_index
                                                           - PROCESSING_ELEMENT_BASE_INDEX;
                processing_element_interface.write_data = host_interface.write_data;
                host_interface.write_ack = processing_element_interface.write_ack;
                memory_interface.write_req = 0;
                memory_interface.write_index = 0;
                memory_interface.write_data = 0;
            end else if (host_interface.write_index >= MEMORY_BASE_INDEX
                         && host_interface.write_index < MEMORY_BOUND_INDEX) begin
                control_interface.write_req = 0;
                control_interface.write_index = 0;
                control_interface.write_data = 0;
                processing_element_interface.write_req = 0;
                processing_element_interface.write_index = 0;
                processing_element_interface.write_data = 0;
                memory_interface.write_req = host_interface.write_req;
                memory_interface.write_index = host_interface.write_index - MEMORY_BASE_INDEX;
                memory_interface.write_data = host_interface.write_data;
                host_interface.write_ack = memory_interface.write_ack;
            end else begin
                host_interface.write_ack = 0;
                control_interface.write_req = 0;
                control_interface.write_index = 0;
                control_interface.write_data = 0;
                processing_element_interface.write_req = 0;
                processing_element_interface.write_index = 0;
                processing_element_interface.write_data = 0;
                memory_interface.write_req = 0;
                memory_interface.write_index = 0;
                memory_interface.write_data = 0;
            end
        end else begin
            host_interface.write_ack = 0;
            control_interface.write_req = 0;
            control_interface.write_index = 0;
            control_interface.write_data = 0;
            processing_element_interface.write_req = 0;
            processing_element_interface.write_index = 0;
            processing_element_interface.write_data = 0;
            memory_interface.write_req = 0;
            memory_interface.write_index = 0;
            memory_interface.write_data = 0;
        end
    end
endmodule
