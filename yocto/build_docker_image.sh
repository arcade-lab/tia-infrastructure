#!/bin/sh

# Exit on error.
set -e

# Only add to the image list if necessary.
if [ "$(docker image ls tia | wc -l)" -ge "2" ]; then
    echo "An image with the tag \"tia\" already exists. Build skipped."
else
    docker build -t tia .
fi

# Exit successfully.
exit 0

