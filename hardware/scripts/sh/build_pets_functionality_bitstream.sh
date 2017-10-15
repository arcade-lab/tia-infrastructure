#!/bin/sh

# Check usage, and get the platform.
if [ $# -ne 1 ]; then
    echo 'Usage: ./build_pets_functionality_bitstream.sh fpga_platform.'
    exit 1;
fi
fpga_platform=$1

# Make sure the environment is set up.
source $XILINX_VIVADO_DIR/settings64.sh

# Make a fresh workspace directory.
rm -frv workspace
mkdir -p workspace

# Have Vivado make the bitstream.
vivado -mode batch -source scripts/tcl/generate_test_system_bitstream_for_functionality.tcl -tclargs processing_element_test_system_top workspace/zynq_project $fpga_platform pets_functionality.bit | tee vivado_build_log.txt
if grep -E '^ERROR' vivado_build_log.txt; then
    echo
    echo 'Vivado failed to generate the bitstream.'
    echo 'See vivado_build_log.txt for more information.'
    echo
    exit 1
fi

# Show that the job has been completed.
echo
echo 'pets_functionality.bit generated successfully.'
echo

# Remove any logs to clean up the main directory.
rm -frv webtalk* vivado*.log vivado*.jou

# Exit successfully.
exit 0
