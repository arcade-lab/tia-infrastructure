`ifndef PROCESSING_ELEMENT_SVH
`define PROCESSING_ELEMENT_SVH

/*
 * Meta-include file for all the definied structures a processing element references.
 */

`ifdef ASIC_SYNTHESIS
    `include "derived_parameters.svh"
    `include "control.svh"
    `include "datapath.svh"
    `include "instruction.svh"
    `include "mmio.svh"
    `include "interconnect.svh"
    `include "memory.svh"
`elsif FPGA_SYNTHESIS
    `include "derived_parameters.svh"
    `include "control.svh"
    `include "datapath.svh"
    `include "instruction.svh"
    `include "mmio.svh"
    `include "interconnect.svh"
    `include "memory.svh"
`elsif SIMULATION
    `include "../derived_parameters.svh"
    `include "../control/control.svh"
    `include "../datapath/datapath.svh"
    `include "../instruction/instruction.svh"
    `include "../mmio/mmio.svh"
    `include "../interconnect/interconnect.svh"
    `include "../memory/memory.svh"
`else
    `include "derived_parameters.svh"
    `include "control.svh"
    `include "datapath.svh"
    `include "instruction.svh"
    `include "mmio.svh"
    `include "interconnect.svh"
    `include "memory.svh"
`endif

`endif // PROCESSING_ELEMENT_SVH
