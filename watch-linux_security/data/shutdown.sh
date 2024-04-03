#!/bin/bash

#
# job cleanup

# umount the remote filesystems
umount /pjob.data/scratch

# umount our local filesystems
umount /var/tmp
umount /tmp
umount /root

exit 0
