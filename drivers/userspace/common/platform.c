#include "platform.h"

// --- JSON Manipulation ---

int get_integer_parameter(cJSON *json, const char *key)
{
    cJSON *value;

    // Attempt to look up the numeric value, and return it, if found.
    value = cJSON_GetObjectItem(json, key);
    if (value == NULL)
        return -1;
    return value->valueint;
}

char *get_string_parameter(cJSON *json, const char *key)
{
    cJSON *value;

    // Attempt to look up the string value, and return it, if found.
    value = cJSON_GetObjectItem(json, key);
    if (value == NULL)
        return NULL;
    return value->valuestring;
}

// --- Construction and Tear-Down ---

core_t *create_core(cJSON *core_json)
{
    core_t *core;
    int ret;
    char *string_parameter;

    // Allocate the core structure.
    if ((core = (core_t *)malloc(sizeof(core_t))) == NULL) {
        perror("malloc");
        fprintf(stderr, "In create_core(): failed to allocate memory for the core structure.\n");
        return NULL;
    }

    // Copy the architecture string over.
    if ((string_parameter = get_string_parameter(core_json, "architecture")) == NULL) {
        fprintf(stderr, "In create_core(): unable to find the JSON key \"architecture\".\n");
        free(core);
        return NULL;
    }
    if ((core->architecture = (char *)malloc((strlen(string_parameter) + 1) * sizeof(char))) == NULL) {
        perror("malloc");
        fprintf(stderr, "In create_core(): failed to allocate the router string for the system.\n");
        free(core);
        return NULL;
    }
    strcpy(core->architecture, string_parameter);

    // Fill in the remaining fields.
    if ((ret = get_integer_parameter(core_json, "device_word_width")) < 0) {
        fprintf(stderr, "In create_core(): unable to find the JSON key \"device_word_width\".\n");
        free(core->architecture);
        free(core);
        return NULL;
    }
    core->device_word_width = (uint8_t)ret;
    if ((ret = get_integer_parameter(core_json, "immediate_width")) < 0) {
        fprintf(stderr, "In create_core(): unable to find the JSON key \"immediate_width\".\n");
        free(core->architecture);
        free(core);
        return NULL;
    }
    core->immediate_width = (uint8_t)ret;
    if ((ret = get_integer_parameter(core_json, "mm_instruction_width")) < 0) {
        fprintf(stderr, "In create_core(): unable to find the JSON key \"mm_instruction_width\".\n");
        free(core->architecture);
        free(core);
        return NULL;
    }
    core->mm_instruction_width = (uint8_t)ret;
    if ((ret = get_integer_parameter(core_json, "num_instructions")) < 0) {
        fprintf(stderr, "In create_core(): unable to find the JSON key \"num_instructions\".\n");
        free(core->architecture);
        free(core);
        return NULL;
    }
    core->num_instructions = (uint8_t)ret;
    if ((ret = get_integer_parameter(core_json, "num_predicates")) < 0) {
        fprintf(stderr, "In create_core(): unable to find the JSON key \"num_predicates\".\n");
        free(core->architecture);
        free(core);
        return NULL;
    }
    core->num_predicates = (uint8_t)ret;
    if ((ret = get_integer_parameter(core_json, "num_registers")) < 0) {
        fprintf(stderr, "In create_core(): unable to find the JSON key \"num_registers\".\n");
        free(core->architecture);
        free(core);
        return NULL;
    }
    core->num_registers = (uint8_t)ret;
    if ((ret = get_integer_parameter(core_json, "has_multiplier")) < 0) {
        fprintf(stderr, "In create_core(): unable to find the JSON key \"has_multiplier\".\n");
        free(core->architecture);
        free(core);
        return NULL;
    }
    core->has_multiplier = (bool)ret;
    if ((ret = get_integer_parameter(core_json, "has_two_word_product_multiplier")) < 0) {
        fprintf(stderr, "In create_core(): unable to find the JSON key \"has_two_word_product_multiplier\".\n");
        free(core->architecture);
        free(core);
        return NULL;
    }
    core->has_two_word_product_multiplier = (bool)ret;
    if ((ret = get_integer_parameter(core_json, "has_scratchpad")) < 0) {
        fprintf(stderr, "In create_core(): unable to find the JSON key \"has_scratchpad\".\n");
        free(core->architecture);
        free(core);
        return NULL;
    }
    core->has_scratchpad = (bool)ret;
    if ((ret = get_integer_parameter(core_json, "num_scratchpad_words")) < 0) {
        fprintf(stderr, "In create_core(): unable to find the JSON key \"num_scratchpad_words\".\n");
        free(core->architecture);
        free(core);
        return NULL;
    }
    core->num_scratchpad_words = (uint16_t)ret;
    if ((ret = get_integer_parameter(core_json, "latch_based_instruction_memory")) < 0) {
        fprintf(stderr, "In create_core(): unable to find the JSON key \"latch_based_instruction_memory\".\n");
        free(core->architecture);
        free(core);
        return NULL;
    }
    core->latch_based_instruction_memory = (bool)ret;
    if ((ret = get_integer_parameter(core_json, "ram_based_immediate_storage")) < 0) {
        fprintf(stderr, "In create_core(): unable to find the JSON key \"ram_based_immediate_storage\".\n");
        free(core->architecture);
        free(core);
        return NULL;
    }
    core->ram_based_immediate_storage = (bool)ret;
    if ((ret = get_integer_parameter(core_json, "num_input_channels")) < 0) {
        fprintf(stderr, "In create_core(): unable to find the JSON key \"num_input_channels\".\n");
        free(core->architecture);
        free(core);
        return NULL;
    }
    core->num_input_channels = (uint8_t)ret;
    if ((ret = get_integer_parameter(core_json, "num_output_channels")) < 0) {
        fprintf(stderr, "In create_core(): unable to find the JSON key \"num_output_channels\".\n");
        free(core->architecture);
        free(core);
        return NULL;
    }
    core->num_output_channels = (uint8_t)ret;
    if ((ret = get_integer_parameter(core_json, "channel_buffer_depth")) < 0) {
        fprintf(stderr, "In create_core(): unable to find the JSON key \"channel_buffer_depth\".\n");
        free(core->architecture);
        free(core);
        return NULL;
    }
    core->channel_buffer_depth = (uint8_t)ret;
    if ((ret = get_integer_parameter(core_json, "max_num_input_channels_to_check")) < 0) {
        fprintf(stderr, "In create_core(): unable to find the JSON key \"max_num_input_channels_to_check\".\n");
        free(core->architecture);
        free(core);
        return NULL;
    }
    core->max_num_input_channels_to_check = (uint8_t)ret;
    if ((ret = get_integer_parameter(core_json, "num_tags")) < 0) {
        fprintf(stderr, "In create_core(): unable to find the JSON key \"num_tags\".\n");
        free(core->architecture);
        free(core);
        return NULL;
    }
    core->num_tags = (uint8_t)ret;
    if ((ret = get_integer_parameter(core_json, "has_speculative_predicate_unit")) < 0) {
        fprintf(stderr, "In create_core(): unable to find the JSON key \"has_speculative_predicate_unit\".\n");
        free(core->architecture);
        free(core);
        return NULL;
    }
    core->has_speculative_predicate_unit = (bool)ret;
    if ((ret = get_integer_parameter(core_json, "has_effective_queue_status")) < 0) {
        fprintf(stderr, "In create_core(): unable to find the JSON key \"has_effective_queue_status\".\n");
        free(core->architecture);
        free(core);
        return NULL;
    }
    core->has_effective_queue_status = (bool)ret;
    if ((ret = get_integer_parameter(core_json, "has_debug_monitor")) < 0) {
        fprintf(stderr, "In create_core(): unable to find the JSON key \"has_debug_monitor\".\n");
        free(core->architecture);
        free(core);
        return NULL;
    }
    core->has_debug_monitor = (bool)ret;
    if ((ret = get_integer_parameter(core_json, "has_performance_counters")) < 0) {
        fprintf(stderr, "In create_core(): unable to find the JSON key \"has_performance_counters\".\n");
        free(core->architecture);
        free(core);
        return NULL;
    }
    core->has_performance_counters = (bool)ret;

    // Return the complete structure.
    return core;
}

