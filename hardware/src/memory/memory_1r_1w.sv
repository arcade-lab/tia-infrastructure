/*
 * A single RAM memory with one read port and one write port. It also allows for memory mapped
 * access. We assume that the driver will not access the memory directly while the system is
 * executing.
 */

`include "memory.svh"

module memory_1r_1w
    #(parameter DEPTH = 1024)
    (input logic clock, // Positive-edge triggered.
     input logic reset, // Active high.
     input logic enable, // Active high.
     mmio_if.device host_interface,
     link_if.receiver read_index_input_link,
     link_if.sender read_data_output_link,
     link_if.receiver write_index_input_link,
     link_if.receiver write_data_input_link,
     output logic quiescent);

    // --- Internal Logic and Wiring ---

    // Logic for multiplexing between PE and memory-mapped access.
    logic rp_read_enable, wp_write_enable;
    logic read_enable, write_enable;
    logic [TIA_WORD_WIDTH - 1:0] rp_read_index, rp_read_data, wp_write_index, wp_write_data;
    logic [TIA_WORD_WIDTH - 1:0] read_index, read_data, write_index, write_data;

    // Quiescent status.
    logic rp_quiescent, wp_quiescent;

    // Read port.
    read_port rp(.clock(clock),
                 .reset(reset),
                 .enable(enable),
                 .read_index_input_link(read_index_input_link),
                 .read_data_output_link(read_data_output_link),
                 .read_enable(rp_read_enable),
                 .read_index(rp_read_index),
                 .read_data(rp_read_data),
                 .quiescent(rp_quiescent));

    // Write port.
    write_port wp(.clock(clock),
                  .reset(reset),
                  .enable(enable),
                  .write_index_input_link(write_index_input_link),
                  .write_data_input_link(write_data_input_link),
                  .write_enable(wp_write_enable),
                  .write_index(wp_write_index),
                  .write_data(wp_write_data),
                  .quiescent(wp_quiescent));

    // Single RAM of adjustable size.
    dual_port_ram #(.WIDTH(TIA_WORD_WIDTH),
                    .DEPTH(DEPTH))
        dpram(.clock(clock),
              .read_enable(read_enable),
              .read_index(read_index[$clog2(DEPTH) - 1:0]),
              .read_data(read_data),
              .write_enable(write_enable),
              .write_index(write_index[$clog2(DEPTH) - 1:0]),
              .write_data(write_data));

    // --- Combinational Logic ---

    // Multiplex between PE and memory-mapped acces.
    assign read_enable = rp_read_enable | host_interface.read_req;
    assign write_enable = wp_write_enable | host_interface.write_req;
    assign read_index = host_interface.read_req ? host_interface.read_index : rp_read_index;
    assign rp_read_data = read_data;
    assign host_interface.read_data = read_data;
    assign write_index = host_interface.write_req ? host_interface.write_index : wp_write_index;
    assign write_data = host_interface.write_req ? host_interface.write_data : wp_write_data;

    // Writes are registered immediately.
    assign host_interface.write_ack = host_interface.write_req;

    // --- Sequential Logic ---

    // Handle reads.
    always_ff @(posedge clock) begin
        if (reset)
            host_interface.read_ack <= 0;
        else if (enable) begin
            if (host_interface.read_req && !host_interface.read_ack)
                host_interface.read_ack <= 1;
            else if (host_interface.read_req && host_interface.read_ack)
                host_interface.read_ack <= 0;
        end
    end

    // Show whether our buffers are empty.
    always_ff @(posedge clock) begin
        if (reset)
            quiescent <= 0;
        else if (enable)
            quiescent <= rp_quiescent && wp_quiescent;
    end
endmodule
