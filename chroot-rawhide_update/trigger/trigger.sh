#!/bin/bash

# debug
#set -x

# default - trigger
rc=0

####
# function

function exit_cleanup() {
	cd /pjob.trigger
	exit 1
}

####
# main

#
# setup

# N/A

#
# job processing

cd /pjob.trigger

touch /pjob.trigger/time.ok

# check for the time delta
timestamp=$(date "+%s")
timestamp_old=$(cat /pjob.trigger/time.ok)
[[ -z $timestamp_old ]] && timestamp_old=0
# 24h = 86400s
# 12h = 43200s
#  8h = 28800s
#  6h = 21600s
#  4h = 14400s
#  2h =  7200s
#  1h =  3600s
#  5m =   300s
[[ $(( $timestamp -  $timestamp_old )) -lt 86400  ]] && exit_cleanup

# update the timestamp
echo $timestamp > /pjob.trigger/time.ok

#
# cleanup

# N/A

exit $rc
