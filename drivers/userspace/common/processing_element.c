#include "processing_element.h"

// --- Initialization ---

int initialize_processing_element(processing_element_t *processing_element,
                                  volatile uint32_t *processing_element_base_address,
                                  platform_t *platform)
{
    // Cursor for base indices with various options enabled/disabled.
    size_t base_index;

    // --- Register File Size ---

    // Determine size.
    processing_element->num_registers = platform->core->num_registers;

    // --- Monitor ---

    // Access to the debug monitor.
    base_index = 0;
    if (platform->core->has_debug_monitor) {
        processing_element->num_debug_monitor_words = NUM_DEBUG_MONITOR_REGISTERS + platform->core->num_registers;
        processing_element->num_predicates = platform->core->num_predicates;
        processing_element->halted_reg = &processing_element_base_address[base_index];
        processing_element->predicates_reg = &processing_element_base_address[base_index + 1];
        processing_element->registers_monitor = &processing_element_base_address[base_index + 2];
    } else {
        // Default to NULL for initalization checks.
        processing_element->num_debug_monitor_words = 0;
        processing_element->num_predicates = 0;
        processing_element->halted_reg = NULL;
        processing_element->predicates_reg = NULL;
        processing_element->registers_monitor = NULL;
    }
    base_index += processing_element->num_debug_monitor_words;

    // --- Performance Counters ---

    // Access to the performance counters.
    if (platform->core->has_performance_counters) {
        processing_element->num_performance_counter_words = NUM_PERFORMANCE_COUNTERS_WORDS;
        processing_element->executed_cycles_counter_reg = &processing_element_base_address[base_index];
        processing_element->instructions_issued_counter_reg = &processing_element_base_address[base_index + 1];
        processing_element->instructions_retired_counter_reg = &processing_element_base_address[base_index + 2];
        processing_element->instructions_quashed_counter_reg = &processing_element_base_address[base_index + 3];
        processing_element->untriggered_cycles_counter_reg = &processing_element_base_address[base_index + 4];
        processing_element->bubbles_counter_reg = &processing_element_base_address[base_index + 5];
        processing_element->control_hazard_bubbles_counter_reg = &processing_element_base_address[base_index + 6];
        processing_element->data_hazard_bubbles_counter_reg = &processing_element_base_address[base_index + 7];
        processing_element->predicate_prediction_hits_counter_reg = &processing_element_base_address[base_index + 8];
        processing_element->predicate_prediction_misses_counter_reg = &processing_element_base_address[base_index + 9];
        processing_element->trigger_overrides_counter_reg = &processing_element_base_address[base_index + 10];
        processing_element->multi_cycle_instruction_stalls_counter_reg = &processing_element_base_address[base_index + 11];
        processing_element->pipeline_latency_reg = &processing_element_base_address[base_index + 12];
    } else {
        processing_element->num_performance_counter_words = 0;
        processing_element->executed_cycles_counter_reg = NULL;
        processing_element->instructions_issued_counter_reg = NULL;
        processing_element->instructions_retired_counter_reg = NULL;
        processing_element->instructions_quashed_counter_reg = NULL;
        processing_element->untriggered_cycles_counter_reg = NULL;
        processing_element->bubbles_counter_reg = NULL;
        processing_element->control_hazard_bubbles_counter_reg = NULL;
        processing_element->data_hazard_bubbles_counter_reg = NULL;
        processing_element->predicate_prediction_hits_counter_reg = NULL;
        processing_element->predicate_prediction_misses_counter_reg = NULL;
        processing_element->trigger_overrides_counter_reg = NULL;
        processing_element->multi_cycle_instruction_stalls_counter_reg = NULL;
        processing_element->pipeline_latency_reg = NULL;
    }
    base_index += processing_element->num_performance_counter_words;

    // --- Register File ---

    // Grant access to the register file for inialization.
    processing_element->registers_initialization = &processing_element_base_address[base_index];
    base_index += processing_element -> num_registers;

    // --- Instruction Memory ---

    // Initialize the instruction memory.
    processing_element->instructions = &processing_element_base_address[base_index];
    processing_element->num_instruction_words = platform->core->num_instructions
                                                * platform->core->mm_instruction_width
                                                / platform->system->host_word_width;
    base_index += platform->core->num_instructions
                  * platform->core->mm_instruction_width
                  / platform->system->host_word_width;

    // --- Scratchpad Memory ---

    // Initialize the scratchpad pointer.
    if (platform->core->has_scratchpad) {
        processing_element->num_scratchpad_words = platform->core->num_scratchpad_words;
        processing_element->scratchpad = &processing_element_base_address[base_index];
    } else {
        processing_element->num_scratchpad_words = 0;
        processing_element->scratchpad = NULL;
    }
    base_index += processing_element->num_scratchpad_words;

    // Initialize the router settings pointer.
    if (strcmp(platform->interconnect->router_type, "software") == 0) {
        processing_element->num_router_setting_memory_words = 0;
        processing_element->router_setting_memory = NULL;
    } else if (strcmp(platform->interconnect->router_type, "switch") == 0) {
        processing_element->num_router_setting_memory_words = 1 + platform->interconnect->num_physical_planes;
        processing_element->router_setting_memory = &processing_element_base_address[base_index];
    } else {
        return 1;
    }

    // Determine the total size of the processing element address space.
    processing_element->num_address_space_words = processing_element->num_debug_monitor_words
                                                  + processing_element->num_performance_counter_words
                                                  + processing_element->num_registers
                                                  + processing_element->num_instruction_words
                                                  + processing_element->num_scratchpad_words
                                                  + processing_element->num_router_setting_memory_words;

    // Exit successfully.
    return 0;
}

