/*
 * Core module written in an architectural style wiring components together.
 */

`include "core.svh"

module integer_core
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

    // Unpacked channel wiring.
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
    logic [TIA_TAG_WIDTH - 1:0] input_channel_next_tags [TIA_NUM_INPUT_CHANNELS - 1:0];
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
            assign input_channel_next_tags[k] = input_channels[k].next_packet.tag;
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
    logic internal_reset, internal_enable, triggered_instruction_valid, hazard, control_hazard, collision;
    logic [TIA_NUM_PREDICATES - 1:0] predicates;
    trigger_t triggers [TIA_MAX_NUM_INSTRUCTIONS - 1:0];
    logic [TIA_INSTRUCTION_INDEX_WIDTH - 1:0] triggered_instruction_index;
    datapath_instruction_t triggered_datapath_instruction, hazard_free_datapath_instruction,
                           potentially_overridden_datapath_instruction,
                           retiring_datapath_instruction;
    logic [TIA_NUM_INPUT_CHANNELS - 1:0] updated_input_channel_empty_status;
    logic [TIA_NUM_OUTPUT_CHANNELS - 1:0] updated_output_channel_full_status;
    logic [TIA_TAG_WIDTH - 1:0] input_channel_resolved_tags [TIA_NUM_INPUT_CHANNELS - 1:0];
    `ifdef TIA_HAS_CORE_PERFORMANCE_COUNTERS
    logic downstream_halt;
    `endif

    // Datapath wiring.
    logic [TIA_WORD_WIDTH - 1:0] registers [TIA_NUM_REGISTERS - 1:0];
    logic [TIA_REGISTER_INDEX_WIDTH - 1:0] register_read_index_0, register_read_index_1, register_read_index_2,
                                           register_write_index;
    logic register_write_enable;
    logic [TIA_WORD_WIDTH - 1:0] register_read_data_0, register_read_data_1, register_read_data_2,
                                 register_write_data,
                                 pre_ofu_operand_0, pre_ofu_operand_1, pre_ofu_operand_2,
                                 post_ofu_operand_0, post_ofu_operand_1, post_ofu_operand_2,
                                 alu_result, sm_result, imu_result, datapath_result;

    // Predicate prediction and speculation. (Pulled to ground if disabled.)
    logic trigger_override, predicate_prediction_hit, predicate_prediction_miss;
    `ifndef TIA_HAS_SPECULATIVE_PREDICATE_UNIT
    assign trigger_override = 0;
    assign predicate_prediction_hit = 0;
    assign predicate_prediction_miss = 0;
    `endif

    // Pipeline registers.
    logic [2:0] dx1_instruction_retiring_stage, x2_instruction_retiring_stage;
    functional_unit_t dx1_functional_unit, x2_functional_unit;
    datapath_instruction_t dx1_triggered_datapath_instruction, x2_triggered_datapath_instruction;


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
    `ifdef TIA_HAS_CORE_MONITOR
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

    `ifdef TIA_HAS_CORE_PERFORMANCE_COUNTERS
        // The DX1 and X2 stages are both downstream.
        assign downstream_halt = (dx1_triggered_datapath_instruction.op == TIA_OP_HALT
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
                                          .core_instruction_retired(retiring_datapath_instruction.vi),
                                          .core_instructions_quashed(predicate_prediction_miss
                                                                     ? {2'd0, (potentially_overridden_datapath_instruction.vi
                                                                                + dx1_triggered_datapath_instruction.vi)}
                                                                     : 4'd0),
                                          .core_downstream_halt(downstream_halt),
                                          .core_control_hazard_bubble(1'b0),
                                          .core_data_hazard_bubble(1'b0),
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
                                          .core_instruction_retired(retiring_datapath_instruction.vi),
                                          .core_instructions_quashed(4'd0),
                                          .core_downstream_halt(downstream_halt),
                                          .core_control_hazard_bubble(hazard),
                                          .core_data_hazard_bubble(1'b0),
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
                               .op(retiring_datapath_instruction.op),
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
                                       .datapath_dt(retiring_datapath_instruction.dt),
                                       .datapath_di(retiring_datapath_instruction.di),
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
                          .datapath_dt(retiring_datapath_instruction.dt),
                          .datapath_di(retiring_datapath_instruction.di),
                          .datapath_result(datapath_result),
                          .instruction_pum(hazard_free_datapath_instruction.pum),
                          .predicates(predicates));
    `endif

    `ifdef TIA_HAS_FULL_INFORMATION_CHANNEL_STATUS_UPDATING
        // Full information input channel empty status updater.
        full_information_one_stage_input_channel_empty_status_updater
            fiosicesu(.input_channel_counts(input_channel_counts),
                      .downstream_icd(dx1_triggered_datapath_instruction.icd),
                      .updated_input_channel_empty_status(updated_input_channel_empty_status));
    `else
        // Input channel empty status updater.
        pessimistic_one_stage_input_channel_empty_status_updater
            posiceu(.input_channel_empty_status(input_channel_empty_status),
                    .downstream_icd(dx1_triggered_datapath_instruction.icd),
                    .updated_input_channel_empty_status(updated_input_channel_empty_status));
    `endif

    `ifdef TIA_HAS_FULL_INFORMATION_CHANNEL_STATUS_UPDATING
        // Full information output channel full status updater.
        full_information_two_stage_output_channel_full_status_updater
            fitsocfsu(.output_channel_counts(output_channel_counts),
                      .first_downstream_oci(dx1_triggered_datapath_instruction.oci),
                      .second_downstream_oci(x2_triggered_datapath_instruction.oci),
                      .updated_output_channel_full_status(updated_output_channel_full_status));
    `else
        // Output channel full status updater.
        pessimistic_two_stage_output_channel_full_status_updater
            ptsocfsu(.output_channel_full_status(output_channel_full_status),
                     .first_downstream_oci(dx1_triggered_datapath_instruction.oci),
                     .second_downstream_oci(x2_triggered_datapath_instruction.oci),
                     .updated_output_channel_full_status(updated_output_channel_full_status));
    `endif

    // Input channel tag lookahead unit.
    input_channel_tag_lookahead_unit ictlu(.pending_dequeue_signals(input_channel_dequeue_signals),
                                           .original_tags(input_channel_tags),
                                           .next_tags(input_channel_next_tags),
                                           .resolved_tags(input_channel_resolved_tags));

    // Trigger resolution unit.
    trigger_resolution_unit tru(.enable(internal_enable),
                                .execute(execute),
                                .halted(halted),
                                .triggers(triggers),
                                .predicates(predicates),
                                .input_channel_empty_status(updated_input_channel_empty_status),
                                .input_channel_tags(input_channel_resolved_tags),
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

    // This design only needs to worry about control hazards and collisions.
    `ifndef TIA_HAS_SPECULATIVE_PREDICATE_UNIT
        two_stage_control_hazard_detector tschd(.first_downstream_dt(dx1_triggered_datapath_instruction.dt),
                                                .second_downstream_dt(x2_triggered_datapath_instruction.dt),
                                                .hazard(control_hazard));
    `else
        assign control_hazard = 0;
    `endif
    integer_collision_detector icd(.triggered_instruction_op(triggered_datapath_instruction.op),
                                   .dx1_instruction_retiring_stage(dx1_instruction_retiring_stage),
                                   .collision(collision));
    assign hazard = control_hazard | collision;
    assign hazard_free_datapath_instruction = hazard ? 0 : triggered_datapath_instruction;

    // Trigger override from speculative predicate unit.
    `ifdef TIA_HAS_SPECULATIVE_PREDICATE_UNIT
        assign potentially_overridden_datapath_instruction = trigger_override ? 0 : hazard_free_datapath_instruction;
    `else
        assign potentially_overridden_datapath_instruction = hazard_free_datapath_instruction;
    `endif

    /*
     * T|DX1 Pipeline Register
     */
    always_ff @(posedge clock) begin
        if (reset || predicate_prediction_miss)
            dx1_triggered_datapath_instruction <= 0;
        else if (enable)
            dx1_triggered_datapath_instruction <= potentially_overridden_datapath_instruction;
    end

    // --- Instruction Issue ---

    // Issue.
    integer_issue_unit iiu(.dx1_instruction_op(dx1_triggered_datapath_instruction.op),
                           .retiring_stage(dx1_instruction_retiring_stage),
                           .functional_unit(dx1_functional_unit));


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
    source_fetching_unit sfu(.st(dx1_triggered_datapath_instruction.st),
                             .si(dx1_triggered_datapath_instruction.si),
                             .immediate(dx1_triggered_datapath_instruction.immediate),
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
    operand_forwarding_unit ofu(.enable((dx1_instruction_retiring_stage == 2)
                                        && (x2_instruction_retiring_stage == 2)
                                        && (dx1_functional_unit != ALU)),
                                .st(dx1_triggered_datapath_instruction.st),
                                .si(dx1_triggered_datapath_instruction.si),
                                .downstream_dt(x2_triggered_datapath_instruction.dt),
                                .downstream_di(x2_triggered_datapath_instruction.di),
                                .downstream_result(datapath_result),
                                .pre_ofu_operand_0(pre_ofu_operand_0),
                                .pre_ofu_operand_1(pre_ofu_operand_1),
                                .pre_ofu_operand_2(pre_ofu_operand_2),
                                .post_ofu_operand_0(post_ofu_operand_0),
                                .post_ofu_operand_1(post_ofu_operand_1),
                                .post_ofu_operand_2(post_ofu_operand_2));

    // Arithemetic logic unit.
    // N.B.: As a single-cycle functional unit in an in-order core, there is not reason the ALU
    // should take fowarded operands.
    arithmetic_logic_unit alu(.op(dx1_triggered_datapath_instruction.op),
                              .operand_0(pre_ofu_operand_0), // To prevent a loop being inferred.
                              .operand_1(pre_ofu_operand_1), // To prevent a loop being inferred.
                              .operand_2(pre_ofu_operand_2), // To prevent a loop being inferred.
                              .result(alu_result));

    // Scratchpad memory.
    `ifdef TIA_HAS_SCRATCHPAD
        scratchpad_memory #(.DEPTH(TIA_NUM_SCRATCHPAD_WORDS))
            sm(.clock(clock),
               .host_interface(scratchpad_memory_interface),
               .op(dx1_triggered_datapath_instruction.op),
               .operand_0(post_ofu_operand_0),
               .operand_1(post_ofu_operand_1),
               .result(sm_result));
    `else
        assign sm_result = 0;
        unused_host_interface usmi(scratchpad_memory_interface);
    `endif

    // Integer multiplication.
    `ifdef TIA_HAS_MULTIPLIER
        integer_multiplication_unit imu(.clock(clock),
                                        .reset(internal_reset),
                                        .enable(internal_enable),
                                        .op(dx1_triggered_datapath_instruction.op),
                                        .operand_0(post_ofu_operand_0),
                                        .operand_1(post_ofu_operand_1),
                                        .operand_2(post_ofu_operand_2),
                                        .result(imu_result));
    `else
        assign imu_result = 0;
    `endif

    /*
     * DX1|X2 Pipeline Register
     */
    always_ff @(posedge clock) begin
        if (reset || predicate_prediction_miss) begin
            x2_triggered_datapath_instruction <= 0;
            x2_instruction_retiring_stage <= 0;
            x2_functional_unit <= ALU;
        end else if (enable) begin
            if (dx1_instruction_retiring_stage == 2) begin
                x2_triggered_datapath_instruction <= dx1_triggered_datapath_instruction;
                x2_instruction_retiring_stage <= dx1_instruction_retiring_stage;
                x2_functional_unit <= dx1_functional_unit;
            end else begin
                x2_triggered_datapath_instruction <= 0;
                x2_instruction_retiring_stage <= 0;
                x2_functional_unit <= ALU;
            end
        end
    end

    // --- Retirement ---

    integer_retirement_unit iru(.dx1_instruction_retiring_stage(dx1_instruction_retiring_stage),
                                .dx1_functional_unit(dx1_functional_unit),
                                .x2_instruction_retiring_stage(x2_instruction_retiring_stage),
                                .x2_functional_unit(x2_functional_unit),
                                .dx1_datapath_instruction(dx1_triggered_datapath_instruction),
                                .x2_datapath_instruction(x2_triggered_datapath_instruction),
                                .alu_result(alu_result),
                                .sm_result(sm_result),
                                .imu_result(imu_result),
                                .retiring_datapath_instruction(retiring_datapath_instruction),
                                .datapath_result(datapath_result));


    // Destination routing unit.
    destination_routing_unit dru(.datapath_result(datapath_result),
                                 .dt(retiring_datapath_instruction.dt),
                                 .di(retiring_datapath_instruction.di),
                                 .oci(retiring_datapath_instruction.oci),
                                 .register_write_enable(register_write_enable),
                                 .register_write_index(register_write_index),
                                 .register_write_data(register_write_data),
                                 .output_channel_data(output_channel_data));

    // --- Channel I/O ---

    // Dequeueing unit.
    dequeueing_unit du(.enable(enable && execute && !halted && dx1_triggered_datapath_instruction.vi),
                       .icd(dx1_triggered_datapath_instruction.icd),
                       .dequeue_signals(input_channel_dequeue_signals));

    // Enqueueing unit.
    enqueueing_unit eu(.enable(enable && execute && !halted && retiring_datapath_instruction.vi),
                       .oci(retiring_datapath_instruction.oci),
                       .oct(retiring_datapath_instruction.oct),
                       .enqueue_signals(output_channel_enqueue_signals),
                       .output_channel_tags(output_channel_tags));
endmodule
