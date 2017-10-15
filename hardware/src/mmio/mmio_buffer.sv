/*
 * Buffer for the MMIO protocol.
 */

`include "mmio.svh"

module mmio_buffer(input logic clock, // Positive-edge triggered.
                   input logic reset, // Active high.
                   mmio_if.device host_interface,
                   mmio_if.host device_interface);

    // --- Internal Logic and Wiring ---

    // Internal write buffer length of two to enable zero-latency writes.
    mmio_write_packet_t mmio_write_fifo [1:0];

    // Write buffer state.
    logic head, tail;
    logic [1:0] count;

    // Incoming and outgoing packets.
    mmio_write_packet_t incoming_write_packet, outgoing_write_packet;

    // --- Combinational Logic ---

    // Packing/unpacking write packets.
    assign incoming_write_packet.index = host_interface.write_index;
    assign incoming_write_packet.data = host_interface.write_data;
    assign outgoing_write_packet = mmio_write_fifo[head];

    // Write FIFO logic.
    assign host_interface.write_ack = (host_interface.write_req && count != 2);

    // Offer write packets to the device interface.
    assign device_interface.write_index = mmio_write_fifo[head].index;
    assign device_interface.write_data = mmio_write_fifo[head].data;
    assign device_interface.write_req = (count != 0);

    // --- Sequential Logic ---

    // Read channel.
    always_ff @(posedge clock) begin
        if (reset) begin
            host_interface.read_ack <= 0;
            host_interface.read_data <= 0;
            device_interface.read_req <= 0;
            device_interface.read_index <= 0;
        end else begin
            if (host_interface.read_req && !host_interface.read_ack
                && !device_interface.read_req && !device_interface.read_ack) begin
                device_interface.read_req <= 1;
                device_interface.read_index <= host_interface.read_index;
            end else if (host_interface.read_req && !host_interface.read_ack
                         && device_interface.read_req && device_interface.read_ack) begin
                host_interface.read_ack <= 1;
                host_interface.read_data <= device_interface.read_data;
                device_interface.read_req <= 0;
            end else if (host_interface.read_req && host_interface.read_ack)
                host_interface.read_ack <= 0;
        end
    end

    // Write channel.
    always_ff @(posedge clock) begin
        if (reset) begin
            head <= 0;
            tail <= 0;
            count <= 0;
        end else begin
            if (host_interface.write_ack) begin
                mmio_write_fifo[tail] <= incoming_write_packet;
                if (device_interface.write_req && device_interface.write_ack) begin
                    head <= head + 1;
                    tail <= tail + 1;
                end else begin
                    tail <= tail + 1;
                    count <= count + 1;
                end
            end else begin
                if (device_interface.write_req && device_interface.write_ack) begin
                    head <= head + 1;
                    count <= count - 1;
                end
            end
        end
    end
endmodule
