`ifndef INSTRUCTION_SVH
`define INSTRUCTION_SVH

/*
 * Definitions for triggers and instructions.
 */

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

// A (physical) instruction broken down into its various fields.
typedef struct packed {
    logic vi;
    logic [TIA_PTM_WIDTH - 1:0] ptm;
    logic [TIA_ICI_WIDTH - 1:0] ici;
    logic [TIA_ICTB_WIDTH - 1:0] ictb;
    logic [TIA_ICTV_WIDTH - 1:0] ictv;
    logic [TIA_OP_WIDTH - 1:0] op;
    logic [TIA_ST_WIDTH - 1:0] st;
    logic [TIA_SI_WIDTH - 1:0] si;
    logic [TIA_DT_WIDTH - 1:0] dt;
    logic [TIA_DI_WIDTH - 1:0] di;
    logic [TIA_OCI_WIDTH - 1:0] oci;
    logic [TIA_OCT_WIDTH - 1:0] oct;
    logic [TIA_ICD_WIDTH - 1:0] icd;
    logic [TIA_PUM_WIDTH - 1:0] pum;
    logic [TIA_IMMEDIATE_WIDTH - 1:0] immediate;
} instruction_t;

// A memory-mapped instruction broken down into its various fields including padding.
typedef struct packed {
    logic vi;
    logic [TIA_PTM_WIDTH - 1:0] ptm;
    logic [TIA_ICI_WIDTH - 1:0] ici;
    logic [TIA_ICTB_WIDTH - 1:0] ictb;
    logic [TIA_ICTV_WIDTH - 1:0] ictv;
    logic [TIA_OP_WIDTH - 1:0] op;
    logic [TIA_ST_WIDTH - 1:0] st;
    logic [TIA_SI_WIDTH - 1:0] si;
    logic [TIA_DT_WIDTH - 1:0] dt;
    logic [TIA_DI_WIDTH - 1:0] di;
    logic [TIA_OCI_WIDTH - 1:0] oci;
    logic [TIA_OCT_WIDTH - 1:0] oct;
    logic [TIA_ICD_WIDTH - 1:0] icd;
    logic [TIA_PUM_WIDTH - 1:0] pum;
    logic [TIA_IMMEDIATE_WIDTH - 1:0] immediate;
    logic [TIA_MM_INSTRUCTION_PADDING_WIDTH - 1:0] padding;
} mm_instruction_t;

typedef struct packed {
    logic vi;
    logic [TIA_PTM_WIDTH - 1:0] ptm;
    logic [TIA_ICI_WIDTH - 1:0] ici;
    logic [TIA_ICTB_WIDTH - 1:0] ictb;
    logic [TIA_ICTV_WIDTH - 1:0] ictv;
    logic [TIA_OP_WIDTH - 1:0] op;
    logic [TIA_ST_WIDTH - 1:0] st;
    logic [TIA_SI_WIDTH - 1:0] si;
    logic [TIA_DT_WIDTH - 1:0] dt;
    logic [TIA_DI_WIDTH - 1:0] di;
    logic [TIA_OCI_WIDTH - 1:0] oci;
    logic [TIA_OCT_WIDTH - 1:0] oct;
    logic [TIA_ICD_WIDTH - 1:0] icd;
    logic [TIA_PUM_WIDTH - 1:0] pum;
} non_immediate_mm_instruction_t;

// Only the portions of an instruction relevant to triggering.
typedef struct packed {
    logic vi;
    logic [TIA_PTM_WIDTH - 1:0] ptm;
    logic [TIA_ICI_WIDTH - 1:0] ici;
    logic [TIA_ICTB_WIDTH - 1:0] ictb;
    logic [TIA_ICTV_WIDTH - 1:0] ictv;
    logic [TIA_OCI_WIDTH - 1:0] oci;
} trigger_t;

// Only the portions of an instruction relevant to the datapath.
typedef struct packed {
    logic vi;
    logic [TIA_OP_WIDTH - 1:0] op;
    logic [TIA_ST_WIDTH - 1:0] st;
    logic [TIA_SI_WIDTH - 1:0] si;
    logic [TIA_DT_WIDTH - 1:0] dt;
    logic [TIA_DI_WIDTH - 1:0] di;
    logic [TIA_OCI_WIDTH - 1:0] oci;
    logic [TIA_OCT_WIDTH - 1:0] oct;
    logic [TIA_ICD_WIDTH - 1:0] icd;
    logic [TIA_PUM_WIDTH - 1:0] pum;
    logic [TIA_WORD_WIDTH - 1:0] immediate; // Sign extended.
} datapath_instruction_t;

typedef struct packed {
    logic vi;
    logic [TIA_OP_WIDTH - 1:0] op;
    logic [TIA_ST_WIDTH - 1:0] st;
    logic [TIA_SI_WIDTH - 1:0] si;
    logic [TIA_DT_WIDTH - 1:0] dt;
    logic [TIA_DI_WIDTH - 1:0] di;
    logic [TIA_OCI_WIDTH - 1:0] oci;
    logic [TIA_OCT_WIDTH - 1:0] oct;
    logic [TIA_ICD_WIDTH - 1:0] icd;
    logic [TIA_PUM_WIDTH - 1:0] pum;
} non_immediate_datapath_instruction_t;

`endif // INSTRUCTION_SVH
