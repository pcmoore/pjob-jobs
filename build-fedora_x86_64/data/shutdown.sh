#!/bin/bash

#
# job cleanup

# umount the remote filesystems
umount --lazy /pjob.data/repo
umount --lazy /pjob.data/scratch

# umount our local filesystems
umount /var/tmp
umount /tmp
umount /root

# tmp cleanup
rm -rf /pjob.data/tmp/*

exit 0
