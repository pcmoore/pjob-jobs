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

rc=0

#
# setup

/pjob.data/startup.sh
/bin/true
[[ $? -ne 0 ]] && exit 1

#
# main

cd /pjob.data

# override our path
PATH=/usr/local/sbin:/sbin:/usr/sbin:/usr/local/bin:/bin:/usr/bin
export PATH

# start a shell for interactive use
(cd /pjob.data/scratch; /bin/bash)

cd /pjob.data

#
# cleanup

/pjob.data/shutdown.sh
[[ $? -ne 0 ]] && exit 1

exit $rc
