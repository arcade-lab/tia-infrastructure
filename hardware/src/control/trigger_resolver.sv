/*
 * A module to be instantiated for each trigger. It checks the instructions's trigger requirements
 * against architectural state, and outputs valid if an trigger is eligible to be scheduled in a
 * given cycle.
 */

`include "control.svh"

module trigger_resolver
    (input trigger_t trigger,
     input logic [TIA_NUM_PREDICATES - 1:0] predicates,
     input logic [TIA_NUM_INPUT_CHANNELS - 1:0] input_channel_empty_status,
     input logic [TIA_TAG_WIDTH - 1:0] input_channel_tags [TIA_NUM_INPUT_CHANNELS - 1:0],
     input logic [TIA_NUM_OUTPUT_CHANNELS - 1:0] output_channel_full_status,
     output logic valid);

    // --- Internal Logic and Wiring ---

    // Not synthesized.
    integer i, j, input_channel_to_check_i, input_channel_to_check_j;

    // Whether the trigger is eligible at all.
    logic valid_trigger;

    // Predicate checking logic.
    logic [TIA_TRUE_PTM_WIDTH - 1:0] true_ptm;
    logic [TIA_FALSE_PTM_WIDTH - 1:0] false_ptm;
    logic [TIA_NUM_PREDICATES - 1:0] true_predicate_array, false_predicate_array;
    logic valid_predicate_state;

    // Input channel empty status checking logic.
    logic [TIA_MAX_NUM_INPUT_CHANNELS_TO_CHECK - 1:0] valid_input_channel_empty_status_array;
    logic valid_input_channel_empty_status;

    // Input channel tag checking logic.
    logic [TIA_MAX_NUM_INPUT_CHANNELS_TO_CHECK - 1:0] valid_input_channel_tags_array;
    logic valid_input_channel_tags;

    // Whether the output channel can accept a new packet.
    logic valid_output_channel_full_status;

    // --- Combinational Logic ---

    // Check whether the trigger is valid at all.
    assign valid_trigger = trigger.vi;

    // Check the predicate state.
    assign true_ptm = trigger.ptm[TIA_PTM_WIDTH - 1:TIA_FALSE_PTM_WIDTH];
    assign false_ptm = trigger.ptm[TIA_FALSE_PTM_WIDTH - 1:0];
    assign true_predicate_array = ~true_ptm | predicates;
    assign false_predicate_array = ~false_ptm | ~predicates;
    assign valid_predicate_state = &{true_predicate_array, false_predicate_array};

    // Check all requested input channels. Channels that are not requested are valid de facto.
    always_comb begin
        for (i = 0; i < TIA_MAX_NUM_INPUT_CHANNELS_TO_CHECK; i++) begin
            if (trigger.ici[TIA_SINGLE_ICI_WIDTH * i+:TIA_SINGLE_ICI_WIDTH] != 0) begin
                input_channel_to_check_i = trigger.ici[TIA_SINGLE_ICI_WIDTH * i+:TIA_SINGLE_ICI_WIDTH] - 1;
                if (!input_channel_empty_status[input_channel_to_check_i])
                    valid_input_channel_empty_status_array[i] = 1;
                else
                    valid_input_channel_empty_status_array[i] = 0;
            end else
                valid_input_channel_empty_status_array[i] = 1;
        end
    end

    // All channels must have a valid state.
    assign valid_input_channel_empty_status = &valid_input_channel_empty_status_array;

    // Check the input channel tags for the requested channels. Channels that are not requested are
    // valid de facto.
    always_comb begin
        for (j = 0; j < TIA_MAX_NUM_INPUT_CHANNELS_TO_CHECK; j++) begin
            if (trigger.ici[TIA_SINGLE_ICI_WIDTH * j+:TIA_SINGLE_ICI_WIDTH] != 0) begin
                input_channel_to_check_j = trigger.ici[TIA_SINGLE_ICI_WIDTH * j+:TIA_SINGLE_ICI_WIDTH] - 1;
                if (input_channel_tags[input_channel_to_check_j] == trigger.ictv[TIA_TAG_WIDTH * j+:TIA_TAG_WIDTH])
                    valid_input_channel_tags_array[j] = trigger.ictb[j];
                else
                    valid_input_channel_tags_array[j] = ~trigger.ictb[j];
            end else
                valid_input_channel_tags_array[j] = 1;
        end
    end

    // All channels must have valid tags.
    assign valid_input_channel_tags = &valid_input_channel_tags_array;

    // Check the output channel status for conflicts with full output channels.
    assign valid_output_channel_full_status = (trigger.oci & output_channel_full_status) == 0;

    // A valid state is the conjugation of all the factors we just checked.
    assign valid = (valid_trigger
                    && valid_predicate_state
                    && valid_input_channel_empty_status
                    && valid_input_channel_tags
                    && valid_output_channel_full_status);
endmodule
