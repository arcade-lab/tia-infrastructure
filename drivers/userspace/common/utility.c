#include "utility.h"

// --- Data I/0 and Checking ---

int write_input_data(volatile uint32_t *data_memory_base_address, size_t input_data_index, size_t num_input_data_words,
                     uint32_t *input_data)
{
    size_t i;

    // Write the data.
    for (i = 0; i < num_input_data_words; i++)
        data_memory_base_address[i + input_data_index] = input_data[i];

    // Make sure the write to physical memory took effect.
    for (i = 0; i < num_input_data_words; i++)
        if (data_memory_base_address[i + input_data_index] != input_data[i])
            return -1;

    // Successful, if reached.
    return 0;
}

void retrieve_output_data(volatile uint32_t *data_memory_base_address, size_t output_data_index,
                          size_t num_output_data_words, uint32_t *output_data)
{
    size_t i;

    // Retrieve the data.
    for (i = 0; i < num_output_data_words; i++)
        output_data[i] = data_memory_base_address[i + output_data_index];
}

bool output_data_matches(size_t num_output_data_words, uint32_t *output_data, uint32_t *expected_output_data)
{
    size_t i;

    // Make sure the two match.
    for (i = 0; i < num_output_data_words; i++)
        if (output_data[i] != expected_output_data[i])
            return false;

    // Successful, if reached.
    return true;
}
