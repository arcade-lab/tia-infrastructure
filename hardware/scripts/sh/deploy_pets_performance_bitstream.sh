#!/bin/sh

# Set the frequency to the freuqncy at which the system closed.
frequency=$(cat integer_frequency.txt)
sshpass -p root scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no scripts/sh/set_fclk0.sh root@192.168.0.2:/home/root
sshpass -p root ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@192.168.0.2 -t "./set_fclk0.sh $frequency"

# Deploy the frequency getter for future use.
sshpass -p root scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no scripts/sh/get_fclk0.sh root@192.168.0.2:/home/root

# Program the configurable logic.
sshpass -p root scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no pets_performance.bit root@192.168.0.2:/home/root
sshpass -p root ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@192.168.0.2 -t "cat pets_performance.bit > /dev/xdevcfg"

# Deploy the reset script.
sshpass -p root scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no scripts/sh/reset_device.sh root@192.168.0.2:/home/root

# Exit successfully.
exit 0
