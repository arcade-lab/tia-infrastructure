`ifndef DATAPATH_SVH
`define DATAPATH_SVH

/*
 * Meta-include file for all the defined structures the datapath references.
 */

`ifdef ASIC_SYNTHESIS
    `include "derived_parameters.svh"
    `include "instruction.svh"
    `include "memory.svh"
    `include "mmio.svh"
    `include "interconnect.svh"
`elsif FPGA_SYNTHESIS
    `include "derived_parameters.svh"
    `include "instruction.svh"
    `include "memory.svh"
    `include "mmio.svh"
    `include "interconnect.svh"
`elsif SIMULATION
    `include "../derived_parameters.svh"
    `include "../instruction/instruction.svh"
    `include "../memory/memory.svh"
    `include "../mmio/mmio.svh"
    `include "../interconnect/interconnect.svh"
`else
    `include "derived_parameters.svh"
    `include "instruction.svh"
    `include "memory.svh"
    `include "mmio.svh"
    `include "interconnect.svh"
`endif

`endif // DATAPATH_SVH
