#ifndef RESULTS_H
#define RESULTS_H

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <limits.h>

#include <cJSON.h>

#include "processing_element.h"

// Result generation.
cJSON *create_results_object(void);
void add_passed(cJSON *json, int passed);
void add_header(cJSON *root, const char *name, cJSON *header);
void add_result(cJSON *json, const char *name, double value);
void add_numerical_array(cJSON *json, const char *name, uint32_t *array, size_t array_length);
char *render_results_object(cJSON *json);
void destroy_results_object(cJSON *json);
void build_processing_element_results(processing_element_t *processing_element, cJSON *results_object);

#endif // RESULTS_H
