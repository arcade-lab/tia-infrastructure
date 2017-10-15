#ifndef PROCESSING_ELEMENT_H
#define PROCESSING_ELEMENT_H

#include <stdint.h>

#include "platform.h"

#define NUM_DEBUG_MONITOR_REGISTERS 2
#define NUM_PERFORMANCE_COUNTERS_WORDS 13

// PE access data structure.
typedef struct processing_element {
    // Debug monitor.
    size_t num_debug_monitor_words;
    size_t num_predicates;
    size_t num_registers;
    volatile uint32_t *halted_reg,
                      *predicates_reg,
                      *registers_monitor;

    // Performance counters.
    size_t num_performance_counter_words;
    volatile uint32_t *executed_cycles_counter_reg,
                      *instructions_issued_counter_reg,
                      *instructions_retired_counter_reg,
                      *instructions_quashed_counter_reg,
                      *untriggered_cycles_counter_reg,
                      *bubbles_counter_reg,
                      *control_hazard_bubbles_counter_reg,
                      *data_hazard_bubbles_counter_reg,
                      *predicate_prediction_hits_counter_reg,
                      *predicate_prediction_misses_counter_reg,
                      *trigger_overrides_counter_reg,
                      *multi_cycle_instruction_stalls_counter_reg,
                      *pipeline_latency_reg;

    // Register file initialization.
    volatile uint32_t *registers_initialization;

    // Instruction memory.
    size_t num_instruction_words;
    volatile uint32_t *instructions;

    // Scratchpad memory.
    size_t num_scratchpad_words;
    volatile uint32_t *scratchpad;

    // Router settings.
    size_t num_router_setting_memory_words;
    volatile uint32_t *router_setting_memory;

    // Address space.
    size_t num_address_space_words;
} processing_element_t;

// Initialization.
int initialize_processing_element(processing_element_t *processing_element,
                                  volatile uint32_t *processing_element_base_address,
                                  platform_t *platform);

// Register access.
uint8_t processing_element_halted(processing_element_t *processing_element);
uint32_t processing_element_predicates(processing_element_t *processing_element);
uint32_t register_file(size_t register_index, processing_element_t *processing_element);
uint32_t executed_cycles_counter(processing_element_t *processing_element);
uint32_t instructions_issued_counter(processing_element_t *processing_element);
uint32_t instructions_retired_counter(processing_element_t *processing_element);
uint32_t instructions_quashed_counter(processing_element_t *processing_element);
uint32_t untriggered_cycles_counter(processing_element_t *processing_element);
uint32_t bubbles_counter(processing_element_t *processing_element);
uint32_t control_hazard_bubbles_counter(processing_element_t *processing_element);
uint32_t data_hazard_bubbles_counter(processing_element_t *processing_element);
uint32_t predicate_prediction_hits_counter(processing_element_t *processing_element);
uint32_t predicate_prediction_misses_counter(processing_element_t *processing_element);
uint32_t trigger_overrides_counter(processing_element_t *processing_element);
uint32_t multi_cycle_instruction_stalls_counter(processing_element_t *processing_element);
uint32_t pipeline_latency(processing_element_t *processing_element);

// Memory access.
int initialize_registers(processing_element_t *processing_element, uint32_t *write_data);
int write_processing_element_program(processing_element_t *processing_element, uint32_t *write_data);
int clear_processing_element_instructions(processing_element_t *processing_element);
int write_to_processing_element_instructions(processing_element_t *processing_element, uint32_t *write_data);
int clear_processing_element_scratchpad(processing_element_t *processing_element);
int write_to_processing_element_scratchpad(processing_element_t *processing_element, uint32_t *write_data);
int clear_processing_element_router_setting_memory(processing_element_t *processing_element);
int write_to_processing_element_router_setting_memory(processing_element_t *processing_element, uint32_t *write_data);

// Display.
void display_debug_info(processing_element_t *processing_element);

#endif
