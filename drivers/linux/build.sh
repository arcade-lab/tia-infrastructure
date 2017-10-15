#!/bin/sh

source $TIA_POKY_SDK_ENVIRONMENT_SCRIPT
pushd ../../linux_image/source
make scripts
popd
make
