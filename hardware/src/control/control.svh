`ifndef CONTROL_SVH
`define CONTROL_SVH

/*
 * Meta-include file for all the defined structures control references.
 */

`ifdef ASIC_SYNTHESIS
    `include "derived_parameters.svh"
    `include "instruction.svh"
    `include "mmio.svh"
    `include "interconnect.svh"
`elsif FPGA_SYNTHESIS
    `include "derived_parameters.svh"
    `include "instruction.svh"
    `include "mmio.svh"
    `include "interconnect.svh"
`elsif SIMULATION
    `include "../derived_parameters.svh"
    `include "../instruction/instruction.svh"
    `include "../mmio/mmio.svh"
    `include "../interconnect/interconnect.svh"
`else
    `include "derived_parameters.svh"
    `include "instruction.svh"
    `include "mmio.svh"
    `include "interconnect.svh"
`endif

typedef enum logic [2:0] {ALU,
                          SM,
                          IMU,
                          FCCU,
                          FASU,
                          FMU,
                          FMAU} functional_unit_t;

`endif // CONTROL_SVH
