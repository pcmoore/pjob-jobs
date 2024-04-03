#!/bin/bash

# debug
#set -x

# default - trigger
rc=0

####
# function

function exit_cleanup() {
        cd /pjob.trigger
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

cd /pjob.trigger

touch /pjob.trigger/time.ok

# check for the time delta
timestamp=$(date "+%s")
timestamp_old=$(cat /pjob.trigger/time.ok)
[[ -z $timestamp_old ]] && timestamp_old=0
# 12h = 43200s
#  8h = 28800s
#  6h = 21600s
#  4h = 14400s
#  2h =  7200s
#  1h =  3600s
#  5m =   300s
#  3m =   180s
#  2m =   120s
[[ $(( $timestamp -  $timestamp_old )) -lt 3600  ]] && exit_cleanup

# update the timestamp
echo $timestamp > /pjob.trigger/time.ok

cd /pjob.trigger

#
# cleanup

/pjob.data/shutdown.sh
[[ $? -ne 0 ]] && exit 1

exit $rc
