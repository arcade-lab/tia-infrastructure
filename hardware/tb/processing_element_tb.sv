/*
 * Single processing element testbench.
 */

`timescale 1ps / 1ps

`ifdef ASIC_SYNTHESIS
    `include "processing_element.svh"
`elsif SIMULATION
    `include "../src/processing_element/processing_element.svh"
`endif

`ifdef NETLIST
    `define DUT processing_element_top_wrapper
`else
    `define DUT processing_element
`endif

module processing_element_tb
    #(parameter CLOCK_PERIOD = 2, // ps.
      parameter MAX_TEST_DURATION = 1000000); // ps.

    // --- Internal Logic and Wiring ---

    // Clock, reset, and control signals.
    logic clock, reset, enable, execute, halted, channels_quiescent, router_quiescent, memory_quiescent;

    // Memory-mapped access.
    mmio_if host_interface();
    mmio_if memory_interface();

    // Links.
    interconnect_link_if input_interconnect_links[3:0]();
    interconnect_link_if output_interconnect_links[3:0]();
    link_if input_links[3:0]();
    link_if output_links[3:0]();

    // Combiners and splitters.
    genvar i;
    generate
        for (i = 0; i < 4; i++) begin: il
            interconnect_link_combiner ilc(.input_interconnect_link(output_interconnect_links[i]),
                                           .output_link(output_links[i]));
            interconnect_link_splitter ils(.input_link(input_links[i]),
                                           .output_interconnect_link(input_interconnect_links[i]));
        end
    endgenerate


    // --- DUT ---

    // Instantiate the PE.
    `DUT pe(.clock(clock),
            .reset(reset),
            .enable(enable),
            .execute(execute),
            .halted(halted),
            .channels_quiescent(channels_quiescent),
            .router_quiescent(router_quiescent),
            .host_interface(host_interface),
            .north_input_interconnect_link(input_interconnect_links[0]),
            .east_input_interconnect_link(input_interconnect_links[1]),
            .south_input_interconnect_link(input_interconnect_links[2]),
            .west_input_interconnect_link(input_interconnect_links[3]),
            .north_output_interconnect_link(output_interconnect_links[0]),
            .east_output_interconnect_link(output_interconnect_links[1]),
            .south_output_interconnect_link(output_interconnect_links[2]),
            .west_output_interconnect_link(output_interconnect_links[3]));

    // --- Program ---

    // Prepare the program from the hex file.
    logic [TIA_MMIO_DATA_WIDTH - 1:0] program_words [TIA_NUM_REGISTER_FILE_WORDS + TIA_NUM_INSTRUCTION_MEMORY_WORDS - 1:0];
    initial
        $readmemh("program.hex", program_words);

    // --- Memory ---

    // Instantiate the memory.
    memory_2r_1w #(.DEPTH(TIA_NUM_DATA_MEMORY_WORDS))
        memory(.clock(clock),
               .reset(reset),
               .enable(enable),
               .host_interface(memory_interface),
               .read_index_0_input_link(output_links[0]),
               .read_data_0_output_link(input_links[0]),
               .read_index_1_input_link(output_links[1]),
               .read_data_1_output_link(input_links[1]),
               .write_index_input_link(output_links[2]),
               .write_data_input_link(output_links[3]),
               .quiescent(memory_quiescent));

    // Disable the memory interface.
    assign memory_interface.read_req = 0;
    assign memory_interface.read_index = 0;
    assign memory_interface.write_req = 0;
    assign memory_interface.write_index = 0;
    assign memory_interface.write_data = 0;

    // Preload both banks with input data.
    initial begin
        $readmemh("input_data.hex", memory.dpram0.ram, 32767, 0);
        $readmemh("input_data.hex", memory.dpram1.ram, 32767, 0);
    end

    // --- Housekeeping ---

    // Clean-up the unused links.
    unused_link_sender uls_0(input_links[2]);
    unused_link_sender uls_1(input_links[3]);

    // --- Output File ---

    // Output everything to VCD.
    initial begin
        $dumpfile("processing_element_tb.vcd");
        $dumpvars();
    end

    // --- Clock Generation ---

    // Oscillate for the duration of the test.
    initial begin
        clock = 1;
        repeat (MAX_TEST_DURATION / (CLOCK_PERIOD / 2)) #(CLOCK_PERIOD / 2) clock = !clock;
    end

    // --- Execution Control Tasks ---

    // Reset the PE synchronously.
    task reset_pe;
        execute = 0;
        @(posedge clock);
        reset = 1;
        @(posedge clock);
        reset = 0;
    endtask

    // Enable the PE synchronously.
    task enable_pe;
        @(posedge clock);
        enable = 1;
    endtask

    // Disable the PE synchonously.
    task disable_pe;
        @(posedge clock);
        enable = 0;
    endtask

    // Start execution synchronously.
    task start_pe_execution;
        @(posedge clock);
        execute = 1;
    endtask

    // Stop execution synchonously.
    task stop_pe_execution;
        @(posedge clock);
        execute = 0;
    endtask

    // Will return the first cycle at which halted goes high.
    task wait_for_pe_halt;
        @(posedge halted && channels_quiescent && router_quiescent && memory_quiescent);
        $display("--- at %g ---", $time);
        $display("PE halted.");
        $display("Testbench simulation ended at: %g", $time);
    endtask

    // --- MMIO Access Tasks ---

    // Read form an address over the MMIO interface.
    task read(input logic [TIA_MMIO_INDEX_WIDTH - 1:0] index);
        host_interface.read_req = 1;
        host_interface.read_index = index;
        @(posedge host_interface.read_ack);
        $display("--- at %g ---", $time);
        $display("read index:");
        $display(index);
        $display("read data:");
        $display(host_interface.read_data);
        @(posedge clock);
        host_interface.read_req = 0;
        @(posedge clock);
    endtask

    // Write to an address over the MMIO interface.
    task write(input logic [TIA_MMIO_INDEX_WIDTH - 1:0] index, input logic [TIA_MMIO_DATA_WIDTH - 1:0] data);
        host_interface.write_req = 1;
        host_interface.write_index = index;
        host_interface.write_data = data;
        if (!host_interface.write_ack)
            @(posedge host_interface.write_ack);
        $display("--- at %g ---", $time);
        $display("write_index:");
        $display(index);
        $display("write_data:");
        $display(data);
        @(posedge clock);
        host_interface.write_req = 0;
    endtask

    // --- Programming Tasks ---

    // Write complete program (including registers and invalid/nop instruction padding) into the instruction memory.
    task write_program(input logic [TIA_MMIO_DATA_WIDTH - 1:0] program_words [TIA_NUM_REGISTER_FILE_WORDS + TIA_NUM_INSTRUCTION_MEMORY_WORDS - 1:0]);
        integer i;
        for (i = 0; i < TIA_NUM_REGISTER_FILE_WORDS + TIA_NUM_INSTRUCTION_MEMORY_WORDS; i++)
            write(TIA_CORE_REGISTER_FILE_BASE_INDEX + i, program_words[i]);
    endtask

    // Program the router to the default switch router setting for a single-PE test system.
    `ifndef TIA_SOFTWARE_ROUTER
        task program_router;
            integer i;
            write(TIA_ROUTER_BASE_INDEX, 32'h0b0a0908);
            write(TIA_ROUTER_BASE_INDEX + 1, 32'h00002d24);
            for (i = 2; i < TIA_NUM_PHYSICAL_PLANES + 1; i++)
                write(TIA_ROUTER_BASE_INDEX + i, 32'd0);
        endtask
    `endif

    // --- Main ---

    // Entry point task.
    task main;
        // Initial checks since this is a testbench for a restricted instance of the processing element.
        assert (TIA_NUM_INPUT_CHANNELS == 4);
        assert (TIA_NUM_OUTPUT_CHANNELS == 4);
        assert (TIA_NUM_PHYSICAL_PLANES == 1);
        if ((TIA_NUM_INPUT_CHANNELS != 4) || (TIA_NUM_OUTPUT_CHANNELS != 4) || (TIA_NUM_PHYSICAL_PLANES != 1)) begin
            $display("Invalid settings for testbench.");
            $finish;
        end

        // Temporarily disable the host interface.
        host_interface.read_req = 0;
        host_interface.read_index = 0;
        host_interface.write_req = 0;
        host_interface.write_index = 0;
        host_interface.write_data = 0;

        // Initialize and program the PE.
        reset_pe();
        enable_pe();
        write_program(program_words);
        `ifndef TIA_SOFTWARE_ROUTER
            program_router();
        `endif

        // Run the PE until halt.
        start_pe_execution();
        wait_for_pe_halt();
        $finish;
    endtask

    // Enter the main testbench routine.
    initial begin
        main();
    end
endmodule