// --- Register Access ---

uint8_t processing_element_halted(processing_element_t *processing_element)
{
    // Guard against invalid accesses.
    if (processing_element->halted_reg != NULL)
        return (uint8_t)*processing_element->halted_reg;
    else
        return 0;
}

uint32_t processing_element_predicates(processing_element_t *processing_element)
{
    // Guard against invalid accesses.
    if (processing_element->predicates_reg != NULL)
        return *processing_element->predicates_reg;
    else
        return 0;
}

uint32_t monitor_register_file(size_t register_index, processing_element_t *processing_element)
{
    // Guard against invalid accesses.
    if (processing_element->registers_monitor != NULL)
        return *(processing_element->registers_monitor + register_index);
    else
        return 0;
}

uint32_t executed_cycles_counter(processing_element_t *processing_element)
{
    // Guard against invalid accesses.
    if (processing_element->executed_cycles_counter_reg != NULL)
        return *processing_element->executed_cycles_counter_reg;
    else
        return 0;
}

uint32_t instructions_issued_counter(processing_element_t *processing_element)
{
    // Guard against invalid accesses.
    if (processing_element->instructions_issued_counter_reg != NULL)
        return *processing_element->instructions_issued_counter_reg;
    else
        return 0;
}

uint32_t instructions_retired_counter(processing_element_t *processing_element)
{
    // Guard against invalid accesses.
    if (processing_element->instructions_retired_counter_reg != NULL)
        return *processing_element->instructions_retired_counter_reg;
    else
        return 0;
}

uint32_t instructions_quashed_counter(processing_element_t *processing_element)
{
    // Guard against invalid accesses.
    if (processing_element->instructions_quashed_counter_reg != NULL)
        return *processing_element->instructions_quashed_counter_reg;
    else
        return 0;
}

uint32_t untriggered_cycles_counter(processing_element_t *processing_element)
{
    // Guard against invalid accesses.
    if (processing_element->untriggered_cycles_counter_reg != NULL)
        return *processing_element->untriggered_cycles_counter_reg;
    else
        return 0;
}

uint32_t bubbles_counter(processing_element_t *processing_element)
{
    // Guard against invalid accesses.
    if (processing_element->bubbles_counter_reg != NULL)
        return *processing_element->bubbles_counter_reg;
    else
        return 0;
}

uint32_t control_hazard_bubbles_counter(processing_element_t *processing_element)
{
    // Guard against invalid accesses.
    if (processing_element->control_hazard_bubbles_counter_reg != NULL)
        return *processing_element->control_hazard_bubbles_counter_reg;
    else
        return 0;
}

uint32_t data_hazard_bubbles_counter(processing_element_t *processing_element)
{
    // Guard against invalid accesses.
    if (processing_element->data_hazard_bubbles_counter_reg != NULL)
        return *processing_element->data_hazard_bubbles_counter_reg;
    else
        return 0;
}

uint32_t predicate_prediction_hits_counter(processing_element_t *processing_element)
{
    // Guard against invalid accesses.
    if (processing_element->predicate_prediction_hits_counter_reg != NULL)
        return *processing_element->predicate_prediction_hits_counter_reg;
    else
        return 0;
}

uint32_t predicate_prediction_misses_counter(processing_element_t *processing_element)
{
    // Guard against invalid accesses.
    if (processing_element->predicate_prediction_misses_counter_reg != NULL)
        return *processing_element->predicate_prediction_misses_counter_reg;
    else
        return 0;
}

uint32_t trigger_overrides_counter(processing_element_t *processing_element)
{
    // Guard against invalid accesses.
    if (processing_element->predicate_prediction_misses_counter_reg != NULL)
        return *processing_element->predicate_prediction_misses_counter_reg;
    else
        return 0;
}

