#!/bin/bash

# debug
#set -x

# default - do not trigger
rc=1

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
[[ $(( $timestamp -  $timestamp_old )) -lt 120  ]] && exit_cleanup

# update the timestamp
echo $timestamp > /pjob.trigger/time.ok

# reset
heads_tmp=/pjob.trigger/heads.tmp
heads_diff=/pjob.trigger/heads.diff
rm -f $heads_tmp.tmp
> $heads_tmp
> $heads_diff

# git branches to watch
repo_refs=""
repo_refs+=" selinux/stable-* selinux/next"
repo_refs+=" audit/stable-* audit/next"

# generate the repo git-ref manifest
repo_src=/pjob.data/scratch/linux-sources
(cd $repo_src; git remote update > /dev/null)
for i in $repo_refs; do
	(cd $repo_src; git show-ref) | grep "refs/remotes/$i" >> $heads_tmp
done

# add the kernel package tag to the manifest
cp $heads_tmp $heads_tmp.tmp
(cd /pjob.data/scratch; ./pcopr_srpm-kernel_rawhide -F -V) 2> /dev/null | \
	grep "^package version:" | \
	sed -e 's/^package version:[ \t]*\(.*\)/\1/' >> $heads_tmp
# check to see if the command above failed
diff $heads_tmp $heads_tmp.tmp >& /dev/null && exit_cleanup

# compare the last and current manifests
diff /pjob.trigger/heads.ok $heads_tmp > $heads_diff
if grep -q "^>" $heads_diff; then
	# output the changes for the log
	echo "TRIGGERING CHANGES"
	cat $heads_diff | grep "^>"

	# trigger the job
	rc=0
fi

# update the manifest
cat $heads_tmp > /pjob.trigger/heads.ok

cd /pjob.trigger

#
# cleanup

/pjob.data/shutdown.sh
[[ $? -ne 0 ]] && exit 1

exit $rc
