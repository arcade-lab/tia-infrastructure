`ifndef INTERCONNECT_SVH
`define INTERCONNECT_SVH

/*
 * Definitions for packets and link/channel I/O.
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

// Packets on channels.
typedef struct packed {
    logic [TIA_TAG_WIDTH - 1:0] tag;
    logic [TIA_WORD_WIDTH - 1:0] data;
} packet_t;

// Disconnected packet.
`define NULL_PACKET '{tag: {TIA_TAG_WIDTH{1'b0}}, data: {TIA_WORD_WIDTH{1'b0}}}

// Link to send packets unidirectionally.
interface link_if;
    packet_t packet;
    logic req;
    logic ack;
    modport sender(output packet,
                   output req,
                   input ack);
    modport receiver(input packet,
                     input req,
                     output ack);
endinterface

// Bundle of multiple links for the main interconnect fabric.
interface interconnect_link_if;
    logic [TIA_TAG_WIDTH - 1:0] tag_lines [TIA_NUM_PHYSICAL_PLANES - 1:0];
    logic [TIA_WORD_WIDTH - 1:0] data_lines [TIA_NUM_PHYSICAL_PLANES - 1:0];
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] reqs;
    logic [TIA_NUM_PHYSICAL_PLANES - 1:0] acks;
    modport sender(output tag_lines,
                   output data_lines,
                   output reqs,
                   input acks);
    modport receiver(input tag_lines,
                     input data_lines,
                     input reqs,
                     output acks);
endinterface

// Input channel.
interface input_channel_if;
    packet_t packet;
    packet_t next_packet;
    logic dequeue;
    logic empty;
    logic [TIA_CHANNEL_BUFFER_COUNT_WIDTH - 1:0] count;
    modport sender(output packet,
                   output next_packet,
                   input dequeue,
                   output empty,
                   output count);
    modport receiver(input packet,
                     input next_packet,
                     output dequeue,
                     input empty,
                     input count);
endinterface

// Output channel.
interface output_channel_if;
    packet_t packet;
    logic enqueue;
    logic full;
    logic [TIA_CHANNEL_BUFFER_COUNT_WIDTH - 1:0] count;
    modport sender(output packet,
                   output enqueue,
                   input full,
                   input count);
    modport receiver(input packet,
                     input enqueue,
                     output full,
                     output count);
endinterface

`endif // INTERCONNECT_SVH
