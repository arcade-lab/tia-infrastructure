/*
 * Block testbench.
 */

`timescale 1ps / 1ps

`ifdef ASIC_SYNTHESIS
    `include "block.svh"
`elsif SIMULATION
    `include "../src/block/block.svh"
`endif

`ifdef NETLIST
    `define DUT block_top_wrapper
`else
    `define DUT block
`endif

module block_tb
    #(parameter CLOCK_PERIOD = 2, // ps.
      parameter MAX_TEST_DURATION = 1000000); // ps.

    // --- Internal Logic and Wiring ---

    // Clock, reset, and control signals.
    logic clock, reset, enable, execute, halted, channels_quiescent, routers_quiescent, memory_quiescent;

    // Memory-mapped access.
    mmio_if host_interface();
    mmio_if memory_interface();

    // Links.
    interconnect_link_if north_input_interconnect_links[3:0]();
    interconnect_link_if east_input_interconnect_links[3:0]();
    interconnect_link_if south_input_interconnect_links[3:0]();
    interconnect_link_if west_input_interconnect_links[3:0]();
    interconnect_link_if north_output_interconnect_links[3:0]();
    interconnect_link_if east_output_interconnect_links[3:0]();
    interconnect_link_if south_output_interconnect_links[3:0]();
    interconnect_link_if west_output_interconnect_links[3:0]();
    link_if north_input_links[3:0]();
    link_if east_input_links[3:0]();
    link_if south_input_links[3:0]();
    link_if west_input_links[3:0]();
    link_if north_output_links[3:0]();
    link_if east_output_links[3:0]();
    link_if south_output_links[3:0]();
    link_if west_output_links[3:0]();

    // Combiners and splitters.
    genvar i;
    generate
        for (i = 0; i < 4; i++) begin: il
            interconnect_link_combiner nilc(.input_interconnect_link(north_output_interconnect_links[i]),
                                            .output_link(north_output_links[i]));
            interconnect_link_combiner eilc(.input_interconnect_link(east_output_interconnect_links[i]),
                                            .output_link(east_output_links[i]));
            interconnect_link_combiner silc(.input_interconnect_link(south_output_interconnect_links[i]),
                                            .output_link(south_output_links[i]));
            interconnect_link_combiner wilc(.input_interconnect_link(west_output_interconnect_links[i]),
                                            .output_link(west_output_links[i]));
            interconnect_link_splitter nils(.input_link(north_input_links[i]),
                                            .output_interconnect_link(north_input_interconnect_links[i]));
            interconnect_link_splitter eils(.input_link(east_input_links[i]),
                                            .output_interconnect_link(east_input_interconnect_links[i]));
            interconnect_link_splitter sils(.input_link(south_input_links[i]),
                                            .output_interconnect_link(south_input_interconnect_links[i]));
            interconnect_link_splitter wils(.input_link(west_input_links[i]),
                                            .output_interconnect_link(west_input_interconnect_links[i]));
        end
    endgenerate

    // --- DUT ---

    // Instantiate the quartet.
    `DUT block(.clock(clock),
               .reset(reset),
               .enable(enable),
               .execute(execute),
               .halted(halted),
               .channels_quiescent(channels_quiescent),
               .routers_quiescent(routers_quiescent),
               .host_interface(host_interface),
               .north_input_interconnect_links(north_input_interconnect_links),
               .east_input_interconnect_links(east_input_interconnect_links),
               .south_input_interconnect_links(south_input_interconnect_links),
               .west_input_interconnect_links(west_input_interconnect_links),
               .north_output_interconnect_links(north_output_interconnect_links),
               .east_output_interconnect_links(east_output_interconnect_links),
               .south_output_interconnect_links(south_output_interconnect_links),
               .west_output_interconnect_links(west_output_interconnect_links));

    // --- Program ---

    // Prepare the program from the hex file.
    logic [TIA_MMIO_DATA_WIDTH - 1:0] program_words [16 * (TIA_NUM_REGISTER_FILE_WORDS + TIA_NUM_INSTRUCTION_MEMORY_WORDS) - 1:0];
    initial
        $readmemh("program.hex", program_words);

    // Router settings.
    `ifndef TIA_SOFTWARE_ROUTER
        logic [TIA_MMIO_DATA_WIDTH - 1:0] router_settings [16 * TIA_ROUTER_SETTING_MEMORY_WORDS - 1:0];
        initial
            $readmemh("router_settings.hex", router_settings);
    `endif

    // --- Memory ---

    // Instantiate the memory.
    memory_4r_1w #(.DEPTH(TIA_NUM_DATA_MEMORY_WORDS))
        memory(.clock(clock),
               .reset(reset),
               .enable(enable),
               .host_interface(memory_interface),
               .read_index_0_input_link(north_output_links[0]),
               .read_data_0_output_link(north_input_links[0]),
               .read_index_1_input_link(north_output_links[1]),
               .read_data_1_output_link(north_input_links[1]),
               .read_index_2_input_link(north_output_links[2]),
               .read_data_2_output_link(north_input_links[2]),
               .read_index_3_input_link(north_output_links[3]),
               .read_data_3_output_link(north_input_links[3]),
               .write_index_input_link(south_output_links[0]),
               .write_data_input_link(south_output_links[1]),
               .quiescent(memory_quiescent));

    // Disable the memory interface.
    assign memory_interface.read_req = 0;
    assign memory_interface.read_index = 0;
    assign memory_interface.write_req = 0;
    assign memory_interface.write_index = 0;
    assign memory_interface.write_data = 0;

    // Preload all four banks with input data.
    initial begin
        $readmemh("input_data.hex", memory.dpram0.ram, 32767, 0);
        $readmemh("input_data.hex", memory.dpram1.ram, 32767, 0);
        $readmemh("input_data.hex", memory.dpram2.ram, 32767, 0);
        $readmemh("input_data.hex", memory.dpram3.ram, 32767, 0);
    end

    // --- Housekeeping ---

    // Clean up unused input links.
    unused_link_sender uls_0(south_input_links[0]);
    unused_link_sender uls_1(south_input_links[1]);
    unused_link_sender uls_2(south_input_links[2]);
    unused_link_sender uls_3(south_input_links[3]);
    unused_link_sender uls_4(east_input_links[0]);
    unused_link_sender uls_5(east_input_links[1]);
    unused_link_sender uls_6(east_input_links[2]);
    unused_link_sender uls_7(east_input_links[3]);
    unused_link_sender uls_8(west_input_links[0]);
    unused_link_sender uls_9(west_input_links[1]);
    unused_link_sender uls_10(west_input_links[2]);
    unused_link_sender uls_11(west_input_links[3]);

    // Clean up unused output links.
    unused_link_receiver ulr_0(south_output_links[2]);
    unused_link_receiver ulr_1(south_output_links[3]);
    unused_link_receiver ulr_2(east_output_links[0]);
    unused_link_receiver ulr_3(east_output_links[1]);
    unused_link_receiver ulr_4(east_output_links[2]);
    unused_link_receiver ulr_5(east_output_links[3]);
    unused_link_receiver ulr_6(west_output_links[0]);
    unused_link_receiver ulr_7(west_output_links[1]);
    unused_link_receiver ulr_8(west_output_links[2]);
    unused_link_receiver ulr_9(west_output_links[3]);

    // --- Output File ---

    // Output everything to VCD.
    initial begin
        $dumpfile("block_tb.vcd");
        $dumpvars();
    end

    // --- Clock Generation ---

    // Oscillate for the duration of the test.
    initial begin
        clock = 1;
        repeat (MAX_TEST_DURATION / (CLOCK_PERIOD / 2)) #(CLOCK_PERIOD / 2) clock = !clock;
    end

    // --- Execution Control Tasks ---

    // Reset the block synchronously.
    task reset_block;
        execute = 0;
        @(posedge clock);
        reset = 1;
        @(posedge clock);
        reset = 0;
    endtask

    // Enable the block synchronously.
    task enable_block;
        @(posedge clock);
        enable = 1;
    endtask

    // Disable the block synchonously.
    task disable_block;
        @(posedge clock);
        enable = 0;
    endtask

    // Start execution synchronously.
    task start_block_execution;
        @(posedge clock);
        execute = 1;
    endtask

    // Stop execution synchonously.
    task stop_block_execution;
        @(posedge clock);
        execute = 0;
    endtask

    // Will return the first cycle at which halted goes high.
    task wait_for_block_halt;
        @(posedge halted);
        $display("--- at %g ---", $time);
        $display("Block halted.");
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

    // --- Programming Functions and Tasks ---

    // Determine the memory map index.
    function int memory_map_index(input integer processing_element_index);
        integer block_row, block_column, quartet_index, quartet_row, quartet_column, processing_element_subindex, m;
        block_row = processing_element_index / 4;
        block_column = processing_element_index % 4;
        quartet_index = 2 * (block_row / 2) + (block_column / 2);
        quartet_row = block_row % 2;
        quartet_column = block_column % 2;
        processing_element_subindex = 2 * quartet_row + quartet_column;
        m = 4 * quartet_index + processing_element_subindex;
        return m;
    endfunction

    // Write a single instruction into the instruciton memory.
    task write_instruction(input integer processing_element_index,
                           input integer instruction_index,
                           input mm_instruction_t instruction);
        integer m, i;
        m = memory_map_index(processing_element_index);
        for (i = 0; i < 4; i++) begin
            write(TIA_NUM_PROCESSING_ELEMENT_ADDRESS_SPACE_WORDS * m
                  + TIA_CORE_INSTRUCTION_MEMORY_BASE_INDEX + 4 * instruction_index + i,
                  instruction[TIA_MMIO_DATA_WIDTH * i+:TIA_MMIO_DATA_WIDTH]);
        end
    endtask

    // Write complete program (including invalid/nop instruction padding) into the instruction memory.
    task write_program(input logic [TIA_MMIO_DATA_WIDTH - 1:0] program_words [16 * (TIA_NUM_REGISTER_FILE_WORDS + TIA_NUM_INSTRUCTION_MEMORY_WORDS) - 1:0]);
        integer i, m, j;
        for (i = 0; i < 16; i++) begin
            m = memory_map_index(i);
            for (j = 0; j < TIA_NUM_REGISTER_FILE_WORDS + TIA_NUM_INSTRUCTION_MEMORY_WORDS; j++) begin
                write(TIA_NUM_PROCESSING_ELEMENT_ADDRESS_SPACE_WORDS * m + TIA_CORE_REGISTER_FILE_BASE_INDEX + j,
                  program_words[i * (TIA_NUM_REGISTER_FILE_WORDS + TIA_NUM_INSTRUCTION_MEMORY_WORDS) + j]);
            end
        end
    endtask

    // Program all the routers.
    `ifndef TIA_SOFTWARE_ROUTER
        task program_routers(input logic [TIA_MMIO_DATA_WIDTH - 1:0] router_settings [16 * TIA_ROUTER_SETTING_MEMORY_WORDS]);
            integer i, m, j;
            for (i = 0; i < 16; i++) begin
                m = memory_map_index(i);
                for (j = 0; j < TIA_ROUTER_SETTING_MEMORY_WORDS; j++) begin
                    write(TIA_NUM_PROCESSING_ELEMENT_ADDRESS_SPACE_WORDS * m + TIA_ROUTER_BASE_INDEX + j,
                          router_settings[TIA_ROUTER_SETTING_MEMORY_WORDS * i + j]);
                end
            end
        endtask
    `endif

    // --- Main ---

    // Entry point task.
    task main;
        // Temporarily disable the host interface.
        host_interface.read_req = 0;
        host_interface.read_index = 0;
        host_interface.write_req = 0;
        host_interface.write_index = 0;
        host_interface.write_data = 0;

        // Initialize and program the block.
        reset_block();
        enable_block();
        write_program(program_words);
        `ifndef TIA_SOFTWARE_ROUTER
            program_routers(router_settings);
        `endif

        // Run the PE until halt.
        start_block_execution();
        wait_for_block_halt();
        $finish;
    endtask

    // Enter the main testbench routine.
    initial begin
        main();
    end
endmodule

