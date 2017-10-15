#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <string.h>
#include <signal.h>

#include "system_control.h"
#include "processing_element.h"
#include "io.h"
#include "platform.h"
#include "utility.h"
#include "results.h"

// Interrupt flag.
bool interrupted = false;

// --- Hardcoded I/O Region Size ---

#define MMAP_SIZE (1024 * 1024)

// --- Signal Handler Utility Functions ---

int install_keyboard_interrupt_handler(void (*handler)(int)) {
    sigset_t old, full;
    struct sigaction action;

    // Create a new full signal mask.
    sigfillset(&full);
    sigprocmask(SIG_SETMASK, &full, &old);

    // Fill in the fields of the action.
    action.sa_handler = handler;
    sigfillset(&action.sa_mask);
    action.sa_flags = SA_RESTART;

    // Attempt to install the signal handler, and restore any old signal mask.
    if (sigaction(SIGINT, &action,  NULL) < 0)
        return -1;
    else {
        sigprocmask(SIG_SETMASK, &old, NULL);
        return 0;
    }
}

void keyboard_interrupt_handler(__attribute__((unused)) int dummy) {
    // Just set the interrupted flag.
    interrupted = true;
}

// --- Entry Point ---

int main(int argc, char **argv)
{
    char *platform_string, *results_json_string;
    platform_t *platform;
    uint32_t *program_binary, *scratchpad_data, *input_data, *expected_output_data, *output_data;
    size_t expected_num_program_binary_words, num_program_binary_words, num_scratchpad_data_words,
           num_input_data_words, num_expected_output_data_words;
    bool has_scratchpad_data, passed;
    int dev_uio0_fd, ret;
    volatile uint32_t *base_address, *system_control_base_address, *processing_element_base_address,
                      *data_memory_base_address;
    system_control_t system_control;
    processing_element_t processing_element;
    cJSON *results, *processing_element_results;

    // --- Argument Parsing and File I/O ---

    // Check usage.
    if (argc != 6) {
        fprintf(stderr, "Usage: ./pete PLATFORM_FILE PROGRAM_BINARY SCRATCHPAD_DATA INPUT_DATA EXPECTED_OUTPUT_DATA\n");
        return 1;
    }

    // Load the platform file.
    platform_string = allocate_and_read_character_data(argv[1]);
    if (platform_string == NULL) {
        fprintf(stderr, "Failed to read the platform file.\n");
        return 1;
    }
    platform = create_platform(platform_string);
    if (platform == NULL) {
        fprintf(stderr, "Failed to deserialize the platform information.\n");
        free(platform_string);
        return 1;
    }
    free(platform_string);

    // Load the program binary.
    expected_num_program_binary_words = platform->core->num_registers
                                        + platform->core->num_instructions
                                          * platform->core->mm_instruction_width
                                          / platform->system->host_word_width;
    program_binary = allocate_and_read_binary_data(argv[2],
                                                   expected_num_program_binary_words,
                                                   &num_program_binary_words);
    if (program_binary == NULL) {
        fprintf(stderr, "Failed to load a valid program binary.\n");
        if (num_program_binary_words != expected_num_program_binary_words)
            fprintf(stderr, "Invalid program binary size.\n");
        destroy_platform(platform);
        return 1;
    }

    // Load the scratchpad data, if required.
    has_scratchpad_data = (strcmp(argv[3], "null") != 0);
    if (has_scratchpad_data) {
        scratchpad_data = allocate_and_read_binary_data(argv[3],
                                                        platform->core->num_scratchpad_words,
                                                        &num_scratchpad_data_words);
        if (scratchpad_data == NULL) {
            fprintf(stderr, "Failed to load valid scratchpad data.\n");
            if (num_scratchpad_data_words != platform->core->num_scratchpad_words)
                fprintf(stderr, "Invalid scratchpad data file size.\n");
            free(program_binary);
            destroy_platform(platform);
            return 1;
        }
    } else
        scratchpad_data = NULL;

    // Load the input data.
    input_data = allocate_and_read_binary_data(argv[4], 0, &num_input_data_words);
    if (input_data == NULL) {
        fprintf(stderr, "Failed to load the input data.\n");
        if (has_scratchpad_data)
            free(scratchpad_data);
        free(program_binary);
        destroy_platform(platform);
        return 1;
    }

    // Load the expected output data.
    expected_output_data = allocate_and_read_binary_data(argv[5], 0, &num_expected_output_data_words);
    if (expected_output_data == NULL) {
        fprintf(stderr, "Failed to load the expected output data.\n");
        free(input_data);
        if (has_scratchpad_data)
            free(scratchpad_data);
        free(program_binary);
        destroy_platform(platform);
        return 1;
    }

    // Preallocate the retrieved output buffer.
    output_data = (uint32_t *)malloc(num_expected_output_data_words * sizeof(uint32_t));
    if (output_data == NULL) {
        perror("malloc");
        fprintf(stderr, "Failed to allocate an output data buffer.\n");
        free(expected_output_data);
        free(input_data);
        if (has_scratchpad_data)
            free(scratchpad_data);
        free(program_binary);
        destroy_platform(platform);
    }

    // --- Physical Memory Mapping ---

    // Open and mmap() /dev/uio0.
    dev_uio0_fd = open("/dev/uio0", O_RDWR | O_SYNC);
    if (dev_uio0_fd < 0) {
        perror("open");
        fprintf(stderr, "Failed to open /dev/uio0.\n");
        free(output_data);
        free(expected_output_data);
        free(input_data);
        if (has_scratchpad_data)
            free(scratchpad_data);
        free(program_binary);
        destroy_platform(platform);
        return 1;
    }
    base_address = (uint32_t *)mmap(0, MMAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, dev_uio0_fd, 0);
    if (base_address == NULL) {
        perror("mmap");
        fprintf(stderr, "Failed to mmap() /dev/uio0.\n");
        close(dev_uio0_fd);
        free(output_data);
        free(expected_output_data);
        free(input_data);
        if (has_scratchpad_data)
            free(scratchpad_data);
        free(program_binary);
        destroy_platform(platform);
        return 1;
    }

    // --- Access Structure Initialization ---

    // System control registers.
    system_control_base_address = base_address;
    initialize_system_control(&system_control, system_control_base_address);

    // Processing element.
    processing_element_base_address = &system_control_base_address[system_control.num_system_control_register_words];
    initialize_processing_element(&processing_element, processing_element_base_address, platform);

    // Data memory.
    data_memory_base_address = &processing_element_base_address[processing_element.num_address_space_words];

    // --- Programming and Setup ---

    // Start the device.
    reset_system(&system_control);
    enable_system(&system_control);

    // Program the device.
    ret = write_processing_element_program(&processing_element, program_binary);
    if (ret < 0) {
        fprintf(stderr, "Failed to write the program to the processing element instruction memory.\n");
        munmap((void *)base_address, MMAP_SIZE);
        close(dev_uio0_fd);
        free(output_data);
        free(expected_output_data);
        free(input_data);
        if (has_scratchpad_data)
            free(scratchpad_data);
        free(program_binary);
        destroy_platform(platform);
        return 1;
    }
    free(program_binary);

    // TODO: Make a real file after debug.
    // Write to the router setting memory, if needed.
    if (processing_element.num_router_setting_memory_words > 0) {
        uint32_t router_setting_memory[5] = {0x0b0a0908, 0x00002d24, 0x0, 0x0, 0x0};
        ret = write_to_processing_element_router_setting_memory(&processing_element, router_setting_memory);
        if (ret < 0) {
            fprintf(stderr, "Failed to write the router setting to the processing element router setting memory.\n");
            munmap((void *)base_address, MMAP_SIZE);
            close(dev_uio0_fd);
            free(output_data);
            free(expected_output_data);
            free(input_data);
            if (has_scratchpad_data)
                free(scratchpad_data);
            destroy_platform(platform);
            return 1;
        }
    }

    // Write scratchpad data, if needed.
    if (has_scratchpad_data) {
        ret = write_to_processing_element_scratchpad(&processing_element, scratchpad_data);
        if (ret < 0) {
            fprintf(stderr, "Failed to write the scratchpad data to the processing element local scratchpad.\n");
            munmap((void *)base_address, MMAP_SIZE);
            close(dev_uio0_fd);
            free(output_data);
            free(expected_output_data);
            free(input_data);
            free(scratchpad_data);
            destroy_platform(platform);
            return 1;
        }
    }
    free(scratchpad_data);

    // Load the input data into physical memory.
    ret = write_input_data(data_memory_base_address, 0, num_input_data_words, input_data);
    if (ret < 0) {
        fprintf(stderr, "Failed to write the input data to the data memory.\n");
        munmap((void *)base_address, MMAP_SIZE);
        close(dev_uio0_fd);
        free(output_data);
        free(expected_output_data);
        free(input_data);
        destroy_platform(platform);
        return 1;
    }
    free(input_data);

    // --- Signal Handling ---

    // Set the signal handler prior to execution.
    install_keyboard_interrupt_handler(keyboard_interrupt_handler);

    // --- Execution ---

    // Begin execution, and poll until halt.
    begin_execution(&system_control);
    while (!system_halted(&system_control) && !interrupted)
        usleep(1000);

    // --- Output Data Checking and Results Output ---

    // Retrieve and check the output data.
    retrieve_output_data(data_memory_base_address, num_input_data_words, num_expected_output_data_words, output_data);
    passed = output_data_matches(num_expected_output_data_words, output_data, expected_output_data);

    // Result preparation and output.
    results = create_results_object();
    add_passed(results, (int)passed);
    processing_element_results = create_results_object();
    add_header(results, "pe_0", processing_element_results);
    build_processing_element_results(&processing_element, processing_element_results);
    results_json_string = render_results_object(results);
    fprintf(stdout, "%s\n", results_json_string);
    free(results_json_string);
    destroy_results_object(results); // Recursive on tree.

    // --- Cleanup ---

    // Remove access to device memory.
    if (munmap((void *)base_address, MMAP_SIZE) == -1) {
        perror("munmap");
        fprintf(stderr, "Failed to unmap physical memory.\n");
        close(dev_uio0_fd);
        free(output_data);
        free(expected_output_data);
        destroy_platform(platform);
        return 1;
    }
    if (close(dev_uio0_fd) == -1) {
        perror("close");
        fprintf(stderr, "Failed to close /dev/uio0.\n");
        free(output_data);
        free(expected_output_data);
        destroy_platform(platform);
        return 1;
    }

    // Clean up remaining data structures.
    free(output_data);
    free(expected_output_data);
    destroy_platform(platform);

    // Exit successfully.
    return 0;
}

