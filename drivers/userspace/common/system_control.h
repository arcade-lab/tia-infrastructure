#ifndef SYSTEM_CONTROL_H
#define SYSTEM_CONTROL_H

#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>

// Access data structure.
typedef struct system_control {
    // Control registers.
    size_t num_system_control_register_words;
    volatile uint32_t *reset_reg,
                      *enable_reg,
                      *execute_reg,
                      *halted_reg;
} system_control_t;

// Register access functions.
int initialize_system_control(system_control_t *system_control,
                              volatile uint32_t *system_control_base_address);
void reset_system(system_control_t *system_control);
void enable_system(system_control_t *system_control);
void disable_system(system_control_t *system_control);
void begin_execution(system_control_t *system_control);
void pause_execution(system_control_t *system_control);
bool system_halted(system_control_t *system_control);

#endif // SYSTEM_CONTROL_H
