/*
 * Simple 2-bit predicate predictor.
 */

module predicate_predictor
    (input logic clock, // Positive-edge triggered.
     input logic reset, // Active high.
     input logic enable, // Active high.
     input logic datapath_write,
     input logic observed_value,
     output logic prediction);

    // --- Internal Logic and Wiring ---

    // FSM states.
    enum logic [1:0] {STRONGLY_1,
                      WEAKLY_1,
                      WEAKLY_0,
                      STRONGLY_0} current_state, next_state;

    // --- Combinational Logic ---

    // Determine the next state.
    always_comb begin
        if (datapath_write) begin
            unique case (current_state)
                STRONGLY_1:
                    next_state = observed_value ? STRONGLY_1 : WEAKLY_1;
                WEAKLY_1:
                    next_state = observed_value ? STRONGLY_1 : WEAKLY_0;
                WEAKLY_0:
                    next_state = observed_value ? WEAKLY_1 : STRONGLY_0;
                STRONGLY_0:
                    next_state = observed_value ? WEAKLY_0 : STRONGLY_0;
                default:
                    next_state = WEAKLY_0;
            endcase
        end else
            next_state = current_state;
    end

    // Expose the prediction.
    always_comb begin
        unique case (current_state)
            STRONGLY_1, WEAKLY_1:
                prediction = 1;
            WEAKLY_0, STRONGLY_0:
                prediction = 0;
            default:
                prediction = 0;
        endcase
    end

    // --- Sequential Logic ---

    // Latch in the next state.
    always_ff @(posedge clock) begin
        if (reset)
            current_state <= WEAKLY_0; // Predicates are initially zero anyway.
        else if (enable)
            current_state <= next_state;
    end
endmodule
