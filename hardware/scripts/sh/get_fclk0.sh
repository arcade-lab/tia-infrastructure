#!/bin/sh

# Note: to be run on the Zynq ARM processor with Linux 4.0.0 or above.

# Export FCLK0 if it is not already exported.
cd /sys/devices/soc0/amba/f8007000.devcfg
if cat fclk_export | grep -q 'fclk0'; then
    echo 'fclk0' > fclk_export
fi

# Get the frequency.
cd fclk/fclk0
cat set_rate

# Exit successfully.
exit 0
