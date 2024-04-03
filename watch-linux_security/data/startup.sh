#!/bin/bash

#
# job setup

# mount our local filesystems
mount -o bind /pjob.data/home /root
[[ $? -ne 0 ]] && exit 1
mount -o bind /pjob.data/tmp /tmp
[[ $? -ne 0 ]] && exit 1
mount -o bind /pjob.data/tmp /var/tmp
[[ $? -ne 0 ]] && exit 1

# mount the remote filesystems
# TODO: experiment with "lookupcache=none" and "noac" options to work around
#       stale file handles
mount -o async,ac,nolock,noacl,nodiratime,noatime \
        nfs-server.local:/mnt/pool1/jobs/kernel-next_check \
        /pjob.data/scratch
[[ $? -ne 0 ]] && exit 1

exit 0
