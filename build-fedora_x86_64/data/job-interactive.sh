#!/bin/bash

# debug
#set -x

####
# config

build_arch=$(uname -m)

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

PJOB_VAR_HOST="unknown"
PJOB_VAR_JOB_ID="X"
[[ -r /pjob.vars/hostinfo ]] && . /pjob.vars/hostinfo

/pjob.data/startup.sh
[[ $? -ne 0 ]] && exit 1

#
# job processing 

cd /pjob.data/scratch

# override our path
PATH=/usr/local/sbin:/sbin:/usr/sbin:/usr/local/bin:/bin:/usr/bin
export PATH

# interactive shell
/bin/bash

cd /pjob.data

#
# cleanup

/pjob.data/shutdown.sh
[[ $? -ne 0 ]] && exit 1

exit $rc
