`ifndef FIXED_PARAMETERS_SVH
`define FIXED_PARAMETERS_SVH

/*
 * Fixed architectural parameters.
 */

// --- Tools ---

// Support for Synopsys Design Compiler (ASIC), Xilinx Vivado (FPGA) and simulation toolchains.
`ifndef ASIC_SYNTHESIS
    `ifndef FPGA_SYNTHESIS
        `ifndef SIMULATION
            `define ASIC_SYNTHESIS // Default to ASIC synthesis.
        `endif
    `endif
`endif

// --- ISA and Microarchitecture ---

// Including all extensions.
parameter TIA_NUM_OPS = 63;

// Base ISA.
parameter TIA_OP_NOP = 0;
parameter TIA_OP_MOV = 1;
parameter TIA_OP_ADD = 2;
parameter TIA_OP_SUB = 3;
parameter TIA_OP_SL = 4;
parameter TIA_OP_ASR = 5;
parameter TIA_OP_LSR = 6;
parameter TIA_OP_EQ = 7;
parameter TIA_OP_NE = 8;
parameter TIA_OP_SGT = 9;
parameter TIA_OP_UGT = 10;
parameter TIA_OP_SLT = 11;
parameter TIA_OP_ULT = 12;
parameter TIA_OP_SGE = 13;
parameter TIA_OP_UGE = 14;
parameter TIA_OP_SLE = 15;
parameter TIA_OP_ULE = 16;
parameter TIA_OP_BAND = 17;
parameter TIA_OP_BNAND = 18;
parameter TIA_OP_BOR = 19;
parameter TIA_OP_BNOR = 20;
parameter TIA_OP_BXOR = 21;
parameter TIA_OP_BXNOR = 22;
parameter TIA_OP_LAND = 23;
parameter TIA_OP_LNAND = 24;
parameter TIA_OP_LOR = 25;
parameter TIA_OP_LNOR = 26;
parameter TIA_OP_LXOR = 27;
parameter TIA_OP_LXNOR = 28;
parameter TIA_OP_GBY = 29; // Not yet implemented.
parameter TIA_OP_SBY = 30; // Not yet implemented.
parameter TIA_OP_CBY = 31; // Not yet implemented.
parameter TIA_OP_MBY = 32; // Not yet implemented.
parameter TIA_OP_GB = 33;
parameter TIA_OP_SB = 34;
parameter TIA_OP_CB = 35;
parameter TIA_OP_MB = 36;
parameter TIA_OP_CLZ = 37;
parameter TIA_OP_CTZ = 38;
parameter TIA_OP_HALT = 39;

// Scratchpad extensions.
parameter TIA_OP_LSW = 40;
parameter TIA_OP_SSW = 41;

// Load-store extensions.
parameter TIA_OP_RLW = 42; // Not yet implemented.
parameter TIA_OP_OLW = 43; // Not yet implemented.
parameter TIA_OP_SW = 44; // Not yet implemented.

// Multiplication extensions.
parameter TIA_OP_LMUL = 45;
parameter TIA_OP_SHMUL = 46;
parameter TIA_OP_UHMUL = 47;
parameter TIA_OP_MAC = 48; // Not yet implemented.

// Floating-point extensions.
parameter TIA_OP_ITF = 49; // Not yet implemented.
parameter TIA_OP_UTF = 50; // Not yet implemented.
parameter TIA_OP_FTI = 51; // Not yet implemented.
parameter TIA_OP_FTU = 52; // Not yet implemented.
parameter TIA_OP_FEQ = 53; // Not yet implemented.
parameter TIA_OP_FNE = 54; // Not yet implemented.
parameter TIA_OP_FGT = 55; // Not yet implemented.
parameter TIA_OP_FLT = 56; // Not yet implemented.
parameter TIA_OP_FLE = 57; // Not yet implemented.
parameter TIA_OP_FGE = 58; // Not yet implemented.
parameter TIA_OP_FADD = 59; // Not yet implemented.
parameter TIA_OP_FSUB = 60; // Not yet implemented.
parameter TIA_OP_FMUL = 61; // Not yet implemented.
parameter TIA_OP_FMAC = 62; // Not yet implemented.

// Source types.
parameter TIA_NUM_SOURCE_TYPES = 4;
parameter TIA_SOURCE_TYPE_NULL = 0;
parameter TIA_SOURCE_TYPE_IMMEDIATE = 1;
parameter TIA_SOURCE_TYPE_CHANNEL = 2;
parameter TIA_SOURCE_TYPE_REGISTER = 3;

// Destination types.
parameter TIA_NUM_DESTINATION_TYPES = 4;
parameter TIA_DESTINATION_TYPE_NULL = 0;
parameter TIA_DESTINATION_TYPE_CHANNEL = 1;
parameter TIA_DESTINATION_TYPE_REGISTER = 2;
parameter TIA_DESTINATION_TYPE_PREDICATE = 3;

// --- System Interface ---

// System control registers.
parameter TIA_NUM_SYSTEM_CONTROL_REGISTERS = 4;
parameter TIA_RESET_REGISTER_INDEX = 0;
parameter TIA_ENABLE_REGISTER_INDEX = 1;
parameter TIA_EXECUTE_REGISTER_INDEX = 2;
parameter TIA_HALTED_REGISTER_INDEX = 3;

// PE monitor registers.
parameter TIA_NUM_CORE_MONITOR_REGISTERS_IF_ENABLED = 2;
parameter TIA_PE_MONITOR_HALTED_INDEX = 0;
parameter TIA_PE_MONITOR_PREDICATES_INDEX = 1;

// PE performance counters.
parameter TIA_NUM_CORE_PERFORMANCE_COUNTERS_IF_ENABLED = 13;
parameter TIA_PE_EXECUTED_CYCLES_COUNTER_INDEX = 0;
parameter TIA_PE_INSTRUCTIONS_ISSUED_COUNTER_INDEX = 1;
parameter TIA_PE_INSTRUCTIONS_RETIRED_COUNTER_INDEX = 2;
parameter TIA_PE_INSTRUCTIONS_QUASHED_COUNTER_INDEX = 3;
parameter TIA_PE_UNTRIGGERED_CYCLES_COUNTER_INDEX = 4;
parameter TIA_PE_BUBBLES_COUNTER_INDEX = 5;
parameter TIA_PE_CONTROL_HAZARD_BUBBLES_COUNTER_INDEX = 6;
parameter TIA_PE_DATA_HAZARD_BUBBLES_COUNTER_INDEX = 7;
parameter TIA_PE_PREDICATE_PREDICTION_HITS_COUNTER_INDEX = 8;
parameter TIA_PE_PREDICATE_PREDICTION_MISSES_COUNTER_INDEX = 9;
parameter TIA_PE_TRIGGER_OVERRIDES_COUNTER_INDEX = 10;
parameter TIA_PE_MULTI_CYCLE_INSTRUCTION_STALLS_INDEX = 11;
parameter TIA_PE_PIPELINE_LATENCY_INDEX = 12;

// --- MMIO ---

// MMIO parameters.
parameter TIA_MMIO_DATA_WIDTH = 32;
parameter TIA_MMIO_INDEX_WIDTH = 32 - $clog2(32 / 8);

// AXI4-Lite parameters.
parameter AXI4_LITE_DATA_WIDTH = 32;
parameter AXI4_LITE_ADDRESS_WIDTH = 32;

`endif // FIXED_PARAMETERS_SVH
