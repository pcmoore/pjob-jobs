#!/bin/bash

#
# job cleanup

# umount the remote filesystems
umount /pjob.data/repo
umount /pjob.data/scratch

# umount our local filesystems
umount /var/tmp
umount /tmp
umount /root

# tmp cleanup
rm -rf /pjob.data/tmp/*

exit 0
