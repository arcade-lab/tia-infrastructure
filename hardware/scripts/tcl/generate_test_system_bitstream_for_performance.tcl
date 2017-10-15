# TODO: Bring up to 2016.4 version of the scripts.

# Import the platform definitions and common utilities.
source scripts/tcl/platforms.tcl
source scripts/tcl/common_zynq_utilities.tcl
source scripts/tcl/automatic_timing_closure_utilities.tcl

# --- Entry Point ---

# Check usage.
if {$argc != 5} {
    puts "ERROR (User Tcl): Usage: vivado -mode batch -source (this script) -tclargs bitstream_name project_dir platform ip_dir ip_module"
    exit 1
}

# Extract the arguments, but assume they are correct, and let Vivado handle any errors.
set bitstream_name_arg [lindex $argv 0]
set project_dir_arg [lindex $argv 1]
set platform_arg [lindex $argv 2]
set ip_dir_arg [lindex $argv 3]
set ip_module_arg [lindex $argv 4]

# Automatically find the f_max for our device starting at 250 MHz.
set frequency [automatically_close 250 $bitstream_name_arg $project_dir_arg $platform_arg $ip_dir_arg $ip_module_arg 0x40000000 1M]

# Only reached if the design closed, so we can write out everything to disk.
generate_and_save_bitstream $project_dir_arg $bitstream_name_arg
generate_reports

# Save the integer value of the final frequency to a text file for future use, e.g., by set_fclk0.sh.
set integer_frequency_file [open integer_frequency.txt w]
puts $integer_frequency_file $frequency
close $integer_frequency_file

# Save the float value of the final frequency to a text file for future use, e.g., by data aggregation scripts.
set float_frequency_file [open float_frequency.txt w]
puts $float_frequency_file [integer_frequency_as_float $platform_arg $frequency]
close $float_frequency_file

# Exit successfully.
exit 0
