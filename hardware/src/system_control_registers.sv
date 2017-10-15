/*
 * Global system control registers to start and stop execution and reset.
 */

`ifdef ASIC_SYNTHESIS
    `include "mmio.svh"
`elsif FPGA_SYNTHESIS
    `include "mmio.svh"
`elsif SIMULATION
    `include "../mmio/mmio.svh"
`else
    `include "mmio.svh"
`endif

module system_control_registers
    (input logic clock,
     input logic reset,
     mmio_if.device host_interface,
     output logic system_reset,
     output logic system_enable,
     output logic system_execute,
     input logic system_halted);

    // --- Local Parameters ---

    // Memory map.
    localparam TIA_SYSTEM_RESET_REG = 0;
    localparam TIA_SYSTEM_ENABLE_REG = 1;
    localparam TIA_SYSTEM_EXECUTE_REG = 2;
    localparam TIA_SYSTEM_HALTED_REG = 3;

    // --- Combinational Logic ---

    // Map reads.
    always_comb begin
        if (host_interface.read_req) begin
            unique case (host_interface.read_index)
                TIA_SYSTEM_RESET_REG: host_interface.read_data = system_reset;
                TIA_SYSTEM_ENABLE_REG: host_interface.read_data = system_enable;
                TIA_SYSTEM_EXECUTE_REG: host_interface.read_data = system_execute;
                TIA_SYSTEM_HALTED_REG: host_interface.read_data = system_halted;
                default: host_interface.read_data = 0;
            endcase
        end else
            host_interface.read_data = 0;
    end

    // Reads from muxed registers have no latency.
    assign host_interface.read_ack = host_interface.read_req;

    // Writes are registered immediately.
    assign host_interface.write_ack = host_interface.write_req;

    // --- Sequential Logic ---

    // Handle the synchronous reset, reset the enable and execute registers if the reset register
    // is high and the host is not trying to write to any register, and map writes.
    always_ff @(posedge clock) begin
        if (reset) begin
            system_reset <= 0;
            system_enable <= 0;
            system_execute <= 0;
        end else if (system_reset && !host_interface.write_req) begin
            system_enable <= 0;
            system_execute <= 0;
        end else if (host_interface.write_req) begin
            unique case (host_interface.write_index)
                TIA_SYSTEM_RESET_REG: system_reset <= host_interface.write_data;
                TIA_SYSTEM_ENABLE_REG: system_enable <= host_interface.write_data;
                TIA_SYSTEM_EXECUTE_REG: system_execute <= host_interface.write_data;
                // The halted register is a pseudo-register depending on the PEs' state.
            endcase
        end
    end
endmodule
