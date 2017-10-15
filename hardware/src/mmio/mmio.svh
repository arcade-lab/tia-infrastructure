`ifndef MMIO_SVH
`define MMIO_SVH

/*
 * Static parameters definitions for MMIO. The latency insensitive MMIO interface uses a req/ack
 * protocol for arbitrary delays in reads and writes.
 */

`ifdef ASIC_SYNTHESIS
    `include "derived_parameters.svh"
`elsif FPGA_SYNTHESIS
    `include "derived_parameters.svh"
`elsif SIMULATION
    `include "../derived_parameters.svh"
`else
    `include "derived_parameters.svh"
`endif

// MMIO slave interface.
interface mmio_if;
    logic read_req;
    logic read_ack;
    logic [TIA_MMIO_INDEX_WIDTH - 1:0] read_index;
    logic [TIA_MMIO_DATA_WIDTH - 1:0] read_data;
    logic write_req;
    logic write_ack;
    logic [TIA_MMIO_INDEX_WIDTH - 1:0] write_index;
    logic [TIA_MMIO_DATA_WIDTH - 1:0] write_data;
    modport host(output read_req,
                 input read_ack,
                 output read_index,
                 input read_data,
                 output write_req,
                 input write_ack,
                 output write_index,
                 output write_data);
    modport device(input read_req,
                   output read_ack,
                   input read_index,
                   output read_data,
                   input write_req,
                   output write_ack,
                   input write_index,
                   input write_data);
endinterface

// Write packet.
typedef struct packed {
    logic [TIA_MMIO_INDEX_WIDTH - 1:0] index;
    logic [TIA_MMIO_DATA_WIDTH - 1:0] data;
} mmio_write_packet_t;

`endif // MMIO_SVH
