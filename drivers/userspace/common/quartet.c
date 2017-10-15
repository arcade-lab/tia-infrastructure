#include "quartet.h"

int initialize_quartet(quartet_t *quartet, volatile uint32_t *quartet_base_address, platform_t *platform)
{
    volatile uint32_t *processing_element_base_address;
    size_t i;

    // The processing element address spaces are contiguous.
    processing_element_base_address = quartet_base_address;

    // Initialize each processing element, iterating through the respective base addresses.
    initialize_processing_element(&quartet->processing_elements[0],
                                  &processing_element_base_address[0],
                                  platform);
    for (i = 1; i < 4; i++) {
        initialize_processing_element(&quartet->processing_elements[i],
                                      &processing_element_base_address[i * quartet->processing_elements[0].num_address_space_words],
                                      platform);
    }

    // Determine the total size of the quartet address space.
    quartet->num_address_space_words = 4 * quartet->processing_elements[0].num_address_space_words;

    // Successful, if reached.
    return 0;
}
