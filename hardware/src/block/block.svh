`ifndef BLOCK_SVH
`define BLOCK_SVH

/*
 * Meta-include file for all the definied structures a block references.
 */

`ifdef ASIC_SYNTHESIS
    `include "quartet.svh"
`elsif FPGA_SYNTHESIS
    `include "quartet.svh"
`elsif SIMULATION
    `include "../quartet/quartet.svh"
`else
    `include "quartet.svh"
`endif

`endif // BLOCK_SVH
