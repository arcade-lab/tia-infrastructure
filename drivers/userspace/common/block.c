#include "block.h"

int initialize_block(block_t *block, volatile uint32_t *block_base_address, platform_t *platform)
{
    volatile uint32_t *quartet_base_address;
    size_t i;

    // The quartet address spaces are contiguous.
    quartet_base_address = block_base_address;

    // Initialize each quartet, iterating through the respective base address.
    initialize_quartet(&block->quartets[0],
                       &quartet_base_address[0],
                       platform);
    for (i = 1; i < 4; i++) {
        initialize_quartet(&block->quartets[i],
                           &block_base_address[i * block->quartets[0].num_address_space_words],
                           platform);
    }

    // Determine the total size of the block address space.
    block->num_address_space_words = 4 * block->quartets[0].num_address_space_words;

    // Successful, if reached.
    return 0;
}

processing_element_t *get_logical_processing_element(block_t *block, size_t processing_element_index)
{
    size_t block_row, block_column, quartet_index, quartet_row, quartet_column, processing_element_subindex;
    quartet_t *quartet;
    processing_element_t *processing_element;

    // Check for invalid indices.
    if (processing_element_index >= 16)
        return NULL;

    // Determine the row and column within the block.
    block_row = processing_element_index / 4;
    block_column = processing_element_index % 4;

    // Determine which quartet the processing element is in.
    quartet_index = 2 * (block_row / 2) + (block_column / 2);

    // Determine the row and oclumn within the
    quartet_row = block_row % 2;
    quartet_column = block_column % 2;

    // Determine the index of the processing element within the quartet.
    processing_element_subindex = 2 * quartet_row + quartet_column;

    // Look up the quartet and processing element.
    quartet = &block->quartets[quartet_index];
    processing_element = &quartet->processing_elements[processing_element_subindex];

    // Return a pointer to the processing element associated with the original logical index.
    return processing_element;
}
