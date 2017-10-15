`ifndef DERIVED_PARAMETERS_SVH
`define DERIVED_PARAMETERS_SVH

/*
 * Parameters that are not meant to be defined by the user.
 */

`include "knob_parameters.svh"
`include "fixed_parameters.svh"

// --- Utility Macros ---

// max
`define max(x, y) ((x > y) ? x : y)

// --- Core Architecture ---

// Index widths.
parameter TIA_INSTRUCTION_INDEX_WIDTH = $clog2(TIA_MAX_NUM_INSTRUCTIONS);
parameter TIA_REGISTER_INDEX_WIDTH = $clog2(TIA_NUM_REGISTERS);

// --- Triggered Instruction Field Widths ---

parameter TIA_TRUE_PTM_WIDTH = TIA_NUM_PREDICATES;
parameter TIA_FALSE_PTM_WIDTH = TIA_NUM_PREDICATES;
parameter TIA_PTM_WIDTH = TIA_TRUE_PTM_WIDTH + TIA_FALSE_PTM_WIDTH;
parameter TIA_SINGLE_ICI_WIDTH = $clog2(TIA_NUM_INPUT_CHANNELS + 1);
parameter TIA_ICI_WIDTH = TIA_MAX_NUM_INPUT_CHANNELS_TO_CHECK * TIA_SINGLE_ICI_WIDTH;
parameter TIA_TAG_WIDTH = $clog2(TIA_NUM_TAGS);
parameter TIA_ICTB_WIDTH = TIA_MAX_NUM_INPUT_CHANNELS_TO_CHECK;
parameter TIA_ICTV_WIDTH = TIA_MAX_NUM_INPUT_CHANNELS_TO_CHECK * TIA_TAG_WIDTH;
parameter TIA_OP_WIDTH = $clog2(TIA_NUM_OPS);
parameter TIA_SINGLE_ST_WIDTH = $clog2(TIA_NUM_SOURCE_TYPES);
parameter TIA_ST_WIDTH = 3 * TIA_SINGLE_ST_WIDTH;
parameter TIA_SINGLE_SI_WIDTH = $clog2(`max(TIA_NUM_REGISTERS, TIA_NUM_INPUT_CHANNELS));
parameter TIA_SI_WIDTH = 3 * TIA_SINGLE_SI_WIDTH;
parameter TIA_DT_WIDTH = $clog2(TIA_NUM_DESTINATION_TYPES);
parameter TIA_DI_WIDTH = $clog2(`max(`max(TIA_NUM_REGISTERS, TIA_NUM_OUTPUT_CHANNELS), TIA_NUM_PREDICATES));
parameter TIA_OCI_WIDTH = TIA_NUM_OUTPUT_CHANNELS;
parameter TIA_OCT_WIDTH = TIA_TAG_WIDTH;
parameter TIA_ICD_WIDTH = TIA_NUM_INPUT_CHANNELS;
parameter TIA_TRUE_PUM_WIDTH = TIA_TRUE_PTM_WIDTH;
parameter TIA_FALSE_PUM_WIDTH = TIA_FALSE_PTM_WIDTH;
parameter TIA_PUM_WIDTH = TIA_TRUE_PUM_WIDTH + TIA_FALSE_PUM_WIDTH;
parameter TIA_NON_IMMEDIATE_INSTRUCTION_WIDTH = 1 // Valid bit vi.
                                                + TIA_PTM_WIDTH
                                                + TIA_ICI_WIDTH
                                                + TIA_ICTB_WIDTH
                                                + TIA_ICTV_WIDTH
                                                + TIA_OP_WIDTH
                                                + TIA_ST_WIDTH
                                                + TIA_SI_WIDTH
                                                + TIA_DT_WIDTH
                                                + TIA_DI_WIDTH
                                                + TIA_OCI_WIDTH
                                                + TIA_OCT_WIDTH
                                                + TIA_ICD_WIDTH
                                                + TIA_PUM_WIDTH;
