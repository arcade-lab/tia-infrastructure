`ifndef KNOB_PARAMETERS_SVH
`define KNOB_PARAMETERS_SVH

/*
 * User-editable parameters.
 */

// --- Microarchitecture ---

// Selected core type.
`define TIA_INTEGER_CORE

// Integer architecture.
`ifdef TIA_INTEGER_CORE
    `define TIA_CORE integer_core

// Pipelines from MICRO.
`elsif TIA_TDX_CORE
    `define TIA_CORE tdx_core
`elsif TIA_TDX1_X2_CORE
    `define TIA_CORE tdx1_x2_core
`elsif TIA_TD_X_CORE
    `define TIA_CORE td_x_core
`elsif TIA_TD_X1_X2_CORE
    `define TIA_CORE td_x1_x2_core
`elsif TIA_T_DX_CORE
    `define TIA_CORE t_dx_core
`elsif TIA_T_DX1_X2_CORE
    `define TIA_CORE t_dx1_x2_core
`elsif TIA_T_D_X_CORE
    `define TIA_CORE t_d_x_core
`elsif TIA_T_D_X1_X2_CORE
    `define TIA_CORE t_d_x1_x2_core

// Canary (one microarchitecture must be selected).
`else
    `define TIA_CORE canary_for_invalid_core_type
`endif

// --- Routing Architecture ---

// Selected router type.
`define TIA_SOFTWARE_ROUTER

// Software.
`ifdef TIA_SOFTWARE_ROUTER
    `define TIA_ROUTER software_router

// Switch
`elsif TIA_SWITCH_ROUTER
    `define TIA_ROUTER switch_router

// Canary (one router type must be selected).
`else
    `define TIA_ROUTER canary_for_invalid_router_type
`endif

// --- Data and Instruction Representation ---

// Data word size.
parameter TIA_WORD_WIDTH = 32;

// Memory-mapped instruction representation.
parameter TIA_MM_INSTRUCTION_WIDTH = 128;

// Maximum number of instructions per PE.
parameter TIA_MAX_NUM_INSTRUCTIONS = 16;

// Instruction storage medium.
// `define TIA_LATCH_BASED_INSTRUCTION_MEMORY
// `define TIA_RAM_BASED_IMMEDIATE_STORAGE


// --- Instruction Support ---

// Whether to include multipliers (which should be considered part of the core ISA, but can be
// disabled for debug/timing/fitting purposes.)
`define TIA_HAS_MULTIPLIER
`define TIA_HAS_TWO_WORD_PRODUCT_MULTIPLIER

// Whether to include a PE-private scratchpad and the associated load and store instructions.
// `define TIA_HAS_SCRATCHPAD

// Scratchpad size.
parameter TIA_NUM_SCRATCHPAD_WORDS_IF_ENABLED = 512;

// --- Instruction Triggering ---

// Number of predicates to store state.
parameter TIA_NUM_PREDICATES = 8;

// Tags for inter-PE/ME channels.
parameter TIA_NUM_TAGS = 3;

// Maximum number of input channels upon which an instruction can depend.
parameter TIA_MAX_NUM_INPUT_CHANNELS_TO_CHECK = 2;

// Effective queue status.
`define TIA_HAS_FULL_INFORMATION_CHANNEL_STATUS_UPDATING

// Predicate prediction and speculative execution.
`define TIA_HAS_SPECULATIVE_PREDICATE_UNIT

// --- Datapath and Channels ---

// Number of data registers.
parameter TIA_NUM_REGISTERS = 8;

// Number of input and output channels.
parameter TIA_NUM_INPUT_CHANNELS = 4;
parameter TIA_NUM_OUTPUT_CHANNELS = 4;

// Instruction immediates.
parameter TIA_IMMEDIATE_WIDTH = 32;

// How many input channels we can dequeue in a single cycle.
parameter TIA_MAX_NUM_INPUT_CHANNELS_TO_DEQUEUE = TIA_NUM_INPUT_CHANNELS; // TODO: remove.

// --- Array ---

// TODO: Dimensions of the array.

// --- Interconnect ---

// Number of physical planes.
parameter TIA_NUM_PHYSICAL_PLANES = 1;

// Generic channel FIFO depth.
parameter TIA_CHANNEL_BUFFER_FIFO_DEPTH = 2;

// Link buffer FIFO depth.
parameter TIA_LINK_BUFFER_FIFO_DEPTH = 2;

// Memory link buffer FIFO depth.
parameter TIA_MEMORY_LINK_BUFFER_FIFO_DEPTH = 4;

// --- Memory ---

parameter TIA_NUM_DATA_MEMORY_WORDS = 32786;

// --- Monitors and Performance Counters ---

// Comment out to remove PE debug monitors.
`define TIA_HAS_CORE_MONITOR

// Comment out to disable particular performance counter features.
`define TIA_HAS_CORE_PERFORMANCE_COUNTERS

`endif // KNOB_PARAMETERS_SVH

