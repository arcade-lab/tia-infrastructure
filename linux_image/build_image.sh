#!/bin/sh

# Exit on error.
set -e

# Function to empty out stale containers. (Progress is saved using volumes.)
clean_docker_containers() {
    containers=$(docker ps -aq --no-trunc --filter "name=linux_image")
    if [ "$containers" != "" ]; then
        docker ps -aq --no-trunc --filter "name=linux_image" | xargs docker rm
    fi
}

# Remove any old image.
rm -f image.direct

# Make sure we have a Docker image for TIA.
if [ "$(docker image ls tia | wc -l)" -lt "2" ]; then
    echo "Must have the Docker  image already built."
    exit 1
fi

# Clean out old containers, and pass control the Docker instance.
clean_docker_containers
docker run -it --name linux_image -v $(pwd)/../yocto:/home/build -v $(pwd):/linux_image tia \
    "/linux_image/scripts/sh/yocto_script.sh" $TIA_FPGA_PLATFORM

# Exit successfully.
exit 0

