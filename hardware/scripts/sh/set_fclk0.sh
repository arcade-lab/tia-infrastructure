#!/bin/sh

# Note: to be run on the Zynq ARM processor with Linux 4.0.0 or above.

# Parse the frequency.
if [ "$#" -ne "1" ]; then
    echo "Usage: ./set_fclk0.sh [frequency in MHz]."
    exit 1
fi
frequency_mhz=$1

# Make sure the frequency is not too high.
if [ "$frequency_mhz" -gt 250 ]; then
    echo "$frequency_mhz MHz is too high for FCLK0."
    exit 1
fi

# Export FCLK0.
cd /sys/devices/soc0/amba/f8007000.devcfg
if cat fclk_export | grep -q 'fclk0'; then
    echo 'fclk0' > fclk_export
fi

# Set the frequency.
cd fclk/fclk0
echo "$(($frequency_mhz * 1000000))" > set_rate

# Exit successfully.
exit 0
