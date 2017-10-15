#ifndef QUARTET_H
#define QUARTET_H

#include <stdint.h>

#include "platform.h"
#include "processing_element.h"

// The quartet access data structure just wraps the constituent processing elements.
typedef struct quartet {
    // Substructures.
    processing_element_t processing_elements[4];

    // Address space.
    size_t num_address_space_words;
} quartet_t;

// Initialization.
int initialize_quartet(quartet_t *quartet, volatile uint32_t *quartet_base_address, platform_t *platform);

#endif
