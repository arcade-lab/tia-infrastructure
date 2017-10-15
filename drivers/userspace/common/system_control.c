#include "system_control.h"

int initialize_system_control(system_control_t *system_control,
                              volatile uint32_t *system_control_base_address)
{
    size_t base_index;

    // Four control registers.
    system_control->num_system_control_register_words = 4;
    base_index = 0;
    system_control->reset_reg = &system_control_base_address[base_index];
    system_control->enable_reg = &system_control_base_address[base_index + 1];
    system_control->execute_reg = &system_control_base_address[base_index + 2];
    system_control->halted_reg = &system_control_base_address[base_index + 3];

    // Default to success.
    return 0;
}

void reset_system(system_control_t *system_control)
{
    // We may want to add a pause here.
    *(system_control->reset_reg) = 1;
    *(system_control->reset_reg) = 0;
}

void enable_system(system_control_t *system_control)
{
    // Leave enabled.
    *(system_control->enable_reg) = 1;
}

void disable_system(system_control_t *system_control)
{
    // Leave disabled.
    *(system_control->enable_reg) = 0;
}

void begin_execution(system_control_t *system_control)
{
    // Leave executing.
    *(system_control->execute_reg) = 1;
}

void pause_execution(system_control_t *system_control)
{
    // Leave paused.
    *(system_control->execute_reg) = 0;
}

bool system_halted(system_control_t *system_control)
{
    // Return whether the system is halted.
    return (bool)*(system_control->halted_reg);
}

