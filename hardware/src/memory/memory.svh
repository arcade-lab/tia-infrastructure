`ifndef MEMORY_SVH
`define MEMORY_SVH

`ifdef ASIC_SYNTHESIS
    `include "derived_parameters.svh"
    `include "mmio.svh"
`elsif FPGA_SYNTHESIS
    `include "derived_parameters.svh"
    `include "mmio.svh"
`elsif SIMULATION
    `include "../derived_parameters.svh"
    `include "../mmio/mmio.svh"
`else
    `include "derived_parameters.svh"
    `include "mmio.svh"
`endif

`endif // MEMORY_SVH
