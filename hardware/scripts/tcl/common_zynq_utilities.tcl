# Import the platform definitions.
source scripts/tcl/platforms.tcl

# --- Utility Functions ---

# Create an empty Zynq project for the relevant parts.
proc create_zynq_project {top_module project_dir source_dir fpga_part board_part} {
    # Empty project targeting the given chip part with automatic board constraints.
    create_project $top_module $project_dir -part $fpga_part -force
    set_property board_part $board_part [current_project]
    add_files $source_dir
    set_property source_mgmt_mode None [current_project]
    set_property top $top_module [current_fileset]
    set_property source_mgmt_mode All [current_project]
}

# Destroy the current Zynq project.
proc destroy_zynq_project {} {
    # Assumes the current project is in scope. This is mainly just an alias as there is no explicit destroy project command.
    close_project -delete -quiet
}

# Encapsulate the Zynq block diagram shenanigans in HDL. This only has a single AXI4-Lite master port exposed.
proc make_basic_zynq_block {top_module project_dir freq_mhz base_address address_space_size} {
    # New block diagram.
    create_bd_design "zynq_block"

    # Use the autoconfig for the GPIO AXI4-Lite module as a template.
    create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0
    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" Clk "Auto" }  [get_bd_intf_pins axi_gpio_0/S_AXI]
    apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]
    set_property -dict [list CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ $freq_mhz] [get_bd_cells processing_system7_0]

    # Remove the GPIO, leaving the interconnect intact.
    delete_bd_objs [get_bd_intf_nets ps7_0_axi_periph_M00_AXI] [get_bd_cells axi_gpio_0]

    # Expose the AXI4-Lite master.
    create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI
    set_property -dict [list CONFIG.PROTOCOL [get_property CONFIG.PROTOCOL [get_bd_intf_pins processing_system7_0/M_AXI_GP0]] CONFIG.HAS_REGION [get_property CONFIG.HAS_REGION [get_bd_intf_pins processing_system7_0/M_AXI_GP0]] CONFIG.NUM_READ_OUTSTANDING [get_property CONFIG.NUM_READ_OUTSTANDING [get_bd_intf_pins processing_system7_0/M_AXI_GP0]] CONFIG.NUM_WRITE_OUTSTANDING [get_property CONFIG.NUM_WRITE_OUTSTANDING [get_bd_intf_pins processing_system7_0/M_AXI_GP0]]] [get_bd_intf_ports M00_AXI]
    connect_bd_intf_net [get_bd_intf_pins ps7_0_axi_periph/M00_AXI] [get_bd_intf_ports M00_AXI]
    create_bd_port -dir O -type clk ACLK
    connect_bd_net [get_bd_pins /processing_system7_0/FCLK_CLK0] [get_bd_ports ACLK]
    create_bd_port -dir O -from 0 -to 0 -type rst ARESETN
    connect_bd_net [get_bd_pins /rst_ps7_0_50M/peripheral_aresetn] [get_bd_ports ARESETN]
    set_property CONFIG.ASSOCIATED_BUSIF {M00_AXI} [get_bd_ports /ACLK]
    set_property CONFIG.PROTOCOL AXI4LITE [get_bd_intf_ports M00_AXI]

    # Set up the memory map.
    assign_bd_address
    set_property range $address_space_size [get_bd_addr_segs {processing_system7_0/Data/SEG_M00_AXI_Reg}]
    set_property offset $base_address [get_bd_addr_segs {processing_system7_0/Data/SEG_M00_AXI_Reg}]
    save_bd_design

    # Make the HDL wrapper.
    make_wrapper -files [get_files ${project_dir}/${top_module}.srcs/sources_1/bd/zynq_block/zynq_block.bd] -top
    add_files -norecurse ${project_dir}/${top_module}.srcs/sources_1/bd/zynq_block/hdl/zynq_block_wrapper.v
}
# Support multiple synthesis/implementation directives.
proc synthesize_and_implement_design {directive} {
    # Keep all messages about nets being inferred away, even if some of the messages are spurious.
    set_msg_config -id {Synth 8-3295} -limit 5000
    set_msg_config -id {Synth 8-3332} -limit 5000
    set_msg_config -id {Synth 8-3333} -limit 5000
    set_msg_config -id {Synth 8-3886} -limit 5000

    # Determine which directive to use.
    if {$directive eq "functionality"} {
        # Synthesize the design as quickly as possible and preserve the module hierarchy for debugging.
        set_property verilog_define FPGA_SYNTHESIS [current_fileset]
        set_property strategy Flow_RuntimeOptimized [get_runs synth_1]
        set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]
        launch_runs synth_1 -jobs 8
        wait_on_run synth_1

        # Implement the design as quickly as possible, too.
        set_property strategy Flow_RuntimeOptimized [get_runs impl_1]
        launch_runs impl_1 -jobs 8
        wait_on_run impl_1
    } elseif {$directive eq "performance"} {
        # No holds barred performance-focused synthesis.
        set_property verilog_define FPGA_SYNTHESIS [current_fileset]
        set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
        set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]
        launch_runs synth_1 -jobs 8
        wait_on_run synth_1

        # Implement the design using extensive performance optimization.
        set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]
        set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
        set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore [get_runs impl_1]
        set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE AddRetime [get_runs impl_1]
        launch_runs impl_1 -jobs 8
        wait_on_run impl_1
    } else {
        # Currently only support the functionality and performance directives.
        puts "ERROR (User Tcl): Unrecognized synthesis/implementation directive: $directive"
        exit 1
    }
}

# Write out the bitstream, and copy it into the directory from which Make was called.
proc generate_and_save_bitstream {top_module project_dir bitstream_file} {
    # The bitstream should be in the impl_1 folder after this.
    launch_runs impl_1 -to_step write_bitstream -jobs 8
    wait_on_run impl_1

    # Copy the bitstream into the working directory.
    file copy ${project_dir}/${top_module}.runs/impl_1/${top_module}.bit $bitstream_file
}

# Create power, timing and utilization reports.
proc generate_reports {} {
    # Open the implementation and write out the reports.
    open_run impl_1 -name impl_1
    report_power -file power_report.txt
    report_timing_summary -file timing_report.txt
    report_utilization -hierarchical  -file utilization_report.txt
}
