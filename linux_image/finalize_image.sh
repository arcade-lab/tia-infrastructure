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
    echo "Usage ./flash_image.sh IMAGE_PATH FPGA_PLATFORM."
    exit 1
fi
image_path=$1
fpga_platform=$2

# Default boot sector begins at the eighth 512-byte block.
mkdir -p /mnt/sd_card_boot
mount -o loop,offset=4096 $image_path /mnt/sd_card_boot

# Find the name of the dtb.
dtb_file=$(ls /mnt/sd_card_boot/*.dtb | sed 's/\/mnt\/sd_card_boot\///')

# Compile the new dtb, and overwrite.
dtc -o $dtb_file scripts/res/${fpga_platform}.dts
mv $dtb_file /mnt/sd_card_boot

# Overwrite the uEnv file.
uenv_file=scripts/res/${fpga_platform}.uEnv.txt
cp $uenv_file /mnt/sd_card_boot

# Clean up.
umount /mnt/sd_card_boot

# Exit successfully.
exit 0
