/*
 * A module to terminate an unused host interface.
 */

`include "mmio.svh"

module unused_host_interface
    (mmio_if.device host_interface);

    // Always return zero as the read data.
    assign host_interface.read_data = 0;
    assign host_interface.read_ack = 0;
    assign host_interface.write_ack = 0;
endmodule
