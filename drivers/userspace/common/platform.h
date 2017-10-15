#ifndef PLATFORM_H
#define PLATFORM_H

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>

#include <cJSON.h>

// --- Structures for Deserialized Platform Information ---

typedef struct core {
    // Base architecture.
    char *architecture;
    uint8_t device_word_width;
    uint8_t immediate_width;
    uint8_t mm_instruction_width;
    uint8_t num_instructions;
    uint8_t num_predicates;
    uint8_t num_registers;

    // Instruction features.
    bool has_multiplier;
    bool has_two_word_product_multiplier;
    bool has_scratchpad;
    uint16_t num_scratchpad_words;

    // Instruction memory microarchitecture.
    bool latch_based_instruction_memory;
    bool ram_based_immediate_storage;

    // Channels.
    uint8_t num_input_channels;
    uint8_t num_output_channels;
    uint8_t channel_buffer_depth;
    uint8_t max_num_input_channels_to_check;
    uint8_t num_tags;

    // Pipeline features.
    bool has_speculative_predicate_unit;
    bool has_effective_queue_status;

    // Debugging and profiling features.
    bool has_debug_monitor;
    bool has_performance_counters;
} core_t;

typedef struct interconnect {
    // Router configuration.
    char *router_type;
    uint8_t num_router_sources;
    uint8_t num_router_destinations;
    uint8_t num_input_channels;
    uint8_t num_output_channels;
    uint8_t router_buffer_depth;
    uint8_t num_physical_planes;
} interconnect_t;

typedef struct system {
    // Host bus information.
    uint8_t host_word_width;

    // Test memory system.
    uint32_t num_test_data_memory_words;
    uint8_t test_data_memory_buffer_depth;
} system_t;

typedef struct platform {
    // Reference for each subsystem.
    core_t *core;
    interconnect_t *interconnect;
    system_t *system;
} platform_t;

// --- Utility Functions ---

// JSON manipulation.
int get_integer_parameter(cJSON *json, const char *key);
char *get_string_parameter(cJSON *json, const char *key);

// Construction and tear-down functions.
core_t *create_core(cJSON *core_json);
void destroy_core(core_t *core);
interconnect_t *create_interconnect(cJSON *interconnect_json);
void destroy_interconnect(interconnect_t *interconnect);
system_t *create_system(cJSON *system_json);
void destroy_system(system_t *system);
platform_t *create_platform(char *platform_string);
void destroy_platform(platform_t *platform);

#endif // PLATFORM_H
