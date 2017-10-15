# TODO: Bring up to 2016.4 version of the scripts.

# Import the platform definitions and common utilities.
source scripts/tcl/platforms.tcl
source scripts/tcl/common_zynq_utilities.tcl

# --- Utility Functions ---

# Get a list of integer values for the frequency settings we should be considering.
proc get_list_of_possible_frequencies {platform} {
    # Use the default location for the extracted clock data about the Zynq.
    set frequency_list_file_string scripts/res/possible_${platform}_frequencies.txt
    set frequency_list_file [open $frequency_list_file_string r]

    # Build a list going line by line through the file.
    set frequency_list {}
    while {[gets $frequency_list_file line] >= 0} {
        lappend frequency_list [expr int(ceil($line * 1.0 / 1000000))]
    }

    # Close the file.
    close $frequency_list_file

    # Sort the list numerically, and only consider unique frequencies.
    set frequency_list [lsort -integer -unique $frequency_list]

    # Return the list we have built.
    return $frequency_list
}

# Calculate design slack.
proc design_slack {} {
    # Extract the last non-whitespace line from the timing report.
    open_run impl_1 -name impl_1
    set timing_report [report_timing -return_string]
    set timing_report [string trim $timing_report]
    set timing_report_lines [split $timing_report "\n"]
    set last_line [lindex $timing_report_lines end]
    set last_line [regexp -all -inline {\S+} $last_line]

    # Check whether the last line contains the phrase "slack" to make sure it is a valid report.
    if {[lsearch $last_line slack] < 0} {
        puts "ERROR (User Tcl): The timing report contained no mention of slack."
        exit 1
    }

    # Extract the slack value (in ns).
    set slack [lindex $last_line 1]

    # Return the extracted slack.
    return $slack
}

# Check whether a design closed.
proc design_closed {} {
    # Use the helper function.
    if {[design_slack] > 0} {
        return 1
    } else {
        return 0
    }
}

# Unit conversion in floating point.
proc frequency_mhz_to_period_ns {frequency_mhz} {
    # Spread out over multiple expressions for clarity.
    set frequency_hz [expr $frequency_mhz * 1000000.0]
    set period_s [expr 1.0 / $frequency_hz]
    set period_ns [expr $period_s * 1000000000.0]

    # Return the calculated period in ns.
    return $period_ns
}

# Unit conversion in floating point.
proc period_ns_to_frequency_mhz {period_ns} {
    # Spread out over multiple lines for clarity.
    set period_s [expr $period_ns / 1000000000.0]
    set frequency_hz [expr 1.0 / $period_s]
    set frequency_mhz [expr $frequency_hz / 1000000.0]

    # Return the calculated frequency in MHz.
    return $frequency_mhz
}

# Look up the integer frequency closest to the target frequency.
proc valid_integer_frequency {frequency_list float_frequency} {
    # Find the index of the first integer frequency that meets the requirement.
    set integer_frequency_index 0
    set current_guess [lindex $frequency_list $integer_frequency_index]
    while {$current_guess < $float_frequency} {
        incr integer_frequency_index
        set next_guess [lindex $frequency_list $integer_frequency_index]
        if {$next_guess eq ""} {
           return $current_guess ;# Out of bounds.
        }
        set current_guess $next_guess

    }

    # Return the frequency associated with that index.
    return [lindex $frequency_list $integer_frequency_index]
}

# Conversion to float for post-processing, etc.
proc integer_frequency_as_float {platform integer_frequency} {
    # Use the default location for the extracted clock data about the Zynq.
    set frequency_list_file_string scripts/res/possible_${platform}_frequencies.txt
    set frequency_list_file [open $frequency_list_file_string r]

    # Build a list going line by line through the file.
    set frequency_list {}
    while {[gets $frequency_list_file line] >= 0} {
        lappend frequency_list [expr ($line * 1.0) / 1000000.0]
    }

    # Close the file.
    close $frequency_list_file

    # Sort the list numerically, and only consider unique frequencies.
    set frequency_list [lsort -real -unique $frequency_list]

    # Find the first float value not less than the integer frequency.
    set frequency_list_index 0
    while {[lindex $frequency_list $frequency_list_index] < $integer_frequency} {
            incr frequency_list_index
    }

    # The frequency is the one immediately preceding it.
    incr frequency_list_index -1
    return [lindex $frequency_list $frequency_list_index]
}

# Calculate the next frequency on the list.
proc next_frequency_to_try {current_frequency frequency_list slack} {
    # Calculate the next frequency by subtracting the slack from the current period.
    set current_period [frequency_mhz_to_period_ns $current_frequency]
    set next_period [expr $current_period - $slack]
    set next_frequency [period_ns_to_frequency_mhz $next_period]

    # Return an integer value for the next frequency.
    return [valid_integer_frequency $frequency_list $next_frequency]
}