void destroy_core(core_t *core)
{
    // Free the architecture string and then the remainder of the structure.
    free(core->architecture);
    free(core);
}

interconnect_t *create_interconnect(cJSON *interconnect_json)
{
    interconnect_t *interconnect;
    int ret;
    char *string_parameter;

    // Allocate an interconnect structure.
    if ((interconnect = (interconnect_t *)malloc(sizeof(interconnect_t))) == NULL) {
        perror("malloc");
        fprintf(stderr, "In create_interconnect(): failed to allocate memory for the interconnect structure.\n");
        return NULL;
    }

    // Copy the router_type_string over;
    if ((string_parameter = get_string_parameter(interconnect_json, "router_type")) == NULL) {
        fprintf(stderr, "In create_interconnect(): unable to find the JSON key \"router_type\".\n");
        free(interconnect);
        return NULL;
    }
    if ((interconnect->router_type = (char *)malloc((strlen(string_parameter) + 1) * sizeof(char))) == NULL) {
        perror("malloc");
        fprintf(stderr, "In create_interconnect(): failed to allocate the router string for the interconnect.\n");
        free(interconnect);
        return NULL;
    }
    strcpy(interconnect->router_type, string_parameter);

    // Fill in the remaining fields.
    if ((ret = get_integer_parameter(interconnect_json, "num_router_sources")) < 0) {
        fprintf(stderr, "In create_interconnect(): unable to find the JSON key \"num_router_sources\".\n");
        free(interconnect->router_type);
        free(interconnect);
        return NULL;
    }
    interconnect->num_router_sources = (uint8_t)ret;
    if ((ret = get_integer_parameter(interconnect_json, "num_router_destinations")) < 0) {
        fprintf(stderr, "In create_interconnect(): unable to find the JSON key \"num_router_destinations\".\n");
        free(interconnect->router_type);
        free(interconnect);
        return NULL;
    }
    interconnect->num_router_destinations = (uint8_t)ret;
    if ((ret = get_integer_parameter(interconnect_json, "num_input_channels")) < 0) {
        fprintf(stderr, "In create_interconnect(): unable to find the JSON key \"num_input_channels\".\n");
        free(interconnect->router_type);
        free(interconnect);
        return NULL;
    }
    interconnect->num_input_channels = (uint8_t)ret;
    if ((ret = get_integer_parameter(interconnect_json, "num_output_channels")) < 0) {
        fprintf(stderr, "In create_interconnect(): unable to find the JSON key \"num_output_channels\".\n");
        free(interconnect->router_type);
        free(interconnect);
        return NULL;
    }
    interconnect->num_output_channels = (uint8_t)ret;
    if ((ret = get_integer_parameter(interconnect_json, "router_buffer_depth")) < 0) {
        fprintf(stderr, "In create_interconnect(): unable to find the JSON key \"router_buffer_depth\".\n");
        free(interconnect->router_type);
        free(interconnect);
        return NULL;
    }
    interconnect->router_buffer_depth = (uint8_t)ret;
    if ((ret = get_integer_parameter(interconnect_json, "num_physical_planes")) < 0) {
        fprintf(stderr, "In create_interconnect(): unable to find the JSON key \"num_physical_planes\".\n");
        free(interconnect->router_type);
        free(interconnect);
        return NULL;
    }
    interconnect->num_physical_planes = (uint8_t)ret;

    // Return the complete structure.
    return interconnect;
}

