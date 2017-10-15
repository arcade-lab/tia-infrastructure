/*
 * Split a single memory-mapped address space into four equal subspaces.
 */

`include "mmio.svh"

module four_way_address_space_splitter
    #(parameter NUM_SUBSPACE_WORDS = TIA_NUM_CORE_ADDRESS_SPACE_WORDS)
    (mmio_if.device host_interface,
     mmio_if.host first_device_interface,
     mmio_if.host second_device_interface,
     mmio_if.host third_device_interface,
     mmio_if.host fourth_device_interface);

    // --- Local Parameters ---

    // Memory map.
    localparam FIRST_DEVICE_BASE_INDEX = 0;
    localparam FIRST_DEVICE_BOUND_INDEX = NUM_SUBSPACE_WORDS;
    localparam SECOND_DEVICE_BASE_INDEX = FIRST_DEVICE_BOUND_INDEX;
    localparam SECOND_DEVICE_BOUND_INDEX = SECOND_DEVICE_BASE_INDEX
                                           + NUM_SUBSPACE_WORDS;
    localparam THIRD_DEVICE_BASE_INDEX = SECOND_DEVICE_BOUND_INDEX;
    localparam THIRD_DEVICE_BOUND_INDEX = THIRD_DEVICE_BASE_INDEX
                                          + NUM_SUBSPACE_WORDS;
    localparam FOURTH_DEVICE_BASE_INDEX = THIRD_DEVICE_BOUND_INDEX;
    localparam FOURTH_DEVICE_BOUND_INDEX = FOURTH_DEVICE_BASE_INDEX
                                           + NUM_SUBSPACE_WORDS;

    // --- Combinational Logic ---

    // Map reads.
    always_comb begin
        if (host_interface.read_req) begin
            if (host_interface.read_index >= FIRST_DEVICE_BASE_INDEX
                && host_interface.read_index < FIRST_DEVICE_BOUND_INDEX) begin
                first_device_interface.read_req = host_interface.read_req;
                first_device_interface.read_index = host_interface.read_index;
                host_interface.read_ack = first_device_interface.read_ack;
                host_interface.read_data = first_device_interface.read_data;
                second_device_interface.read_req = 0;
                second_device_interface.read_index = 0;
                third_device_interface.read_req = 0;
                third_device_interface.read_index = 0;
                fourth_device_interface.read_req = 0;
                fourth_device_interface.read_index = 0;
            end else if (host_interface.read_index >= SECOND_DEVICE_BASE_INDEX
                         && host_interface.read_index < SECOND_DEVICE_BOUND_INDEX) begin
                first_device_interface.read_req = 0;
                first_device_interface.read_index = 0;
                second_device_interface.read_req = host_interface.read_req;
                second_device_interface.read_index = host_interface.read_index
                                                     - SECOND_DEVICE_BASE_INDEX;
                host_interface.read_ack = second_device_interface.read_ack;
                host_interface.read_data = second_device_interface.read_data;
                third_device_interface.read_req = 0;
                third_device_interface.read_index = 0;
                fourth_device_interface.read_req = 0;
                fourth_device_interface.read_index = 0;
            end else if (host_interface.read_index >= THIRD_DEVICE_BASE_INDEX
                         && host_interface.read_index < THIRD_DEVICE_BOUND_INDEX) begin
                first_device_interface.read_req = 0;
                first_device_interface.read_index = 0;
                second_device_interface.read_req = 0;
                second_device_interface.read_index = 0;
                third_device_interface.read_req = host_interface.read_req;
                third_device_interface.read_index = host_interface.read_index
                                                    - THIRD_DEVICE_BASE_INDEX;
                host_interface.read_ack = third_device_interface.read_ack;
                host_interface.read_data = third_device_interface.read_data;
                fourth_device_interface.read_req = 0;
                fourth_device_interface.read_index = 0;
            end else if (host_interface.read_index >= FOURTH_DEVICE_BASE_INDEX
                         && host_interface.read_index < FOURTH_DEVICE_BOUND_INDEX) begin
                first_device_interface.read_req = 0;
                first_device_interface.read_index = 0;
                second_device_interface.read_req = 0;
                second_device_interface.read_index = 0;
                third_device_interface.read_req = 0;
                third_device_interface.read_index = 0;
                fourth_device_interface.read_req = host_interface.read_req;
                fourth_device_interface.read_index = host_interface.read_index
                                                     - FOURTH_DEVICE_BASE_INDEX;
                host_interface.read_ack = fourth_device_interface.read_ack;
                host_interface.read_data = fourth_device_interface.read_data;
            end else begin
                host_interface.read_ack = 0;
                host_interface.read_data = 0;
                first_device_interface.read_req = 0;
                first_device_interface.read_index = 0;
                second_device_interface.read_req = 0;
                second_device_interface.read_index = 0;
                third_device_interface.read_req = 0;
                third_device_interface.read_index = 0;
                fourth_device_interface.read_req = 0;
                fourth_device_interface.read_index = 0;
            end
        end else begin
            host_interface.read_ack = 0;
            host_interface.read_data = 0;
            first_device_interface.read_req = 0;
            first_device_interface.read_index = 0;
            second_device_interface.read_req = 0;
            second_device_interface.read_index = 0;
            third_device_interface.read_req = 0;
            third_device_interface.read_index = 0;
            fourth_device_interface.read_req = 0;
            fourth_device_interface.read_index = 0;
        end
    end

    // Map writes.
    always_comb begin
        if (host_interface.write_req) begin
            if (host_interface.write_index >= FIRST_DEVICE_BASE_INDEX
                && host_interface.write_index < FIRST_DEVICE_BOUND_INDEX) begin
                first_device_interface.write_req = host_interface.write_req;
                first_device_interface.write_index = host_interface.write_index;
                first_device_interface.write_data = host_interface.write_data;
                host_interface.write_ack = first_device_interface.write_ack;
                second_device_interface.write_req = 0;
                second_device_interface.write_index = 0;
                second_device_interface.write_data = 0;
                third_device_interface.write_req = 0;
                third_device_interface.write_index = 0;
                third_device_interface.write_data = 0;
                fourth_device_interface.write_req = 0;
                fourth_device_interface.write_index = 0;
                fourth_device_interface.write_data = 0;
            end else if (host_interface.write_index >= SECOND_DEVICE_BASE_INDEX
                         && host_interface.write_index < SECOND_DEVICE_BOUND_INDEX) begin
                first_device_interface.write_req = 0;
                first_device_interface.write_index = 0;
                first_device_interface.write_data = 0;
                second_device_interface.write_req = host_interface.write_req;
                second_device_interface.write_index = host_interface.write_index
                                                      - SECOND_DEVICE_BASE_INDEX;
                second_device_interface.write_data = host_interface.write_data;
                host_interface.write_ack = second_device_interface.write_ack;
                third_device_interface.write_req = 0;
                third_device_interface.write_index = 0;
                third_device_interface.write_data = 0;
                fourth_device_interface.write_req = 0;
                fourth_device_interface.write_index = 0;
                fourth_device_interface.write_data = 0;
            end else if (host_interface.write_index >= THIRD_DEVICE_BASE_INDEX
                         && host_interface.write_index < THIRD_DEVICE_BOUND_INDEX) begin
                first_device_interface.write_req = 0;
                first_device_interface.write_index = 0;
                first_device_interface.write_data = 0;
                second_device_interface.write_req = 0;
                second_device_interface.write_index = 0;
                second_device_interface.write_data = 0;
                third_device_interface.write_req = host_interface.write_req;
                third_device_interface.write_index = host_interface.write_index
                                                     - THIRD_DEVICE_BASE_INDEX;
                third_device_interface.write_data = host_interface.write_data;
                host_interface.write_ack = third_device_interface.write_ack;
                fourth_device_interface.write_req = 0;
                fourth_device_interface.write_index = 0;
                fourth_device_interface.write_data = 0;
            end else if (host_interface.write_index >= FOURTH_DEVICE_BASE_INDEX
                         && host_interface.write_index < FOURTH_DEVICE_BOUND_INDEX) begin
                first_device_interface.write_req = 0;
                first_device_interface.write_index = 0;
                first_device_interface.write_data = 0;
                second_device_interface.write_req = 0;
                second_device_interface.write_index = 0;
                second_device_interface.write_data = 0;
                third_device_interface.write_req = 0;
                third_device_interface.write_index = 0;
                third_device_interface.write_data = 0;
                fourth_device_interface.write_req = host_interface.write_req;
                fourth_device_interface.write_index = host_interface.write_index
                                                      - FOURTH_DEVICE_BASE_INDEX;
                fourth_device_interface.write_data = host_interface.write_data;
                host_interface.write_ack = fourth_device_interface.write_ack;
            end else begin
                host_interface.write_ack = 0;
                first_device_interface.write_req = 0;
                first_device_interface.write_index = 0;
                first_device_interface.write_data = 0;
                second_device_interface.write_req = 0;
                second_device_interface.write_index = 0;
                second_device_interface.write_data = 0;
                third_device_interface.write_req = 0;
                third_device_interface.write_index = 0;
                third_device_interface.write_data = 0;
                fourth_device_interface.write_req = 0;
                fourth_device_interface.write_index = 0;
                fourth_device_interface.write_data = 0;
            end
        end else begin
            host_interface.write_ack = 0;
            first_device_interface.write_req = 0;
            first_device_interface.write_index = 0;
            first_device_interface.write_data = 0;
            second_device_interface.write_req = 0;
            second_device_interface.write_index = 0;
            second_device_interface.write_data = 0;
            third_device_interface.write_req = 0;
            third_device_interface.write_index = 0;
            third_device_interface.write_data = 0;
            fourth_device_interface.write_req = 0;
            fourth_device_interface.write_index = 0;
            fourth_device_interface.write_data = 0;
        end
    end
endmodule