parameter TIA_PHY_INSTRUCTION_WIDTH = TIA_NON_IMMEDIATE_INSTRUCTION_WIDTH + TIA_IMMEDIATE_WIDTH;
parameter TIA_MM_INSTRUCTION_PADDING_WIDTH = TIA_MM_INSTRUCTION_WIDTH - TIA_PHY_INSTRUCTION_WIDTH;

// --- Core Debug Monitor ---

// Set in knob parameters.
`ifdef TIA_HAS_CORE_MONITOR
parameter TIA_NUM_CORE_MONITOR_WORDS = TIA_NUM_CORE_MONITOR_REGISTERS_IF_ENABLED + TIA_NUM_REGISTERS;
`else
parameter TIA_NUM_CORE_MONITOR_WORDS = 0;
`endif

// --- Core Performance Counters ---

// Set in knob parameters.
`ifdef TIA_HAS_CORE_PERFORMANCE_COUNTERS
parameter TIA_NUM_CORE_PERFORMANCE_COUNTERS = TIA_NUM_CORE_PERFORMANCE_COUNTERS_IF_ENABLED;
`else
parameter TIA_NUM_CORE_PERFORMANCE_COUNTERS = 0;
`endif

// --- Register File and Instruction Memory ---

// MMIO address space words.
parameter TIA_NUM_REGISTER_FILE_WORDS = TIA_NUM_REGISTERS;
parameter TIA_NUM_INSTRUCTION_MEMORY_WORDS = TIA_MAX_NUM_INSTRUCTIONS * TIA_MM_INSTRUCTION_WIDTH / TIA_MMIO_DATA_WIDTH;

// --- Scratchpad ---

// Set in knob parameters.
`ifdef TIA_HAS_SCRATCHPAD
parameter TIA_NUM_SCRATCHPAD_WORDS = TIA_NUM_SCRATCHPAD_WORDS_IF_ENABLED;
`else
parameter TIA_NUM_SCRATCHPAD_WORDS = 0;
`endif

// --- Core Memory Map ---

// Memory map of an individual PE.
parameter TIA_CORE_MONITOR_BASE_INDEX = 0;
`ifdef TIA_HAS_CORE_MONITOR
parameter TIA_CORE_MONITOR_BOUND_INDEX = TIA_NUM_CORE_MONITOR_WORDS;
`else
parameter TIA_CORE_MONITOR_BOUND_INDEX = 0;
`endif
parameter TIA_CORE_PERFORMANCE_COUNTERS_BASE_INDEX = TIA_CORE_MONITOR_BOUND_INDEX;
`ifdef TIA_HAS_CORE_PERFORMANCE_COUNTERS
parameter TIA_CORE_PERFORMANCE_COUNTERS_BOUND_INDEX = TIA_CORE_PERFORMANCE_COUNTERS_BASE_INDEX
                                                     + TIA_NUM_CORE_PERFORMANCE_COUNTERS;
`else
parameter TIA_CORE_PERFORMANCE_COUNTERS_BOUND_INDEX = TIA_CORE_MONITOR_BOUND_INDEX;
`endif
parameter TIA_CORE_REGISTER_FILE_BASE_INDEX = TIA_CORE_PERFORMANCE_COUNTERS_BOUND_INDEX;
parameter TIA_CORE_REGISTER_FILE_BOUND_INDEX = TIA_CORE_REGISTER_FILE_BASE_INDEX
                                               + TIA_NUM_REGISTER_FILE_WORDS;
parameter TIA_CORE_INSTRUCTION_MEMORY_BASE_INDEX = TIA_CORE_REGISTER_FILE_BOUND_INDEX;
parameter TIA_CORE_INSTRUCTION_MEMORY_BOUND_INDEX = TIA_CORE_INSTRUCTION_MEMORY_BASE_INDEX
                                                    + TIA_NUM_INSTRUCTION_MEMORY_WORDS;
parameter TIA_CORE_SCRATCHPAD_MEMORY_BASE_INDEX = TIA_CORE_INSTRUCTION_MEMORY_BOUND_INDEX;
`ifdef TIA_HAS_SCRATCHPAD
parameter TIA_CORE_SCRATCHPAD_MEMORY_BOUND_INDEX = TIA_CORE_SCRATCHPAD_MEMORY_BASE_INDEX
                                                  + TIA_NUM_SCRATCHPAD_WORDS;