# Perform the long outer-loop search function to find the f_max.
proc automatically_close {starting_frequency bitstream_name project_dir platform ip_dir ip_module base_address address_space_size} {
    # Global variables.
    global fpga_part_map
    global board_part_map

    # The starting frequency should be the device's maximum frequency or there about.
    set frequency $starting_frequency
    puts "\n\n\n\n\n\n\n\n\n\n"
    puts "Starting at a frequency of $frequency MHz."
    puts "\n\n\n\n\n\n\n\n\n\n"

    # Determine the range of frequencies to try.
    set frequency_list [get_list_of_possible_frequencies $platform]

    # Main loop for decreasing the frequency based on the slack.
    set last_attempt_closed 0 ;# It is assumed that the initial frequency will not close.
    while {$last_attempt_closed == 0} {
        # After synthesis, pause to analyze timing.
        create_zynq_project $bitstream_name $project_dir [dict get $fpga_part_map $platform] [dict get $board_part_map $platform]
        build_block_diagram_with_axi_slave_ip $bitstream_name $ip_dir $ip_module $frequency $base_address $address_space_size
        generate_block_diagram_wrapper $bitstream_name $project_dir
        synthesize_and_implement_design performance

        # Based on whether we closed...
        if {[design_closed] == 0} {
            # Find the next frequency among the integer values.
            set slack [design_slack]
            set next_frequency [next_frequency_to_try $frequency $frequency_list $slack]

            # Handle the case where the slack change does not change the frequency.
            if {$next_frequency == $frequency} {
                # Check for the case where we have hit the minimum frequency.
                if {$next_frequency == [lindex $frequency_list 0]} {
                    break
                }

                # Force the frequency lower otherwise.
                set frequency_index [lsearch $frequency_list $frequency]
                set next_frequency [lindex $frequency_list [expr $frequency_index - 1]]
            }

            # On to the next frequency.
            set frequency $next_frequency

            # Write the next frequency out to stdout clearly.
            puts "\n\n\n\n\n\n\n\n\n\n"
            puts "Based on a slack of $slack ns, trying the next frequency of $frequency MHz."
            puts "\n\n\n\n\n\n\n\n\n\n"

            # Start clean at the next iteration.
            destroy_zynq_project
        } else {
            # Exit the loop noting the that we found at least one design that closes.
            set last_attempt_closed 1

            # Write out the closing frequency to stdout clearly.
            puts "\n\n\n\n\n\n\n\n\n\n"
            puts "The design closed at $frequency MHz."
            puts "\n\n\n\n\n\n\n\n\n\n"
        }
    }

    # If the last frequency closed, begin ratcheting up the frequency one notch at a time.
    if {$last_attempt_closed == 1} {
        # Note that we are now beginning the final ascent.
        puts "\n\n\n\n\n\n\n\n\n\n"
        puts "Beginning final frequency ascent to find f_max..."
        puts "\n\n\n\n\n\n\n\n\n\n"

        # We go through each frequency in the list one by one.
        set frequency_list_index [lsearch $frequency_list $frequency]
        while {[design_closed] == 1} {
            # Decrement the index and lookup the next frequency.
            incr frequency_list_index
            set frequency [lindex $frequency_list $frequency_list_index]

            # Note the higher frequency we are attempting.
            puts "\n\n\n\n\n\n\n\n\n\n"
            puts "Trying a higher frequency of $frequency MHz."
            puts "\n\n\n\n\n\n\n\n\n\n"

            # Again pause at synthesis to analyze timing (in the condition of the while loop).
            destroy_zynq_project
            create_zynq_project $bitstream_name $project_dir [dict get $fpga_part_map $platform] [dict get $board_part_map $platform]
            build_block_diagram_with_axi_slave_ip $bitstream_name $ip_dir $ip_module $frequency $base_address $address_space_size
            generate_block_diagram_wrapper $bitstream_name $project_dir
            synthesize_and_implement_design performance
        }

        # If reached we should go back down to the last frequency that worked.
        destroy_zynq_project
        incr frequency_list_index -1
        set frequency [lindex $frequency_list $frequency_list_index]
        puts "\n\n\n\n\n\n\n\n\n\n"
        puts "Returning to the last known good frequency of $frequency MHz."
        puts "\n\n\n\n\n\n\n\n\n\n"

        # Recreate that version.
        create_zynq_project $bitstream_name $project_dir [dict get $fpga_part_map $platform] [dict get $board_part_map $platform]
        build_block_diagram_with_axi_slave_ip $bitstream_name $ip_dir $ip_module $frequency $base_address $address_space_size
        generate_block_diagram_wrapper $bitstream_name $project_dir
        synthesize_and_implement_design performance
    }

    # Give an informative message about the f_max.
    puts "\n\n\n\n\n\n\n\n\n\n"
    puts "The design's f_max is $frequency MHz ([integer_frequency_as_float $platform $frequency] MHz)."
    puts "\n\n\n\n\n\n\n\n\n\n"

    # Return the newly found f_max.
    return $frequency
}
