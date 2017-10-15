#!/bin/sh

# Exit on error.
set -e

# Make sure we are running as root.
if [ "$EUID" -ne 0 ]; then
  echo "Must be run as root."
  exit 1
fi

# Check usage.
if [ $# != 2 ]; then
    echo "Usage ./flash_image.sh IMAGE_FILE_PATH BLOCK_DEVICE."
    exit 1
fi

# Write the image out to flash.
dd if=$1 of=$2 bs=4k
sync

# Exit successfully.
exit 0