uint32_t multi_cycle_instruction_stalls_counter(processing_element_t *processing_element)
{
    // Guard against invalid accesses.
    if (processing_element->multi_cycle_instruction_stalls_counter_reg != NULL)
        return *processing_element->multi_cycle_instruction_stalls_counter_reg;
    else
        return 0;
}

uint32_t pipeline_latency(processing_element_t *processing_element)
{
    // Guard against invalid accesses.
    if (processing_element->pipeline_latency_reg != NULL)
        return *processing_element->pipeline_latency_reg;
    else
        return 0;
}

// --- Memory Access ---

int initialize_registers(processing_element_t *processing_element, uint32_t *write_data)
{
    size_t i;

    // Make sure that we have register file access.
    if (processing_element->registers_initialization == NULL)
        return -1;

    // Write the register data into the register file.
    for (i = 0; i < processing_element->num_registers; i++)
        processing_element->registers_initialization[i] = write_data[i];

    // Successful if reached.
    return 0;
}

int clear_processing_element_instructions(processing_element_t *processing_element)
{
    size_t i;

    // Make sure that we have instruction memory access.
    if (processing_element->instructions == NULL)
        return -1;

    // Clear the instruction memory.
    for (i = 0; i < processing_element->num_instruction_words; i++)
        processing_element->instructions[i] = 0;

    // Successful if reached.
    return 0;
}

int write_to_processing_element_instructions(processing_element_t *processing_element, uint32_t *write_data)
{
    size_t i;

    // Make sure that we have instruction memory access.
    if (processing_element->instructions == NULL)
        return -1;

    // Write out the data to instruction memory.
    for (i = 0; i < processing_element->num_instruction_words; i++)
        processing_element->instructions[i] = write_data[i];

    // Successful if reached.
    return 0;
}

int write_processing_element_program(processing_element_t *processing_element, uint32_t *write_data)
{
    int ret;

    // Initialize the register file.
    if ((ret = initialize_registers(processing_element, write_data)) < 0)
        return ret;

    // Increment the source pointer.
    write_data = &write_data[processing_element->num_registers];

    // Write out the instruction data.
    if ((ret = write_to_processing_element_instructions(processing_element, write_data)) < 0)
        return ret;

    // Successful if reached.
    return 0;
}

int clear_processing_element_scratchpad(processing_element_t *processing_element)
{
    size_t i;

    // Make sure we have scratchpad memory access.
    if (processing_element->scratchpad == NULL)
       return -1;

    // Clear the scratchpad memory.
    for (i = 0; i < processing_element->num_scratchpad_words; i++)
        processing_element->scratchpad[i] = 0;

    // Successful if reached.
    return 0;
}

int write_to_processing_element_scratchpad(processing_element_t *processing_element, uint32_t *write_data)
{
    size_t i;

    // Make sure we have scratchpad memory access.
    if (processing_element->scratchpad == NULL)
       return -1;

    // Write out the data to the scratchpad memory.
    for (i = 0; i < processing_element->num_scratchpad_words; i++)
        processing_element->scratchpad[i] = write_data[i];

    // Successful if reached.
    return 0;
}

int clear_processing_element_router_setting_memory(processing_element_t *processing_element)
{
    size_t i;

    // Make sure we have router setting memory access.
    if (processing_element->router_setting_memory == NULL)
        return -1;

    // Clear the router setting memory.
    for (i = 0; i < processing_element->num_router_setting_memory_words; i++)
        processing_element->router_setting_memory[i] = 0;

    // Successful if reached.
    return 0;
}

int write_to_processing_element_router_setting_memory(processing_element_t *processing_element, uint32_t *write_data)
{
    size_t i;

    // Make sure we have router setting memory access.
    if (processing_element->router_setting_memory == NULL)
        return -1;

    // Clear the router setting memory.
    for (i = 0; i < processing_element->num_router_setting_memory_words; i++)
        processing_element->router_setting_memory[i] = write_data[i];

    // Successful if reached.
    return 0;
}


// --- Display ---

void display_debug_info(processing_element_t *processing_element)
{
    uint32_t halted_reg, predicates_reg, temp, current_register;
    int i;
    size_t j;

    // Access and display debug information.
    halted_reg = (uint32_t)processing_element_halted(processing_element);
    fprintf(stderr, "halted: %u\n", halted_reg);
    predicates_reg = processing_element_predicates(processing_element);
    fprintf(stderr, "predicates: ");
    for (i = processing_element->num_predicates - 1; i >= 0; i--) {
        temp = (predicates_reg >> i) & 0x1;
        fprintf(stderr, "%u", temp);
    }
    fprintf(stderr, "\n");
    fprintf(stderr, "registers:\n");
    for (j = 0; j < processing_element->num_registers; j++) {
        current_register = monitor_register_file(j, processing_element);
        fprintf(stderr, "%2zu: 0x%08x\n", j, current_register);
    }
}
