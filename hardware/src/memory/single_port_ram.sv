/*
 * Single-port RAM written to be synthesizable as BRAM on Xilinx FPGAs. Default size is 512 words
 * (which will use all capacity assuming those words are 32 bits each).
 */

`include "memory.svh"

module single_port_ram
    #(parameter WIDTH = TIA_WORD_WIDTH,
      parameter DEPTH = 1024)
    (input logic clock,
     input logic read_enable,
     input logic write_enable,
     input logic [$clog2(DEPTH) - 1:0] index,
     output logic [WIDTH - 1:0] read_data,
     input logic [WIDTH - 1:0] write_data);

    // --- Internal Logic and Wiring ---

    // RAM.
    (* ram_style = "block" *) logic [WIDTH - 1:0] ram [DEPTH - 1:0];

    // --- Sequential Logic ---

    // Read and write access.
    always_ff @(posedge clock) begin
        if (read_enable)
            read_data <= ram[index];
        else
            read_data <= 0;
        if (write_enable)
            ram[index] <= write_data;
    end
endmodule
