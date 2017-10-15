# Import the platform definitions and common utilities.
source scripts/tcl/platforms.tcl
source scripts/tcl/common_zynq_utilities.tcl

# --- Entry Point ---

# Check usage.
if {$argc != 4} {
    puts "ERROR (User Tcl): Usage: vivado -mode batch -source (this script) -tclargs top_module project_dir platform bitstream_file"
    exit 1
}

# Extract the arguments, but assume they are correct, and let Vivado handle any errors.
set top_module_arg [lindex $argv 0]
set project_dir_arg [lindex $argv 1]
set platform_arg [lindex $argv 2]
set bitstream_file_arg [lindex $argv 3]

# Run the utility.
create_zynq_project $top_module_arg $project_dir_arg src [dict get $fpga_part_map $platform_arg] [dict get $board_part_map $platform_arg]
make_basic_zynq_block $top_module_arg $project_dir_arg 20 0x40000000 4M
synthesize_and_implement_design functionality
generate_and_save_bitstream $top_module_arg $project_dir_arg $bitstream_file_arg
generate_reports

# Exit successfully.
exit 0
