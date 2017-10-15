/*
 * Run-of-the-mill register file. Note there is no reset, so like in a real processor, if you want
 * a register to be zero, you need to set it as such in assembly.
 */

`include "datapath.svh"

module register_file
    (input logic clock, // Positive-edge triggered.
     input logic enable, // Active high.
     mmio_if.device host_interface,
     input logic [TIA_REGISTER_INDEX_WIDTH - 1:0] read_index_0,
     input logic [TIA_REGISTER_INDEX_WIDTH - 1:0] read_index_1,
     input logic [TIA_REGISTER_INDEX_WIDTH - 1:0] read_index_2,
     input logic write_enable, // Active high.
     input logic [TIA_REGISTER_INDEX_WIDTH - 1:0] write_index,
     input logic [TIA_WORD_WIDTH - 1:0] register_write_data,
     output logic [TIA_WORD_WIDTH - 1:0] read_data_0,
     output logic [TIA_WORD_WIDTH - 1:0] read_data_1,
     output logic [TIA_WORD_WIDTH - 1:0] read_data_2,
     output logic [TIA_WORD_WIDTH - 1:0] register_data [TIA_NUM_REGISTERS - 1:0]);

    // --- Internal Logic and Wiring ---

    // Not synthesized.
    integer i;

    // The actual register file.
    logic [TIA_WORD_WIDTH - 1:0] registers [TIA_NUM_REGISTERS - 1:0];

    // --- Combinational Logic ---

    // Access the read data asynchronously.
    assign read_data_0 = registers[read_index_0];
    assign read_data_1 = registers[read_index_1];
    assign read_data_2 = registers[read_index_2];

    // Expose register data.
    always_comb begin
        for (i = 0; i < TIA_NUM_REGISTERS; i++)
            register_data[i] = registers[i];
    end

    // Read data is always null (register file is write only).
    assign host_interface.read_data = 0;
    assign host_interface.read_ack = host_interface.read_req;

    // Zero-latency writes.
    assign host_interface.write_ack = host_interface.write_req;

    // --- Sequential Logic ---

    // Latch in write data, if requested by either the datapath or host.
    always_ff @(posedge clock) begin
        if (enable) begin
            if (host_interface.write_req)
                registers[host_interface.write_index] <= host_interface.write_data;
            else if (write_enable)
                registers[write_index] <= register_write_data;
        end
    end
endmodule