void destroy_interconnect(interconnect_t *interconnect)
{
    // Free the type string and then the remainder of the structure.
    free(interconnect->router_type);
    free(interconnect);
}

system_t *create_system(cJSON *system_json)
{
    system_t *system;
    int ret;

    // Allocate a system structure.
    if ((system = (system_t *)malloc(sizeof(system_t))) == NULL) {
        perror("malloc");
        fprintf(stderr, "In create_system(): failed to allocate memory for the system structure.\n");
        return NULL;
    }

    // Fill in all the fields.
    if ((ret = get_integer_parameter(system_json, "host_word_width")) < 0) {
        fprintf(stderr, "In create_system(): unable to find the JSON key \"host_word_width\".\n");
        free(system);
        return NULL;
    }
    system->host_word_width = (uint8_t)ret;
    if ((ret = get_integer_parameter(system_json, "num_test_data_memory_words")) < 0) {
        fprintf(stderr, "In create_system(): unable to find the JSON key \"num_test_data_memory_words\".\n");
        free(system);
        return NULL;
    }
    system->num_test_data_memory_words = (uint32_t)ret;
    if ((ret = get_integer_parameter(system_json, "test_data_memory_buffer_depth")) < 0) {
        fprintf(stderr, "In create_system(): unable to find the JSON key \"test_data_memory_buffer_depth\".\n");
        free(system);
        return NULL;
    }
    system->test_data_memory_buffer_depth = (uint8_t)ret;

    // Return the complete structure.
    return system;
}

