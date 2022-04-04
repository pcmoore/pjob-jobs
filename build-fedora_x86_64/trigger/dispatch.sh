#!/bin/bash

# verify the dispatch info is present
[[ ! -r /pjob.vars/dispatchhosts ]] && exit 1

# load our libraries
[[ ! -r /pjob.global/path.sh ]] && exit 1
. /pjob.global/path.sh
[[ ! -r /pjob.global/time.sh ]] && exit 1
. /pjob.global/time.sh

# limit dispatching to Mon-Fri, 7:30a to 6:00p
echo "CHECKING TIME/DATE CONDITIONS"
time_test_weekday || exit 1
time_test_range 7:30 18:00 || exit 1

# TODO - we need a better way of selecting hosts

# pick a target at random
target_host=$(cat /pjob.vars/dispatchhosts | shuf | head -n 1)

# set the target info
echo "TARGET_HOST=$target_host"
echo "TARGET_USER=root"
echo "TARGET_LOCK=1"
# NOTE: the timeout is really large here since we rely on the post hook to
#       shutdown the system, this is really just a failsafe
echo "TARGET_TIMEOUT=43200" # 12h

exit 0
