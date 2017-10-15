#!/bin/sh

# TODO: Bring up to 2016.4 version of the scripts.

# Check usage, and get the platform.
if [ $# -ne 1 ]; then
    echo 'Usage: ./build_bts_functionality_bitstream.sh fpga_platform.'
    exit 1;
fi
fpga_platform=$1

# Make sure the environment is set up.
source $XILINX_VIVADO_DIR/settings64.sh

# Make a fresh workspace directory.
rm -frv workspace
mkdir -p workspace

# Have Vivado package the IP.
vivado -mode batch -source scripts/tcl/package_test_system_ip.tcl -tclargs block_test_system workspace/block_test_system src $fpga_platform workspace/block_test_system_ip | tee vivado_packaging_log.txt
if grep -E '^ERROR' vivado_packaging_log.txt; then
    echo
    echo 'Vivado failed to package the IP.'
    echo 'See vivado_packaging_log.txt for more information.'
    echo
    exit 1
fi

# Have Vivado make the bitstream.
vivado -mode batch -source scripts/tcl/generate_test_system_bitstream_for_performance.tcl -tclargs bts_performance workspace/zynq_project $fpga_platform workspace/block_test_system_ip block_test_system | tee vivado_build_log.txt
if grep -E '^ERROR' vivado_build_log.txt; then
    echo
    echo 'Vivado failed to generate the bitstream.'
    echo 'See vivado_build_log.txt for more information.'
    echo
    exit 1
fi

# Show that the job has been completed.
echo
echo 'bts_performance.bit generated successfully.'
echo

# Remove any logs to clean up the main directory.
rm -frv webtalk* vivado*.log vivado*.jou

# Exit successfully.
exit 0
