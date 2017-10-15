#!/bin/sh

# Kill any running test executable instance.
killall -9 pete 2> /dev/null
killall -9 qte 2> /dev/null
killall -9 bte 2> /dev/null

# Reset the device.
devmem 0x40000000 32 1
devmem 0x40000000 32 0

# Exit successfully.
exit 0
