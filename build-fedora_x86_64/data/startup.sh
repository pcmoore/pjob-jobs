#!/bin/bash

#
# job setup

# mount our local filesystems
mount -o bind /pjob.data/home /root
[[ $? -ne 0 ]] && exit 1
mount -o rw,nodev,nosuid -t tmpfs tmpfs /tmp
[[ $? -ne 0 ]] && exit 1
mount -o bind /pjob.data/tmp /var/tmp
[[ $? -ne 0 ]] && exit 1

# mount the remote filesystems
mount -o async,ac,nolock,noacl,nodiratime,noatime \
	nfs-server.local:/mnt/pool1/jobs/x86-rpmbuild \
	/pjob.data/scratch
[[ $? -ne 0 ]] && exit 1
mount -o async,ac,noacl,nodiratime,noatime \
	nfs-server.local:/mnt/pool1/packages \
	/pjob.data/repo
[[ $? -ne 0 ]] && exit 1

exit 0
