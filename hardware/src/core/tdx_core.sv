/*
 * Core module written in an architectural style wiring components together.
 */

`include "core.svh"

module tdx_core
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
    logic internal_reset, internal_enable, triggered_instruction_valid;
    logic [TIA_NUM_PREDICATES - 1:0] predicates;
    trigger_t triggers [TIA_MAX_NUM_INSTRUCTIONS - 1:0];
    logic [TIA_INSTRUCTION_INDEX_WIDTH - 1:0] triggered_instruction_index;
    datapath_instruction_t triggered_datapath_instruction;
    logic load_scratchpad_word_stall;

    // Datapath wiring.
    logic [TIA_WORD_WIDTH - 1:0] registers [TIA_NUM_REGISTERS - 1:0];
    logic [TIA_REGISTER_INDEX_WIDTH - 1:0] register_read_index_0, register_read_index_1, register_read_index_2,
                                           register_write_index;
    logic register_write_enable;
    logic [TIA_WORD_WIDTH - 1:0] register_read_data_0, register_read_data_1, register_read_data_2,
                                 register_write_data;
    logic [TIA_WORD_WIDTH - 1:0] operand_0, operand_1, operand_2, cfu_result, sm_result, datapath_result;

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
        core_performance_counters cpc(.clock(clock),
                                      .reset(reset),
                                      .enable(enable),
                                      .host_interface(performance_counters_interface),
                                      .core_enable(internal_enable),
                                      .core_execute(execute),
                                      .core_halted(halted),
                                      .core_instruction_valid(triggered_datapath_instruction.vi),
                                      .core_instruction_retired(triggered_datapath_instruction.vi),
                                       // The below are not relevant in a single-cycle design.
                                      .core_instructions_quashed(4'd0),
                                      .core_downstream_halt(1'b0),
                                      .core_control_hazard_bubble(1'b0),
                                      .core_data_hazard_bubble(1'b0),
                                      .core_predicate_prediction_hit(1'b0),
                                      .core_predicate_prediction_miss(1'b0),
                                      .core_trigger_override(1'b0),
                                      // We do, however, have the possibility of multi-cycle instruction stalls.
                                      .core_multi_cycle_instruction_stall(load_scratchpad_word_stall),
                                      // Single-cycle designs have no pipeline latency.
                                      .core_pipeline_latency(4'd0));
    `else
        unused_host_interface upci(performance_counters_interface);
    `endif

    // --- Control ---

    // Execution control unit.
    execution_control_unit ecu(.clock(clock),
                               .reset(reset),
                               .enable(enable),
                               .execute(execute),
                               .op(triggered_datapath_instruction.op),
                               .input_channel_quiescent_status(input_channel_quiescent_status),
                               .output_channel_quiescent_status(output_channel_quiescent_status),
                               .internal_reset(internal_reset),
                               .internal_enable(internal_enable),
                               .halted(halted),
                               .channels_quiescent(channels_quiescent));

    // Predicate unit.
    predicate_unit pu(.clock(clock),
                      .reset(internal_reset),
                      .enable(internal_enable && !load_scratchpad_word_stall),
                      .datapath_dt(triggered_datapath_instruction.dt),
                      .datapath_di(triggered_datapath_instruction.di),
                      .datapath_result(datapath_result),
                      .instruction_pum(triggered_datapath_instruction.pum),
                      .predicates(predicates));

    // Trigger resolution unit.
    trigger_resolution_unit tru(.enable(internal_enable),
                                .execute(execute),
                                .halted(halted),
                                .triggers(triggers),
                                .predicates(predicates),
                                .input_channel_empty_status(input_channel_empty_status),
                                .input_channel_tags(input_channel_tags),
                                .output_channel_full_status(output_channel_full_status),
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

    // --- Datapath ---

    // Register file.
    register_file rf(.clock(clock),
                     .enable(enable),
                     .host_interface(register_file_interface),
                     .read_index_0(register_read_index_0),
                     .read_index_1(register_read_index_1),
                     .read_index_2(register_read_index_2),
                     .write_enable(register_write_enable && !load_scratchpad_word_stall),
                     .write_index(register_write_index),
                     .register_write_data(register_write_data),
                     .read_data_0(register_read_data_0),
                     .read_data_1(register_read_data_1),
                     .read_data_2(register_read_data_2),
                     .register_data(registers));

    // Source fetching unit.
    source_fetching_unit sfu(.st(triggered_datapath_instruction.st),
                             .si(triggered_datapath_instruction.si),
                             .immediate(triggered_datapath_instruction.immediate),
                             .input_channel_data(input_channel_data),
                             .register_read_index_0(register_read_index_0),
                             .register_read_index_1(register_read_index_1),
                             .register_read_index_2(register_read_index_2),
                             .register_read_data_0(register_read_data_0),
                             .register_read_data_1(register_read_data_1),
                             .register_read_data_2(register_read_data_2),
                             .operand_0(operand_0),
                             .operand_1(operand_1),
                             .operand_2(operand_2));

    // Scratchpad memory.
    `ifdef TIA_HAS_SCRATCHPAD
        scratchpad_memory sm(.clock(clock),
                             .host_interface(scratchpad_memory_interface),
                             .op(triggered_datapath_instruction.op),
                             .operand_0(operand_0),
                             .operand_1(operand_1),
                             .result(sm_result));
        load_scratchpad_word_stall_unit lswsu(.clock(clock),
                                              .reset(internal_reset),
                                              .enable(internal_enable),
                                              .op(triggered_datapath_instruction.op),
                                              .load_scratchpad_word_stall(load_scratchpad_word_stall));
    `else
        unused_host_interface usmi(scratchpad_memory_interface);
        assign load_scratchpad_word_stall = 0;
    `endif

    // Combined functional unit.
    single_cycle_combined_functional_unit sccfu(.op(triggered_datapath_instruction.op),
                                                .operand_0(operand_0),
                                                .operand_1(operand_1),
                                                .operand_2(operand_2),
                                                .result(cfu_result));

    // Multiplex between the scratchpad memory result and the functional unit result.
    `ifdef TIA_HAS_SCRATCHPAD
        always_comb begin
            if (triggered_datapath_instruction.op == TIA_OP_SSW
                || triggered_datapath_instruction.op == TIA_OP_LSW)
                datapath_result = sm_result;
            else
                datapath_result = cfu_result;
        end
    `else
        assign datapath_result = cfu_result;
    `endif

    // Destination routing unit.
    destination_routing_unit dru(.datapath_result(datapath_result),
                                 .dt(triggered_datapath_instruction.dt),
                                 .di(triggered_datapath_instruction.di),
                                 .oci(triggered_datapath_instruction.oci),
                                 .register_write_enable(register_write_enable),
                                 .register_write_index(register_write_index),
                                 .register_write_data(register_write_data),
                                 .output_channel_data(output_channel_data));

    // --- Channel I/O ---

    // Dequeueing unit.
    dequeueing_unit du(.enable(enable && execute && !halted && !load_scratchpad_word_stall && triggered_datapath_instruction.vi),
                       .icd(triggered_datapath_instruction.icd),
                       .dequeue_signals(input_channel_dequeue_signals));

    // Enqueueing unit.
    enqueueing_unit eu(.enable(enable && execute && !halted && !load_scratchpad_word_stall && triggered_datapath_instruction.vi),
                       .oci(triggered_datapath_instruction.oci),
                       .oct(triggered_datapath_instruction.oct),
                       .enqueue_signals(output_channel_enqueue_signals),
                       .output_channel_tags(output_channel_tags));
endmodule
