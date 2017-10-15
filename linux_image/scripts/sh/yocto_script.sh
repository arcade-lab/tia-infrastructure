#!/bin/sh

# Exit on error.
set -e

# Check usage, and parse argument.
if [ $# -ne 1 ]; then
    echo "Usage: ./yocto_script.sh FPGA_PLATFORM"
    exit 1
fi
fpga_platform=$1

# Original directory.
original_directory=$(pwd)

# Tweak the poky image's network interfaces.
cp /linux_image/scripts/res/interfaces poky/meta/recipes-core/init-ifupdown/init-ifupdown-1.0/interfaces

# Source the build environment.
source poky/oe-init-build-env

# Clean any old images.
rm -f *.direct

# Copy the configuration files from the resources directory.
cp /linux_image/scripts/res/bblayers.conf conf
if [ "$fpga_platform" == "zedboard" ]; then
    cp /linux_image/scripts/res/zedboard.conf conf/local.conf
elif [ "$fpga_platform" == "zc706" ]; then
    cp /linux_image/scripts/res/zc706.conf conf/local.conf
else
    echo "Unknown FPGA platform."
    exit 1
fi

# Run bitbake.
bitbake core-image-full-cmdline kernel-devsrc

# Build any prerequisites.
bitbake wic-tools dosfstools-native mtools-native parted-native

# Generate the SD card image.
wic create sdimage-bootpart -e core-image-full-cmdline

# Move the SD card image to the linux image directory.
cp *.direct /linux_image/image.direct
echo "Created the image file at image.direct."

# Save the kernel source as a target for building device drivers.
rm -rf /linux_image/source
cp -R tmp/work/${fpga_platform}_zynq7-poky-linux-gnueabi/kernel-devsrc/1.0-r0/image/usr/src/kernel \
    /linux_image/source
echo "Saved the Linux kernel source at source/."

# Build the SDK.
rm -rf /linux_image/sdk
bitbake meta-toolchain
cp -R tmp/deploy/sdk /linux_image/sdk

# Exit successfully.
exit 0
