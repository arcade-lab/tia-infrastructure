#ifndef IO_H
#define IO_H

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

char *allocate_and_read_character_data(const char *file_name);
uint32_t *allocate_and_read_binary_data(const char *file_name, size_t expected_num_words, size_t *num_words_read);

#endif // IO_H
