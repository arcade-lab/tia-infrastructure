#!/bin/sh

# Perform error checking.
set -e

# All parameters.
pipelines="
tdx
tdx1_x2
tdx1_x2_no_ofu
td_x
td_x1_x2
t_dx
t_dx1_x2
t_dx1_x2_no_ofu
t_d_x
t_d_x1_x2
"
spus="
on
off
"
channels="
on
off
"

# Run the design on all parameters.
for pipeline in $pipelines; do
    for spu in $spus; do
        for channel in $channels; do
            test_name=${pipeline}_spu_${spu}_channel_${channel}
            echo
            figlet $test_name
            echo
            qtm $TIA_HARDWARE_DIR/qts_design_cache/${test_name}_qts_functionality/qts_functionality.bit \
                $TIA_HARDWARE_DIR/qts_design_cache/${test_name}_qts_functionality/parameters.json \
                microbenchmarks.json \
                -o ${test_name}.csv
        done
    done
done

# Save the results to their own directory.
mkdir -p fpga_results
mv *.csv fpga_results

# Exit successfully.
exit 0
