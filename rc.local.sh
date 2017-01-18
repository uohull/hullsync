#!/bin/bash

# This script runs on startup and ensures the PID is cleared, the queues are empty and the DAVFS folder is mounted
# NB: the script is executed in the context of root, not cottagelabs.

# clear the automation tools PID if it exists (automation tools are run via cron)
su -l cottagelabs -c "rm -f /usr/local/automation-tools/pid.lck"

# mount the DavFS folder
su -l cottagelabs -c "mount /var/hullsync/mount"

# kill any resque processes
su -l cottagelabs -c "pkill resque"

# clear the resque queues and restart
su -l cottagelabs -c "/var/hullsync/process_queues.sh"
