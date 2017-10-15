/*
 * PE-private scratchpad memory wrapper.
 */

`include "datapath.svh"

module scratchpad_memory
    #(parameter DEPTH = 1024)
    (input logic clock,
     mmio_if.device host_interface,
     input logic [TIA_OP_WIDTH - 1:0] op,
     input logic [TIA_WORD_WIDTH - 1:0] operand_0,
     input logic [TIA_WORD_WIDTH - 1:0] operand_1,
     output logic [TIA_WORD_WIDTH - 1:0] result);

    // --- Internal Logic and Wiring ---

    // Muxed write data;
    logic [TIA_WORD_WIDTH - 1:0] write_data;

    // Translated from opcodes.
    logic read_enable, write_enable;
    logic [$clog2(DEPTH) - 1:0] index;

    // Single port RAM with width adjustments.
    single_port_ram #(.WIDTH(TIA_WORD_WIDTH),
                      .DEPTH(DEPTH))
        spram(.clock(clock),
              .read_enable(read_enable),
              .write_enable(write_enable),
              .index(index),
              .read_data(result),
              .write_data(write_data));


    // --- Combinational Logic ---

    // Write-only scratchpad memories.
    assign host_interface.read_data = 0;
    assign host_interface.read_ack = host_interface.read_req;

    // Writes from the host interface are registered immediately.
    assign host_interface.write_ack = host_interface.write_req;

    // Write data can come either from the first operand or the host.
    assign write_data = host_interface.write_req ? host_interface.write_data : operand_0;

    // Give the host priority access, and translate between opcodes and read/write enable signals.
    always_comb begin
        if (host_interface.read_req) begin
            read_enable = 0; // PE scratchpads, like instruction memories, are write-only.
            write_enable = 0;
            index = 0;
        end else if (host_interface.write_req) begin
            read_enable = 0;
            write_enable = 1;
            index = host_interface.write_index[$clog2(DEPTH) - 1:0];
        end else begin
            if (op == TIA_OP_LSW) begin
                read_enable = 1;
                write_enable = 0;
                index = operand_0[$clog2(DEPTH) - 1:0];
            end else if (op == TIA_OP_SSW) begin
                read_enable = 0;
                write_enable = 1;
                index = operand_1[$clog2(DEPTH) - 1:0];
            end else begin
                read_enable = 0;
                write_enable = 0;
                index = 0;
            end
        end
    end
endmodule
