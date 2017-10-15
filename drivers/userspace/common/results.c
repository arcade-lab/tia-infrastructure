#include "results.h"

cJSON *create_results_object(void)
{
	return cJSON_CreateObject();
}

void add_passed(cJSON *json, int passed)
{
    // Use the true/false function macros in cJSON.
    if (passed)
        cJSON_AddTrueToObject(json, "passed");
    else
        cJSON_AddFalseToObject(json, "passed");
}

void add_header(cJSON *root, const char *name, cJSON *header)
{
    // Simple wrapper.
    cJSON_AddItemToObject(root, name, header);
}

void add_result(cJSON *json, const char *name, double value)
{
    // Simple wrapper.
	cJSON_AddNumberToObject(json, name, value);
}

void add_numerical_array(cJSON *json, const char *name, uint32_t *array, size_t array_length)
{
    double *converted_array;
    size_t i;
    cJSON *list;

    // Allocate memory to convert the array.
    if ((converted_array = (double *)malloc(array_length * sizeof(double))) == NULL) {
        perror("malloc");
        return;
    }

    // Convert the array to doubles for JSON with casting.
    for (i = 0; i < array_length; i++)
        converted_array[i] = (double)array[i];

    // Create the cJSON list.
    list = cJSON_CreateDoubleArray(converted_array, (int)array_length);


    // Add the list the parent JSON object.
    cJSON_AddItemToObject(json, name, list);
}

char *render_results_object(cJSON *json)
{
    return cJSON_Print(json);
}

void destroy_results_object(cJSON *json)
{
    cJSON_Delete(json);
}

void build_processing_element_results(processing_element_t *processing_element, cJSON *results_object)
{
    // Add labeled results fields.
    add_result(results_object, "executed_cycles", (double)executed_cycles_counter(processing_element));
    add_result(results_object, "instructions_issued", (double)instructions_issued_counter(processing_element));
    add_result(results_object, "instructions_retired", (double)instructions_retired_counter(processing_element));
    add_result(results_object, "instructions_quashed", (double)instructions_quashed_counter(processing_element));
    add_result(results_object, "untriggered_cycles", (double)untriggered_cycles_counter(processing_element));
    add_result(results_object, "bubbles", (double)bubbles_counter(processing_element));
    add_result(results_object, "control_hazard_bubbles", (double)control_hazard_bubbles_counter(processing_element));
    add_result(results_object, "data_hazard_bubbles", (double)data_hazard_bubbles_counter(processing_element));
    add_result(results_object, "predicate_prediction_hits", (double)predicate_prediction_hits_counter(processing_element));
    add_result(results_object, "predicate_prediction_misses", (double)predicate_prediction_misses_counter(processing_element));
    add_result(results_object, "trigger_overrides", (double)trigger_overrides_counter(processing_element));
    add_result(results_object, "multi_cycle_instruction_stalls", (double)multi_cycle_instruction_stalls_counter(processing_element));
    add_result(results_object, "pipeline_latency", (double)pipeline_latency(processing_element));
}

