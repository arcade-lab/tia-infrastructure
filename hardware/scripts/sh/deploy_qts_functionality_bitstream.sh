#!/bin/sh

# Set the frequency to 20 MHz.
sshpass -p root scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no scripts/sh/set_fclk0.sh root@192.168.0.2:/home/root
sshpass -p root ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@192.168.0.2 -t "./set_fclk0.sh 20"

# Deploy the frequency getter for future use.
sshpass -p root scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no scripts/sh/get_fclk0.sh root@192.168.0.2:/home/root

# Program the configurable logic.
sshpass -p root scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no qts_functionality.bit root@192.168.0.2:/home/root
sshpass -p root ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@192.168.0.2 -t "cat qts_functionality.bit > /dev/xdevcfg"

# Deploy the reset script.
sshpass -p root scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no scripts/sh/reset_device.sh root@192.168.0.2:/home/root

# Exit successfully.
exit 0
