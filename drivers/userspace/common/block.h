#ifndef BLOCK_H
#define BLOCK_H

#include <stdint.h>

#include "platform.h"
#include "quartet.h"

// The block access data structure just wraps the constiutent quartets.
typedef struct block {
    quartet_t quartets[4];

    // Address space.
    size_t num_address_space_words;
} block_t;

// Initialization.
int initialize_block(block_t *block, volatile uint32_t *block_base_address, platform_t *platform);

// Processing element access.
processing_element_t *get_logical_processing_element(block_t *block, size_t processing_element_index);

#endif
