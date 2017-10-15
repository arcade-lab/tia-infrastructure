`ifndef QUARTET_SVH
`define QUARTET_SVH

/*
 * Meta-include file for all the definied structures a quartet references.
 */

`ifdef ASIC_SYNTHESIS
    `include "processing_element.svh"
`elsif FPGA_SYNTHESIS
    `include "processing_element.svh"
`elsif SIMULATION
    `include "../processing_element/processing_element.svh"
`else
    `include "processing_element.svh"
`endif

`endif // QUARTET_SVH
