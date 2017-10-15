#!/bin/sh

# Exit on error.
set -e

if [ ! -d sdk ]; then
    echo "Must build the image first."
    exit 1
fi

# Just run the install script (image included within) and exit.
sdk/*.sh
exit 0
