#!/bin/bash

# debug
#set -x

####
# function

function exit_cleanup() {
	cd /pjob.data
	/pjob.data/shutdown.sh
	exit 1
}

####
# main

#
# setup

/pjob.data/startup.sh
[[ $? -ne 0 ]] && exit 1

#
# job processing

cd /pjob.data/scratch

# update our scripts
(cd /pjob.data/scratch/copr-pkg_scripts; git pull)

# clean the srpm directory
find /pjob.data/scratch/srpms -mtime +21 | xargs rm -f {}

# generate the patches
./pcopr_patch
[[ $? -ne 0 ]] && exit_cleanup

# generate the srpm and submit the copr build
srpm_build_opts=""
# NOTE: try to do a "fast" build ('-F'), may need to be cleaned if errors occur
#srpm_build_opts+=" -F"
./pcopr_srpm-kernel_rawhide $srpm_build_opts -r auto -b
[[ $? -ne 0 ]] && exit_cleanup

# copy the new srpms to the package repo
rsync /pjob.data/scratch/srpms/*.rpm /pjob.data/repo/rawhide/source

cd /pjob.data

#
# cleanup

/pjob.data/shutdown.sh
[[ $? -ne 0 ]] && exit 1

exit 0
