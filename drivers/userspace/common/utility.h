#ifndef UTILITY_H
#define UTILITY_H

#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>

// Data I/0 and checking.
int write_input_data(volatile uint32_t *data_memory_base_address, size_t input_data_index, size_t num_input_data_words,
                     uint32_t *input_data);
void retrieve_output_data(volatile uint32_t *data_memory_base_address, size_t output_data_index,
                          size_t num_output_data_words, uint32_t *output_data);
bool output_data_matches(size_t num_output_data_words, uint32_t *output_data, uint32_t *expected_output_data);

#endif // UTILITY_H
