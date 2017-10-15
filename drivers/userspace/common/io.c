#include "io.h"

char *allocate_and_read_character_data(const char *file_name)
{
    FILE *file;
    int file_length;
    char *data;

    // Open the file.
    if ((file = fopen(file_name, "r")) == NULL) {
        perror("fopen");
        fprintf(stderr, "%s\n", file_name);
        return NULL;
    }

    // Allocate space for and read the contents of the file.
    if (fseek(file, 0, SEEK_END) != 0) {
        perror("fseek");
        return NULL;
    }
    if ((file_length = ftell(file)) < 0) {
        perror("ftell");
        return NULL;
    }
    if ((data = (char *)malloc(file_length * sizeof(char))) == NULL) {
        perror("malloc");
        return NULL;
    }
    rewind(file);
    if (fread(data, sizeof(char), file_length, file) != (size_t)file_length) {
        fprintf(stderr, "Error: failed to read the file.\n");
        fprintf(stderr, "%s\n", file_name);
        return NULL;
    }

    // Close the file.
    if (fclose(file) == EOF) {
        perror("fclose");
        fprintf(stderr, "%s\n", file_name);
        return NULL;
    }

    // Return the data read.
    return data;
}

uint32_t *allocate_and_read_binary_data(const char *file_name, size_t expected_num_words, size_t *num_words_read)
{
    uint8_t check_length;
    FILE *file;
    int file_length;
    uint32_t *data;

    // We only check the if the passed parameter is strictly positive.
    check_length = (expected_num_words > 0);

    // Open the file.
    if ((file = fopen(file_name, "r")) == NULL) {
        perror("fopen");
        fprintf(stderr, "%s\n", file_name);
        return NULL;
    }

    // Allocate space for and read the contents of the file.
    if (fseek(file, 0, SEEK_END) != 0) {
        perror("fseek");
        return NULL;
    }
    if ((file_length = ftell(file)) < 0) {
        perror("ftell");
        return NULL;
    }
    if (file_length % 4 != 0) {
        fprintf(stderr, "Binary data is expected to be stored in multiples of 32-bit words.\n");
        fprintf(stderr, "%s\n", file_name);
        return NULL;
    }
    if (check_length && (size_t)(file_length / 4) != expected_num_words) {
        fprintf(stderr, "The file does not match the expected length.\n");
        fprintf(stderr, "%s\n", file_name);
        return NULL;
    }
    if ((data = (uint32_t *)malloc((file_length / 4) * sizeof(uint32_t))) == NULL) {
        perror("malloc");
        return NULL;
    }
    rewind(file);
    if (fread(data, sizeof(uint32_t), file_length, file) != (size_t)(file_length / 4)) {
        fprintf(stderr, "Error: failed to read the file.\n");
        fprintf(stderr, "%s\n", file_name);
        return NULL;
    }

    // Close the file.
    if (fclose(file) == EOF) {
        perror("fclose");
        fprintf(stderr, "%s\n", file_name);
        return NULL;
    }

    // Save the number of words read, if requested.
    if (num_words_read != NULL)
        *num_words_read = (size_t)(file_length / 4);

    // Return the data read.
    return data;
}