`else
parameter TIA_CORE_SCRATCHPAD_MEMORY_BOUND_INDEX = TIA_CORE_SCRATCHPAD_MEMORY_BASE_INDEX;
`endif

// Core address space size.
parameter TIA_NUM_CORE_ADDRESS_SPACE_WORDS = TIA_NUM_CORE_MONITOR_WORDS
                                           + TIA_NUM_CORE_PERFORMANCE_COUNTERS
                                           + TIA_NUM_REGISTER_FILE_WORDS
                                           + TIA_NUM_INSTRUCTION_MEMORY_WORDS
                                           + TIA_NUM_SCRATCHPAD_WORDS;

// --- Channels ---

// Exposed count widths.
parameter TIA_CHANNEL_BUFFER_COUNT_WIDTH = $clog2(TIA_CHANNEL_BUFFER_FIFO_DEPTH) + 1;

// Channel index widths.
parameter TIA_INPUT_CHANNEL_INDEX_WIDTH = $clog2(TIA_NUM_INPUT_CHANNELS);
parameter TIA_OUTPUT_CHANNEL_INDEX_WIDTH = $clog2(TIA_NUM_OUTPUT_CHANNELS);

// --- Interconnect ---

// Router memory words.
`ifdef TIA_SOFTWARE_ROUTER
    parameter TIA_ROUTER_SETTING_MEMORY_WORDS = 0;
`elsif TIA_SWITCH_ROUTER
    parameter TIA_ROUTER_SETTING_MEMORY_WORDS = 1 + TIA_NUM_PHYSICAL_PLANES;
`else
    parameter TIA_ROUTER_SETTING_MEMORY_WORDS = 0;
`endif

// Physical plane index width.
parameter TIA_PHYSICAL_PLANE_INDEX_WIDTH = $clog2(TIA_NUM_PHYSICAL_PLANES) + 1;

// --- Processing Element Memory Map ---

// Memory map using the above parameters.
parameter TIA_CORE_BASE_INDEX = 0;
parameter TIA_CORE_BOUND_INDEX = TIA_NUM_CORE_ADDRESS_SPACE_WORDS;
parameter TIA_ROUTER_BASE_INDEX = TIA_CORE_BOUND_INDEX;
parameter TIA_ROUTER_BOUND_INDEX = TIA_ROUTER_BASE_INDEX
                                     + TIA_ROUTER_SETTING_MEMORY_WORDS;
parameter TIA_PROCESSING_ELEMENT_BASE_INDEX = TIA_CORE_BASE_INDEX;
parameter TIA_PROCESSING_ELEMENT_BOUND_INDEX = TIA_ROUTER_BOUND_INDEX;
parameter TIA_NUM_PROCESSING_ELEMENT_ADDRESS_SPACE_WORDS = TIA_NUM_CORE_ADDRESS_SPACE_WORDS
                                                           + TIA_ROUTER_SETTING_MEMORY_WORDS;
parameter TIA_NUM_QUARTET_ADDRESS_SPACE_WORDS = 4 * TIA_NUM_PROCESSING_ELEMENT_ADDRESS_SPACE_WORDS;
parameter TIA_NUM_BLOCK_ADDRESS_SPACE_WORDS = 4 * TIA_NUM_QUARTET_ADDRESS_SPACE_WORDS;

`endif // DERIVED_PARAMETERS_SVH
