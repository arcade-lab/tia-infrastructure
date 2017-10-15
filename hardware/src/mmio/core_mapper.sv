/*
 * Core memory mapper.
 */

`include "mmio.svh"

module core_mapper
    (mmio_if.device host_interface,
     mmio_if.host monitor_interface,
     mmio_if.host performance_counters_interface,
     mmio_if.host register_file_interface,
     mmio_if.host instruction_memory_interface,
     mmio_if.host scratchpad_memory_interface);

    // --- Combinational Logic ---

    // Map reads.
    always_comb begin
        if (host_interface.read_req) begin
            if (host_interface.read_index < TIA_CORE_MONITOR_BOUND_INDEX) begin
                monitor_interface.read_req = host_interface.read_req;
                monitor_interface.read_index = host_interface.read_index;
                host_interface.read_ack = monitor_interface.read_ack;
                host_interface.read_data = monitor_interface.read_data;
                performance_counters_interface.read_req = 0;
                performance_counters_interface.read_index = 0;
                register_file_interface.read_req = 0;
                register_file_interface.read_index = 0;
                instruction_memory_interface.read_req = 0;
                instruction_memory_interface.read_index = 0;
                scratchpad_memory_interface.read_req = 0;
                scratchpad_memory_interface.read_index = 0;
            end else if (host_interface.read_index >= TIA_CORE_PERFORMANCE_COUNTERS_BASE_INDEX
                         && host_interface.read_index < TIA_CORE_PERFORMANCE_COUNTERS_BOUND_INDEX) begin
                monitor_interface.read_req = 0;
                monitor_interface.read_index = 0;
                performance_counters_interface.read_req = host_interface.read_req;
                performance_counters_interface.read_index = host_interface.read_index
                                                            - TIA_CORE_PERFORMANCE_COUNTERS_BASE_INDEX;
                host_interface.read_ack = performance_counters_interface.read_ack;
                host_interface.read_data = performance_counters_interface.read_data;
                register_file_interface.read_req = 0;
                register_file_interface.read_index = 0;
                instruction_memory_interface.read_req = 0;
                instruction_memory_interface.read_index = 0;
                scratchpad_memory_interface.read_req = 0;
                scratchpad_memory_interface.read_index = 0;
            end else if (host_interface.read_index >= TIA_CORE_REGISTER_FILE_BASE_INDEX
                         && host_interface.read_index < TIA_CORE_REGISTER_FILE_BOUND_INDEX) begin
                monitor_interface.read_req = 0;
                monitor_interface.read_index = 0;
                performance_counters_interface.read_req = 0;
                performance_counters_interface.read_index = 0;
                register_file_interface.read_req = host_interface.read_req;
                register_file_interface.read_index = host_interface.read_index
                                                     - TIA_CORE_REGISTER_FILE_BASE_INDEX;
                host_interface.read_ack = register_file_interface.read_ack;
                host_interface.read_data = register_file_interface.read_data;
                instruction_memory_interface.read_req = 0;
                instruction_memory_interface.read_index = 0;
                scratchpad_memory_interface.read_req = 0;
                scratchpad_memory_interface.read_index = 0;
            end else if (host_interface.read_index >= TIA_CORE_INSTRUCTION_MEMORY_BASE_INDEX
                         && host_interface.read_index < TIA_CORE_INSTRUCTION_MEMORY_BOUND_INDEX) begin
                monitor_interface.read_req = 0;
                monitor_interface.read_index = 0;
                performance_counters_interface.read_req = 0;
                performance_counters_interface.read_index = 0;
                register_file_interface.read_req = 0;
                register_file_interface.read_index = 0;
                instruction_memory_interface.read_req = host_interface.read_req;
                instruction_memory_interface.read_index = host_interface.read_index
                                                          - TIA_CORE_INSTRUCTION_MEMORY_BASE_INDEX;
                host_interface.read_ack = instruction_memory_interface.read_ack;
                host_interface.read_data = instruction_memory_interface.read_data;
                scratchpad_memory_interface.read_req = 0;
                scratchpad_memory_interface.read_index = 0;
            end else if (host_interface.read_index >= TIA_CORE_SCRATCHPAD_MEMORY_BASE_INDEX
                         && host_interface.read_index < TIA_CORE_SCRATCHPAD_MEMORY_BOUND_INDEX) begin
                monitor_interface.read_req = 0;
                monitor_interface.read_index = 0;
                 performance_counters_interface.read_req = 0;
                performance_counters_interface.read_index = 0;
                register_file_interface.read_req = 0;
                register_file_interface.read_index = 0;
                instruction_memory_interface.read_req  = 0;
                instruction_memory_interface.read_index = 0;
                scratchpad_memory_interface.read_req = host_interface.read_req;
                scratchpad_memory_interface.read_index = host_interface.read_index
                                                         - TIA_CORE_SCRATCHPAD_MEMORY_BOUND_INDEX;
                host_interface.read_ack = scratchpad_memory_interface.read_ack;
                host_interface.read_data = scratchpad_memory_interface.read_data;
            end else begin
                host_interface.read_ack = 0;
                host_interface.read_data = 0;
                monitor_interface.read_req = 0;
                monitor_interface.read_index = 0;
                performance_counters_interface.read_req = 0;
                performance_counters_interface.read_index = 0;
                register_file_interface.read_req = 0;
                register_file_interface.read_index = 0;
                instruction_memory_interface.read_req = 0;
                instruction_memory_interface.read_index = 0;
                scratchpad_memory_interface.read_req = 0;
                scratchpad_memory_interface.read_index = 0;
            end
        end else begin
            host_interface.read_ack = 0;
            host_interface.read_data = 0;
            monitor_interface.read_req = 0;
            monitor_interface.read_index = 0;
            performance_counters_interface.read_req = 0;
            performance_counters_interface.read_index = 0;
            register_file_interface.read_req = 0;
            register_file_interface.read_index = 0;
            instruction_memory_interface.read_req = 0;
            instruction_memory_interface.read_index = 0;
            scratchpad_memory_interface.read_req = 0;
            scratchpad_memory_interface.read_index = 0;
        end
    end

    // Map writes.
    always_comb begin
        if (host_interface.write_req) begin
            if (host_interface.write_index < TIA_CORE_MONITOR_BOUND_INDEX) begin
                monitor_interface.write_req = host_interface.write_req;
                monitor_interface.write_index = host_interface.write_index;
                monitor_interface.write_data = host_interface.write_data;
                host_interface.write_ack = monitor_interface.write_ack;
                performance_counters_interface.write_req = 0;
                performance_counters_interface.write_index = 0;
                performance_counters_interface.write_data = 0;
                register_file_interface.write_req = 0;
                register_file_interface.write_index = 0;
                register_file_interface.write_data = 0;
                instruction_memory_interface.write_req = 0;
                instruction_memory_interface.write_index = 0;
                instruction_memory_interface.write_data = 0;
                scratchpad_memory_interface.write_req = 0;
                scratchpad_memory_interface.write_index = 0;
                scratchpad_memory_interface.write_data = 0;
            end else if (host_interface.write_index >= TIA_CORE_PERFORMANCE_COUNTERS_BASE_INDEX
                && host_interface.write_index < TIA_CORE_PERFORMANCE_COUNTERS_BOUND_INDEX) begin
                monitor_interface.write_req = 0;
                monitor_interface.write_index = 0;
                monitor_interface.write_data = 0;
                performance_counters_interface.write_req = host_interface.write_req;
                performance_counters_interface.write_index = host_interface.write_index
                                                             - TIA_CORE_PERFORMANCE_COUNTERS_BASE_INDEX;
                performance_counters_interface.write_data = host_interface.write_data;
                host_interface.write_ack = performance_counters_interface.write_ack;
                register_file_interface.write_req = 0;
                register_file_interface.write_index = 0;
                register_file_interface.write_data = 0;
                instruction_memory_interface.write_req = 0;
                instruction_memory_interface.write_index = 0;
                instruction_memory_interface.write_data = 0;
                scratchpad_memory_interface.write_req = 0;
                scratchpad_memory_interface.write_index = 0;
                scratchpad_memory_interface.write_data = 0;
            end else if (host_interface.write_index >= TIA_CORE_REGISTER_FILE_BASE_INDEX
                         && host_interface.write_index < TIA_CORE_REGISTER_FILE_BOUND_INDEX) begin
                monitor_interface.write_req = 0;
                monitor_interface.write_index = 0;
                monitor_interface.write_data = 0;
                performance_counters_interface.write_req = 0;
                performance_counters_interface.write_index = 0;
                performance_counters_interface.write_data = 0;
                register_file_interface.write_req = host_interface.write_req;
                register_file_interface.write_index = host_interface.write_index
                                                      - TIA_CORE_REGISTER_FILE_BASE_INDEX;
                register_file_interface.write_data = host_interface.write_data;
                host_interface.write_ack = register_file_interface.write_ack;
                instruction_memory_interface.write_req = 0;
                instruction_memory_interface.write_index = 0;
                instruction_memory_interface.write_data = 0;
                scratchpad_memory_interface.write_req = 0;
                scratchpad_memory_interface.write_index = 0;
                scratchpad_memory_interface.write_data = 0;
            end else if (host_interface.write_index >= TIA_CORE_INSTRUCTION_MEMORY_BASE_INDEX
                         && host_interface.write_index < TIA_CORE_INSTRUCTION_MEMORY_BOUND_INDEX) begin
                monitor_interface.write_req = 0;
                monitor_interface.write_index = 0;
                monitor_interface.write_data = 0;
                performance_counters_interface.write_req = 0;
                performance_counters_interface.write_index = 0;
                performance_counters_interface.write_data = 0;
                register_file_interface.write_req = 0;
                register_file_interface.write_index = 0;
                register_file_interface.write_data = 0;
                instruction_memory_interface.write_req = host_interface.write_req;
                instruction_memory_interface.write_index = host_interface.write_index
                                                           - TIA_CORE_INSTRUCTION_MEMORY_BASE_INDEX;
                instruction_memory_interface.write_data = host_interface.write_data;
                host_interface.write_ack = instruction_memory_interface.write_ack;
                scratchpad_memory_interface.write_req = 0;
                scratchpad_memory_interface.write_index = 0;
                scratchpad_memory_interface.write_data = 0;
            end else if (host_interface.write_index >= TIA_CORE_SCRATCHPAD_MEMORY_BASE_INDEX
                         && host_interface.write_index < TIA_CORE_SCRATCHPAD_MEMORY_BOUND_INDEX) begin
                monitor_interface.write_req = 0;
                monitor_interface.write_index = 0;
                monitor_interface.write_data = 0;
                performance_counters_interface.write_req = 0;
                performance_counters_interface.write_index = 0;
                performance_counters_interface.write_data = 0;
                register_file_interface.write_req = 0;
                register_file_interface.write_index = 0;
                register_file_interface.write_data = 0;
                instruction_memory_interface.write_req = 0;
                instruction_memory_interface.write_index = 0;
                instruction_memory_interface.write_data = 0;
                scratchpad_memory_interface.write_req = host_interface.write_req;
                scratchpad_memory_interface.write_index = host_interface.write_index
                                                          - TIA_CORE_SCRATCHPAD_MEMORY_BOUND_INDEX;
                scratchpad_memory_interface.write_data = host_interface.write_data;
                host_interface.write_ack = scratchpad_memory_interface.write_ack;
            end else begin
                host_interface.write_ack = 0;
                monitor_interface.write_req = 0;
                monitor_interface.write_index = 0;
                monitor_interface.write_data = 0;
                performance_counters_interface.write_req = 0;
                performance_counters_interface.write_index = 0;
                performance_counters_interface.write_data = 0;
                register_file_interface.write_req = 0;
                register_file_interface.write_index = 0;
                register_file_interface.write_data = 0;
                instruction_memory_interface.write_req = 0;
                instruction_memory_interface.write_index = 0;
                instruction_memory_interface.write_data = 0;
                scratchpad_memory_interface.write_req = 0;
                scratchpad_memory_interface.write_index = 0;
                scratchpad_memory_interface.write_data = 0;
            end
        end else begin
            host_interface.write_ack = 0;
            monitor_interface.write_req = 0;
            monitor_interface.write_index = 0;
            monitor_interface.write_data = 0;
            performance_counters_interface.write_req = 0;
            performance_counters_interface.write_index = 0;
            performance_counters_interface.write_data = 0;
            register_file_interface.write_req = 0;
            register_file_interface.write_index = 0;
            register_file_interface.write_data = 0;
            instruction_memory_interface.write_req = 0;
            instruction_memory_interface.write_index = 0;
            instruction_memory_interface.write_data = 0;
            scratchpad_memory_interface.write_req = 0;
            scratchpad_memory_interface.write_index = 0;
            scratchpad_memory_interface.write_data = 0;
        end
    end
endmodule
