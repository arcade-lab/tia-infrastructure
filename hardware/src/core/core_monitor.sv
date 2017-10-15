/*
 * A memory-mapped debug/diagnostic module to report the current predicate and register state of a
 * processing element core as well as its halted status. This could be potentially useful in
 * diagnosing issues with programs that do not halt as expected.
 */

`include "core.svh"

module core_monitor
    (input logic clock, // Positive-edge triggered.
     input logic reset, // Active high.
     input logic enable, // Active high.
     mmio_if.device host_interface,
     input logic core_halted,
     input logic [TIA_NUM_PREDICATES - 1:0] core_predicates,
     input logic [TIA_WORD_WIDTH - 1:0] core_registers [TIA_NUM_REGISTERS - 1:0]);

    // --- Internal Logic and Wiring ---

    // Not synthesized.
    integer i, j;

    // Buffers to avoid affecting critical path.
    logic core_halted_buffer;
    logic [TIA_NUM_PREDICATES - 1:0] core_predicates_buffer;
    logic [TIA_WORD_WIDTH - 1:0] core_registers_buffer [TIA_NUM_REGISTERS - 1:0];

    // --- Combinational Logic ---

    // Handle reads from the registers.
    always_comb begin
        if (enable && host_interface.read_req) begin
            case (host_interface.read_index)
                TIA_PE_MONITOR_HALTED_INDEX: host_interface.read_data = core_halted_buffer;
                TIA_PE_MONITOR_PREDICATES_INDEX: host_interface.read_data = core_predicates_buffer;
                default: begin
                    if (host_interface.read_index > TIA_PE_MONITOR_HALTED_INDEX
                        && host_interface.read_index < TIA_PE_MONITOR_HALTED_INDEX + TIA_NUM_REGISTERS) begin
                        host_interface.read_data = core_registers_buffer[host_interface.read_index
                                                                       - TIA_PE_MONITOR_HALTED_INDEX];
                    end else
                        host_interface.read_data = 0;
                end
            endcase
        end else begin
            host_interface.read_data = 0;
        end
    end

    // Reads from muxed registers have no latency.
    assign host_interface.read_ack = host_interface.read_req;

    // We do not support writes, so we always immediately acknowledge write and implicitly discard
    // their data.
    assign host_interface.write_ack = host_interface.write_req;

    // --- Sequential Logic ---

    // Latch in architectural state to the buffers.
    always_ff @(posedge clock) begin
        if (reset) begin
            core_predicates_buffer <= 0;
            core_halted_buffer <= 0;
            for (i = 0; i < TIA_NUM_REGISTERS; i++)
                core_registers_buffer[i] <= 0;
        end else if (enable) begin
            core_predicates_buffer <= core_predicates;
            core_halted_buffer <= core_halted;
            for (j = 0; j < TIA_NUM_REGISTERS; j++)
                core_registers_buffer[j] <= core_registers[j];
        end
    end
endmodule
