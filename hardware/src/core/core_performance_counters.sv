/*
 * Cycle tracking performance counters local to a single processing element core.
 */

`include "core.svh"

module core_performance_counters
    (input logic clock, // Positive-edge triggered.
     input logic reset, // Active high.
     input logic enable, // Active high.
     mmio_if.device host_interface,
     input logic core_enable,
     input logic core_execute,
     input logic core_halted,
     input logic core_instruction_valid,
     input logic core_instruction_retired,
     input logic [3:0] core_instructions_quashed,
     input logic core_downstream_halt,
     input logic core_control_hazard_bubble,
     input logic core_data_hazard_bubble,
     input logic core_predicate_prediction_hit,
     input logic core_predicate_prediction_miss,
     input logic core_trigger_override,
     input logic core_multi_cycle_instruction_stall,
     input logic [3:0] core_pipeline_latency);

    // --- Internal Logic and Wiring ---

    // Whether there is a bubble at all.
    logic core_bubble;

    // Counters.
    logic [TIA_WORD_WIDTH - 1:0] executed_cycles,
                                 instructions_issued,
                                 instructions_retired,
                                 instructions_quashed,
                                 untriggered_cycles,
                                 bubbles,
                                 control_hazard_bubbles,
                                 data_hazard_bubbles,
                                 predicate_prediction_hits,
                                 predicate_prediction_misses,
                                 trigger_overrides,
                                 multi_cycle_instruction_stalls;

    // Buffered input signals.
    logic core_enable_buffer;
    logic core_execute_buffer;
    logic core_halted_buffer;
    logic core_instruction_valid_buffer;
    logic core_instruction_retired_buffer;
    logic [3:0] core_instructions_quashed_buffer;
    logic core_downstream_halt_buffer;
    logic core_control_hazard_bubble_buffer;
    logic core_data_hazard_bubble_buffer;
    logic core_bubble_buffer;
    logic core_predicate_prediction_hit_buffer;
    logic core_predicate_prediction_miss_buffer;
    logic core_trigger_override_buffer;
    logic core_multi_cycle_instruction_stall_buffer;

    // --- Combinational Logic ---

    // Determine if there is a bubble in a given cycle.
    assign core_bubble = core_control_hazard_bubble | core_data_hazard_bubble;

    // Support reads from performance counters.
    always_comb begin
        if (enable && host_interface.read_req) begin
            unique case (host_interface.read_index)
                TIA_PE_EXECUTED_CYCLES_COUNTER_INDEX:
                    host_interface.read_data = executed_cycles;
                TIA_PE_INSTRUCTIONS_ISSUED_COUNTER_INDEX:
                    host_interface.read_data = instructions_issued;
                TIA_PE_INSTRUCTIONS_RETIRED_COUNTER_INDEX:
                    host_interface.read_data = instructions_retired;
                TIA_PE_INSTRUCTIONS_QUASHED_COUNTER_INDEX:
                    host_interface.read_data = instructions_quashed;
                TIA_PE_UNTRIGGERED_CYCLES_COUNTER_INDEX:
                    host_interface.read_data = untriggered_cycles;
                TIA_PE_BUBBLES_COUNTER_INDEX:
                    host_interface.read_data = bubbles;
                TIA_PE_CONTROL_HAZARD_BUBBLES_COUNTER_INDEX:
                    host_interface.read_data = control_hazard_bubbles;
                TIA_PE_DATA_HAZARD_BUBBLES_COUNTER_INDEX:
                    host_interface.read_data = data_hazard_bubbles;
                TIA_PE_PREDICATE_PREDICTION_HITS_COUNTER_INDEX:
                    host_interface.read_data = predicate_prediction_hits;
                TIA_PE_PREDICATE_PREDICTION_MISSES_COUNTER_INDEX:
                    host_interface.read_data = predicate_prediction_misses;
                TIA_PE_TRIGGER_OVERRIDES_COUNTER_INDEX:
                    host_interface.read_data = trigger_overrides;
                TIA_PE_MULTI_CYCLE_INSTRUCTION_STALLS_INDEX:
                    host_interface.read_data = multi_cycle_instruction_stalls;
                TIA_PE_PIPELINE_LATENCY_INDEX:
                    host_interface.read_data = core_pipeline_latency;
                default: host_interface.read_data = 0;
            endcase
        end else begin
            host_interface.read_data = 0;
        end
    end

    // Reads from muxed registers have no latency.
    assign host_interface.read_ack = host_interface.read_req;

    // We do not support writes, so we always immediately acknowledge write and implicitly discard
    // their data.
    assign host_interface.write_ack = host_interface.write_req;

    // --- Sequential Logic ---

    // Buffer inputs to minimized effect on the critical path.
    always_ff @(posedge clock) begin
        if (reset) begin
            core_enable_buffer <= 0;
            core_execute_buffer <= 0;
            core_halted_buffer <= 0;
            core_instruction_valid_buffer <= 0;
            core_instruction_retired_buffer <= 0;
            core_instructions_quashed_buffer <= 0;
            core_downstream_halt_buffer <= 0;
            core_control_hazard_bubble_buffer <= 0;
            core_data_hazard_bubble_buffer <= 0;
            core_bubble_buffer <= 0;
            core_predicate_prediction_hit_buffer <= 0;
            core_predicate_prediction_miss_buffer <= 0;
            core_trigger_override_buffer <= 0;
            core_multi_cycle_instruction_stall_buffer <= 0;
        end else if (enable) begin
            core_enable_buffer <= core_enable;
            core_execute_buffer <= core_execute;
            core_halted_buffer <= core_halted;
            core_instruction_valid_buffer <= core_instruction_valid;
            core_instruction_retired_buffer <= core_instruction_retired;
            core_instructions_quashed_buffer <= core_instructions_quashed;
            core_downstream_halt_buffer <= core_downstream_halt;
            core_control_hazard_bubble_buffer <= core_control_hazard_bubble;
            core_data_hazard_bubble_buffer <= core_data_hazard_bubble;
            core_bubble_buffer <= core_bubble;
            core_predicate_prediction_hit_buffer <= core_predicate_prediction_hit;
            core_predicate_prediction_miss_buffer <= core_predicate_prediction_miss;
            core_trigger_override_buffer <= core_trigger_override;
            core_multi_cycle_instruction_stall_buffer <= core_multi_cycle_instruction_stall;
        end
    end

    // Increment counters according to architectural state.
    always_ff @(posedge clock) begin
        if (reset) begin
            // Reset all counters upon reset.
            executed_cycles <= 0;
            instructions_issued <= 0;
            instructions_retired <= 0;
            instructions_quashed <= 0;
            untriggered_cycles <= 0;
            bubbles <= 0;
            control_hazard_bubbles <= 0;
            data_hazard_bubbles <= 0;
            predicate_prediction_hits <= 0;
            predicate_prediction_misses <= 0;
            trigger_overrides <= 0;
            multi_cycle_instruction_stalls <= 0;
        end else if (enable) begin
            // TODO: These should be commented individually...
            if (core_enable_buffer && core_execute_buffer && !core_halted_buffer)
                executed_cycles <= executed_cycles + 1;
            if (core_enable_buffer && core_execute_buffer && !core_halted_buffer
                && core_instruction_valid_buffer && !core_downstream_halt_buffer && !core_bubble_buffer
                && !core_multi_cycle_instruction_stall_buffer)
                instructions_issued <= instructions_issued + 1;
            if (core_enable_buffer && core_execute_buffer && !core_halted_buffer
                && core_instruction_retired_buffer && !core_multi_cycle_instruction_stall_buffer)
                instructions_retired <= instructions_retired + 1;
            if (core_enable_buffer && core_execute_buffer && !core_halted_buffer
                && core_instructions_quashed_buffer != 0
                && !core_multi_cycle_instruction_stall_buffer)
                instructions_quashed <= instructions_quashed + core_instructions_quashed_buffer;
            if (core_enable_buffer && core_execute_buffer && !core_halted_buffer
                && !core_instruction_valid_buffer && !core_downstream_halt_buffer && !core_bubble_buffer
                && !core_trigger_override_buffer && !core_multi_cycle_instruction_stall_buffer)
                untriggered_cycles <= untriggered_cycles + 1;
            if (core_enable_buffer && core_execute_buffer && !core_halted_buffer && core_bubble_buffer
                && !core_multi_cycle_instruction_stall_buffer)
                bubbles <= bubbles + 1;
            if (core_enable_buffer && core_execute_buffer && !core_halted_buffer
                && core_control_hazard_bubble_buffer && !core_multi_cycle_instruction_stall_buffer)
                control_hazard_bubbles <= control_hazard_bubbles + 1;
            if (core_enable_buffer && core_execute_buffer && !core_halted_buffer
                && core_data_hazard_bubble_buffer && !core_multi_cycle_instruction_stall_buffer)
                data_hazard_bubbles <= data_hazard_bubbles + 1;
            if (core_enable_buffer && core_execute_buffer && !core_halted_buffer
                && core_predicate_prediction_hit_buffer && !core_multi_cycle_instruction_stall_buffer)
                predicate_prediction_hits <= predicate_prediction_hits + 1;
            if (core_enable_buffer && core_execute_buffer && !core_halted_buffer
                && core_predicate_prediction_miss_buffer && !core_multi_cycle_instruction_stall_buffer)
                predicate_prediction_misses <= predicate_prediction_misses + 1;
            if (core_enable_buffer && core_execute_buffer && !core_halted_buffer
                && core_trigger_override_buffer && !core_multi_cycle_instruction_stall_buffer)
                trigger_overrides <= trigger_overrides + 1;
            if (core_enable_buffer && core_execute_buffer && !core_halted_buffer
                && core_multi_cycle_instruction_stall_buffer)
                multi_cycle_instruction_stalls <= multi_cycle_instruction_stalls + 1;
        end
    end
endmodule
