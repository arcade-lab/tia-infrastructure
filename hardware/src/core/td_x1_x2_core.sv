/*
 * Core module written in an architectural style wiring components together.
 */

`include "core.svh"

module td_x1_x2_core
    (input logic clock, // Positive-edge triggered.
     input logic reset, // Active high.
     input logic enable, // Active high.
     input logic execute, // Active high.
     output logic halted, // High when execution finished.
     output logic channels_quiescent, // High when there are no packets left in the buffers.
     mmio_if.device host_interface,
     link_if.receiver input_channel_links [TIA_NUM_INPUT_CHANNELS - 1:0],
     link_if.sender output_channel_links [TIA_NUM_OUTPUT_CHANNELS - 1:0]);

    // --- Internal Logic and Wiring ---

    // MMIO wiring.
    mmio_if monitor_interface();
    mmio_if performance_counters_interface();
    mmio_if register_file_interface();
    mmio_if instruction_memory_interface();
    mmio_if scratchpad_memory_interface();

    // Channel wiring.
    input_channel_if input_channels[TIA_NUM_INPUT_CHANNELS - 1:0]();
    output_channel_if output_channels[TIA_NUM_OUTPUT_CHANNELS - 1:0]();
    logic [TIA_NUM_INPUT_CHANNELS - 1:0] input_channel_quiescent_status;
    logic [TIA_NUM_OUTPUT_CHANNELS - 1:0] output_channel_quiescent_status;

    // Input channel buffers.
    genvar i;
    generate
        for (i = 0; i < TIA_NUM_INPUT_CHANNELS; i++) begin: icb
            input_channel_buffer icb(.clock(clock),
                                     .reset(reset),
                                     .enable(enable),
                                     .link(input_channel_links[i]),
                                     .input_channel(input_channels[i]),
                                     .quiescent(input_channel_quiescent_status[i]));
        end
    endgenerate

    // Output channel_buffers.
    genvar j;
    generate
        for (j = 0; j < TIA_NUM_OUTPUT_CHANNELS; j++) begin: ocb
            output_channel_buffer ocb(.clock(clock),
                                      .reset(reset),
                                      .enable(enable),
                                      .output_channel(output_channels[j]),
                                      .link(output_channel_links[j]),
                                      .quiescent(output_channel_quiescent_status[j]));
        end
    endgenerate

    // Unpacked input channel interfaces.
    logic [TIA_TAG_WIDTH - 1:0] input_channel_tags [TIA_NUM_INPUT_CHANNELS - 1:0];
    logic [TIA_WORD_WIDTH - 1:0] input_channel_data [TIA_NUM_INPUT_CHANNELS - 1:0];
    logic [TIA_NUM_INPUT_CHANNELS - 1:0] input_channel_dequeue_signals;
    logic [TIA_NUM_INPUT_CHANNELS - 1:0] input_channel_empty_status;
    logic [TIA_CHANNEL_BUFFER_COUNT_WIDTH - 1:0] input_channel_counts [TIA_NUM_INPUT_CHANNELS - 1:0];

    // Unpacked output channel interfaces.
    logic [TIA_TAG_WIDTH - 1:0] output_channel_tags [TIA_NUM_OUTPUT_CHANNELS - 1:0];
    logic [TIA_WORD_WIDTH - 1:0] output_channel_data [TIA_NUM_OUTPUT_CHANNELS - 1:0];
    logic [TIA_NUM_OUTPUT_CHANNELS - 1:0] output_channel_enqueue_signals;
    logic [TIA_NUM_OUTPUT_CHANNELS - 1:0] output_channel_full_status;
    logic [TIA_CHANNEL_BUFFER_COUNT_WIDTH - 1:0] output_channel_counts [TIA_NUM_OUTPUT_CHANNELS - 1:0];

    // Unpack the input channels.
    genvar k;
    generate
        for (k = 0; k < TIA_NUM_INPUT_CHANNELS; k++) begin
            assign input_channel_tags[k] = input_channels[k].packet.tag;
            assign input_channel_data[k] = input_channels[k].packet.data;
            assign input_channels[k].dequeue = input_channel_dequeue_signals[k];
            assign input_channel_empty_status[k] = input_channels[k].empty;
            assign input_channel_counts[k] = input_channels[k].count;
        end
    endgenerate

    // Unpack the output channels.
    genvar l;
    generate
        for (l = 0; l < TIA_NUM_OUTPUT_CHANNELS; l++) begin
            assign output_channels[l].packet.tag = output_channel_tags[l];
            assign output_channels[l].packet.data = output_channel_data[l];
            assign output_channels[l].enqueue = output_channel_enqueue_signals[l];
            assign output_channel_full_status[l] = output_channels[l].full;
            assign output_channel_counts[l] = output_channels[l].count;
        end
    endgenerate

    // Control wiring.
    logic internal_reset, internal_enable, triggered_instruction_valid, control_hazard, data_hazard, hazard;
    logic [TIA_NUM_PREDICATES - 1:0] predicates;
    trigger_t triggers [TIA_MAX_NUM_INSTRUCTIONS - 1:0];
    logic [TIA_INSTRUCTION_INDEX_WIDTH - 1:0] triggered_instruction_index;
    datapath_instruction_t triggered_datapath_instruction, hazard_free_datapath_instruction,
                           potentially_overridden_datapath_instruction;
    logic [TIA_NUM_OUTPUT_CHANNELS - 1:0] updated_output_channel_full_status;
    `ifdef TIA_HAS_PE_PERFORMANCE_COUNTERS
        logic downstream_halt;
    `endif

    // Datapath wiring.
    logic [TIA_WORD_WIDTH - 1:0] registers [TIA_NUM_REGISTERS - 1:0];
    logic [TIA_REGISTER_INDEX_WIDTH - 1:0] register_read_index_0, register_read_index_1, register_read_index_2,
                                           register_write_index;
    logic register_write_enable;
    logic [TIA_WORD_WIDTH - 1:0] register_read_data_0, register_read_data_1, register_read_data_2,
                                 register_write_data, pre_ofu_operand_0, pre_ofu_operand_1, pre_ofu_operand_2,
                                 post_ofu_operand_0, post_ofu_operand_1, post_ofu_operand_2;
    logic [TIA_WORD_WIDTH - 1:0] cfu_result, sm_result, datapath_result;

    // Predicate prediction and speculation. (Pulled to ground if disabled.)
    logic trigger_override, predicate_prediction_hit, predicate_prediction_miss;
    `ifndef TIA_HAS_SPECULATIVE_PREDICATE_UNIT
        assign trigger_override = 0;
        assign predicate_prediction_hit = 0;
        assign predicate_prediction_miss = 0;
    `endif

    // --- MMIO Mapping ---

    // Map read and write requests to the relevant modules.
    core_mapper cmap(.host_interface(host_interface),
                     .monitor_interface(monitor_interface),
                     .performance_counters_interface(performance_counters_interface),
                     .register_file_interface(register_file_interface),
                     .instruction_memory_interface(instruction_memory_interface),
                     .scratchpad_memory_interface(scratchpad_memory_interface));

    // --- Monitor ---

    // Debug monitor.
    `ifdef TIA_HAS_PE_MONITOR
        core_monitor cmon(.clock(clock),
                          .reset(reset),
                          .enable(enable),
                          .host_interface(monitor_interface),
                          .core_predicates(predicates),
                          .core_halted(halted),
                          .core_registers(registers));
    `else
        unused_host_interface umi(monitor_interface);
    `endif

    // --- Performance Counters ---

    // Keep track of core cycle behavior.
    `ifdef TIA_HAS_PE_PERFORMANCE_COUNTERS
        // Both the X1 and X2 stages are downstream.
        assign downstream_halt = (x1_triggered_datapath_instruction.op == TIA_OP_HALT
                                  || x2_triggered_datapath_instruction.op == TIA_OP_HALT);
        `ifdef TIA_HAS_SPECULATIVE_PREDICATE_UNIT
            core_performance_counters cpc(.clock(clock),
                                          .reset(reset),
                                          .enable(enable),
                                          .host_interface(performance_counters_interface),
                                          .core_enable(internal_enable),
                                          .core_execute(execute),
                                          .core_halted(halted),
                                          .core_instruction_valid(potentially_overridden_datapath_instruction.vi),
                                          .core_instruction_retired(x2_triggered_datapath_instruction.vi),
                                          .core_instructions_quashed(predicate_prediction_miss
                                                                   ? {2'd0, (potentially_overridden_datapath_instruction.vi
                                                                             + x1_triggered_datapath_instruction.vi)}
                                                                   : 4'd0),
                                          .core_downstream_halt(downstream_halt),
                                          .core_control_hazard_bubble(1'b0),
                                          .core_data_hazard_bubble(data_hazard),
                                          .core_predicate_prediction_hit(predicate_prediction_hit),
                                          .core_predicate_prediction_miss(predicate_prediction_miss),
                                          .core_trigger_override(trigger_override),
                                          .core_multi_cycle_instruction_stall(1'b0),
                                          .core_pipeline_latency(4'd2));
        `else
            core_performance_counters cpc(.clock(clock),
                                          .reset(reset),
                                          .enable(enable),
                                          .host_interface(performance_counters_interface),
                                          .core_enable(internal_enable),
                                          .core_execute(execute),
                                          .core_halted(halted),
                                          .core_instruction_valid(potentially_overridden_datapath_instruction.vi),
                                          .core_instruction_retired(x2_triggered_datapath_instruction.vi),
                                          .core_instructions_quashed(4'd0),
                                          .core_downstream_halt(downstream_halt),
                                          .core_control_hazard_bubble(control_hazard),
                                          .core_data_hazard_bubble(data_hazard),
                                          .core_predicate_prediction_hit(1'b0),
                                          .core_predicate_prediction_miss(1'b0),
                                          .core_trigger_override(1'b0),
                                          .core_multi_cycle_instruction_stall(1'b0),
                                          .core_pipeline_latency(4'd2));
        `endif
    `else
        unused_host_interface upci(performance_counters_interface);
    `endif

    // --- Control ---

    // Execution control unit.
    execution_control_unit ecu(.clock(clock),
                               .reset(reset),
                               .enable(enable),
                               .execute(execute),
                               .op(x2_triggered_datapath_instruction.op),
                               .input_channel_quiescent_status(input_channel_quiescent_status),
                               .output_channel_quiescent_status(output_channel_quiescent_status),
                               .internal_reset(internal_reset),
                               .internal_enable(internal_enable),
                               .halted(halted),
                               .channels_quiescent(channels_quiescent));

    `ifdef TIA_HAS_SPECULATIVE_PREDICATE_UNIT
        // Speculative predicate unit.
        speculative_predicate_unit spu(.clock(clock),
                                       .reset(internal_reset),
                                       .enable(internal_enable),
                                       .datapath_dt(x2_triggered_datapath_instruction.dt),
                                       .datapath_di(x2_triggered_datapath_instruction.di),
                                       .datapath_result(datapath_result),
                                       .instruction_pum(hazard_free_datapath_instruction.pum),
                                       .instruction_dt(hazard_free_datapath_instruction.dt),
                                       .instruction_di(hazard_free_datapath_instruction.di),
                                       .instruction_op(hazard_free_datapath_instruction.op),
                                       .instruction_icd(hazard_free_datapath_instruction.icd),
                                       .predicates(predicates),
                                       .trigger_override(trigger_override),
                                       .predicate_prediction_hit(predicate_prediction_hit),
                                       .predicate_prediction_miss(predicate_prediction_miss));
    `else
        // Predicate unit.
        predicate_unit pu(.clock(clock),
                          .reset(internal_reset),
                          .enable(internal_enable),
                          .datapath_dt(x2_triggered_datapath_instruction.dt),
                          .datapath_di(x2_triggered_datapath_instruction.di),
                          .datapath_result(datapath_result),
                          .instruction_pum(hazard_free_datapath_instruction.pum),
                          .predicates(predicates));
    `endif

    `ifdef TIA_HAS_FULL_INFORMATION_CHANNEL_STATUS_UPDATING
        // Full information output channel full status updater.
        full_information_two_stage_output_channel_full_status_updater
            fitsocfsu(.output_channel_counts(output_channel_counts),
                      .first_downstream_oci(x1_triggered_datapath_instruction.oci),
                      .second_downstream_oci(x2_triggered_datapath_instruction.oci),
                      .updated_output_channel_full_status(updated_output_channel_full_status));

    `else
        // Pessimistic output channel full status updater.
        pessimistic_two_stage_output_channel_full_status_updater
            ptsocfsu(.output_channel_full_status(output_channel_full_status),
                     .first_downstream_oci(x1_triggered_datapath_instruction.oci),
                     .second_downstream_oci(x2_triggered_datapath_instruction.oci),
                     .updated_output_channel_full_status(updated_output_channel_full_status));
    `endif

    // Trigger resolution unit.
    trigger_resolution_unit tru(.enable(internal_enable),
                                .execute(execute),
                                .halted(halted),
                                .triggers(triggers),
                                .predicates(predicates),
                                .input_channel_empty_status(input_channel_empty_status),
                                .input_channel_tags(input_channel_tags),
                                .output_channel_full_status(updated_output_channel_full_status),
                                .triggered_instruction_valid(triggered_instruction_valid),
                                .triggered_instruction_index(triggered_instruction_index));

    // --- Instruction Memory ---

    // Register-based instruction memory.
    instruction_memory im(.clock(clock),
                          .enable(enable),
                          .host_interface(instruction_memory_interface),
                          .triggers(triggers),
                          .triggered_instruction_valid(triggered_instruction_valid),
                          .triggered_instruction_index(triggered_instruction_index),
                          .triggered_datapath_instruction(triggered_datapath_instruction));

    // --- Hazard Detection ---

    // This design has to worry about both control and data hazards.
    `ifndef TIA_HAS_SPECULATIVE_PREDICATE_UNIT
        two_stage_control_hazard_detector tschd(.first_downstream_dt(x1_triggered_datapath_instruction.dt),
                                                .second_downstream_dt(x2_triggered_datapath_instruction.dt),
                                                .hazard(control_hazard));
    `endif
    data_hazard_detector dhd(.current_st(triggered_datapath_instruction.st),
                             .current_si(triggered_datapath_instruction.si),
                             .downstream_dt(x1_triggered_datapath_instruction.dt),
                             .downstream_di(x1_triggered_datapath_instruction.di),
                             .hazard(data_hazard));
   `ifdef TIA_HAS_SPECULATIVE_PREDICATE_UNIT
        assign hazard = data_hazard;
    `else
        assign hazard = control_hazard | data_hazard;
    `endif
    assign hazard_free_datapath_instruction = hazard ? 0 : triggered_datapath_instruction;

    // Trigger override from speculative predicate unit.
    `ifdef TIA_HAS_SPECULATIVE_PREDICATE_UNIT
        assign potentially_overridden_datapath_instruction = trigger_override ? 0 : hazard_free_datapath_instruction;
    `else
        assign potentially_overridden_datapath_instruction = hazard_free_datapath_instruction;
    `endif

    // --- Datapath ---

    // Register file.
    register_file rf(.clock(clock),
                     .enable(enable),
                     .host_interface(register_file_interface),
                     .read_index_0(register_read_index_0),
                     .read_index_1(register_read_index_1),
                     .read_index_2(register_read_index_2),
                     .write_enable(register_write_enable),
                     .write_index(register_write_index),
                     .register_write_data(register_write_data),
                     .read_data_0(register_read_data_0),
                     .read_data_1(register_read_data_1),
                     .read_data_2(register_read_data_2),
                     .register_data(registers));

    // Source fetching unit.
    source_fetching_unit sfu(.st(potentially_overridden_datapath_instruction.st),
                             .si(potentially_overridden_datapath_instruction.si),
                             .immediate(potentially_overridden_datapath_instruction.immediate),
                             .input_channel_data(input_channel_data),
                             .register_read_index_0(register_read_index_0),
                             .register_read_index_1(register_read_index_1),
                             .register_read_index_2(register_read_index_2),
                             .register_read_data_0(register_read_data_0),
                             .register_read_data_1(register_read_data_1),
                             .register_read_data_2(register_read_data_2),
                             .operand_0(pre_ofu_operand_0),
                             .operand_1(pre_ofu_operand_1),
                             .operand_2(pre_ofu_operand_2));

    // Operand forwarding unit.
    operand_forwarding_unit ofu(.enable(1'b1),
                                .st(potentially_overridden_datapath_instruction.st),
                                .si(potentially_overridden_datapath_instruction.si),
                                .downstream_dt(x2_triggered_datapath_instruction.dt),
                                .downstream_di(x2_triggered_datapath_instruction.di),
                                .downstream_result(datapath_result),
                                .pre_ofu_operand_0(pre_ofu_operand_0),
                                .pre_ofu_operand_1(pre_ofu_operand_1),
                                .pre_ofu_operand_2(pre_ofu_operand_2),
                                .post_ofu_operand_0(post_ofu_operand_0),
                                .post_ofu_operand_1(post_ofu_operand_1),
                                .post_ofu_operand_2(post_ofu_operand_2));

    /*
     * TD|X1 Pipeline Register
     */
    datapath_instruction_t x1_triggered_datapath_instruction;
    logic [TIA_WORD_WIDTH - 1:0] x1_operand_0, x1_operand_1, x1_operand_2;
    always_ff @(posedge clock) begin
        if (reset || predicate_prediction_miss) begin
            x1_triggered_datapath_instruction <= 0;
            x1_operand_0 <= 0;
            x1_operand_1 <= 0;
            x1_operand_2 <= 0;
        end else if (enable) begin
            x1_triggered_datapath_instruction <= potentially_overridden_datapath_instruction;
            x1_operand_0 <= post_ofu_operand_0;
            x1_operand_1 <= post_ofu_operand_1;
            x1_operand_2 <= post_ofu_operand_2;
        end
    end

    // Scratchpad memory.
    `ifdef TIA_HAS_SCRATCHPAD
        scratchpad_memory sm(.clock(clock),
                             .host_interface(scratchpad_memory_interface),
                             .op(x1_triggered_datapath_instruction.op),
                             .operand_0(x1_operand_0),
                             .operand_1(x1_operand_1),
                             .result(sm_result));
    `else
        unused_host_interface usmi(scratchpad_memory_interface);
    `endif

    // Combined functional unit.
    two_stage_combined_functional_unit tscfu(.clock(clock),
                                             .reset(internal_reset),
                                             .enable(internal_enable),
                                             .op(x1_triggered_datapath_instruction.op),
                                             .operand_0(x1_operand_0),
                                             .operand_1(x1_operand_1),
                                             .operand_2(x1_operand_2),
                                             .result(cfu_result));

    /*
     * X1|X2 Pipeline Register
     */
    datapath_instruction_t x2_triggered_datapath_instruction;
    always_ff @(posedge clock) begin
        if (reset || predicate_prediction_miss)
            x2_triggered_datapath_instruction <= 0;
        else if (enable)
            x2_triggered_datapath_instruction <= x1_triggered_datapath_instruction;
    end

    // Multiplex between the scratchpad memory result and the functional unit result.
    `ifdef TIA_HAS_SCRATCHPAD
        always_comb begin
            if (x2_triggered_datapath_instruction.op == TIA_OP_SSW
                || x2_triggered_datapath_instruction.op == TIA_OP_LSW)
                datapath_result = sm_result;
            else
                datapath_result = cfu_result;
        end
    `else
        assign datapath_result = cfu_result;
    `endif

    // Destination routing unit.
    destination_routing_unit dru(.datapath_result(datapath_result),
                                 .dt(x2_triggered_datapath_instruction.dt),
                                 .di(x2_triggered_datapath_instruction.di),
                                 .oci(x2_triggered_datapath_instruction.oci),
                                 .register_write_enable(register_write_enable),
                                 .register_write_index(register_write_index),
                                 .register_write_data(register_write_data),
                                 .output_channel_data(output_channel_data));

    // --- Channel I/O ---

    // Dequeueing unit.
    dequeueing_unit du(.enable(enable && execute && !halted && potentially_overridden_datapath_instruction.vi),
                       .icd(potentially_overridden_datapath_instruction.icd),
                       .dequeue_signals(input_channel_dequeue_signals));

    // Enqueueing unit.
    enqueueing_unit eu(.enable(enable && execute && !halted && x2_triggered_datapath_instruction.vi),
                       .oci(x2_triggered_datapath_instruction.oci),
                       .oct(x2_triggered_datapath_instruction.oct),
                       .enqueue_signals(output_channel_enqueue_signals),
                       .output_channel_tags(output_channel_tags));
endmodule