void destroy_system(system_t *system)
{
    // Only one layer.
    free(system);
}

platform_t *create_platform(char *platform_string)
{
    cJSON *platform_json, *core_json, *interconnect_json, *system_json;
    core_t *core;
    interconnect_t *interconnect;
    system_t *system;
    platform_t *platform;

    // Parse the JSON string.
    platform_json = cJSON_Parse(platform_string);
    if (platform_json == NULL) {
        fprintf(stderr, "In create_platform(): JSON parse error.\n");
        return NULL;
    }

    // Create a core structure.
    core_json = cJSON_GetObjectItem(platform_json, "core");
    if (core_json == NULL) {
        fprintf(stderr, "In create_platform(): unable to find JSON header \"core\".\n");
        cJSON_Delete(platform_json);
        return NULL;
    }
    core = create_core(core_json);
    if (core == NULL) {
        fprintf(stderr, "In create_platform(): call to create_core() failed.\n");
        cJSON_Delete(platform_json);
        return NULL;
    }

    // Create an interconnect structure.
    interconnect_json = cJSON_GetObjectItem(platform_json, "interconnect");
    if (interconnect_json == NULL) {
        fprintf(stderr, "In create_platform(): unable to find JSON head \"interconnect\".\n");
        destroy_core(core);
        cJSON_Delete(platform_json);
        return NULL;
    }
    interconnect = create_interconnect(interconnect_json);
    if (interconnect == NULL) {
        fprintf(stderr, "In create_platform(): call to create_interconnect() failed.\n");
        destroy_core(core);
        cJSON_Delete(platform_json);
        return NULL;
    }

    // Create a system structure.
    system_json = cJSON_GetObjectItem(platform_json, "system");
    if (system_json == NULL) {
        fprintf(stderr, "In create_platform(): unable to find JSON header \"system\".\n");
        destroy_interconnect(interconnect);
        destroy_core(core);
        cJSON_Delete(platform_json);
        return NULL;
    }
    system = create_system(system_json);
    if (system == NULL) {
        fprintf(stderr, "In create_platform(): call to create_system() failed.\n");
        destroy_interconnect(interconnect);
        destroy_core(core);
        cJSON_Delete(platform_json);
        return NULL;
    }

    // Fill in the top-level structure.
    if ((platform = (platform_t *)malloc(sizeof(platform_t))) == NULL) {
        perror("malloc");
        fprintf(stderr, "In create_platform(): failed to allocate memory for the platform structure.\n");
        destroy_system(system);
        destroy_interconnect(interconnect);
        destroy_core(core);
        cJSON_Delete(platform_json);
        return NULL;
    }
    platform->core = core;
    platform->interconnect = interconnect;
    platform->system = system;

    // Clean up the JSON object.
    cJSON_Delete(platform_json);

    // Return the platform.
    return platform;
}

void destroy_platform(platform_t *platform) {
    // Call the individual fields' destructors and free the wrapper structure.
    destroy_core(platform->core);
    destroy_interconnect(platform->interconnect);
    destroy_system(platform->system);
    free(platform);
}
