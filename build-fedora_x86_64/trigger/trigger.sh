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
touch /pjob.trigger/srpm_list.ok

srpm_list=/pjob.trigger/srpm_list.tmp

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
> $srpm_list
rm -f /pjob.trigger/pkg_todo.txt

# generate a new srpm manifest
for repo in /pjob.data/repo/rawhide/source; do
	#(cd $repo; sha1sum *.src.rpm) >> $srpm_list
	#(cd $repo; stat --format="%Y %n" *.src.rpm) >> $srpm_list
	for pkg in $(cd $repo; ls *.src.rpm); do
		if diff -q <(grep "$pkg" /pjob.trigger/srpm_list.ok | awk '{ print $1 }') <(stat --format="%Y" $repo/$pkg) &> /dev/null; then
			grep "$pkg" /pjob.trigger/srpm_list.ok >> $srpm_list
		else
			(cd $repo; echo $(stat --format="%Y" $pkg) $(sha1sum $pkg)) >> $srpm_list
		fi
	done
done

# sort the package manifest
sort --key 3 $srpm_list > $srpm_list.sorted
mv -f $srpm_list.sorted $srpm_list

# compare the manifests
diff <(awk '{ print $2" "$3 }' /pjob.trigger/srpm_list.ok) \
	<(awk '{ print $2" "$3 }' $srpm_list) | \
	grep "^>" | awk '{ print $3 }' > /pjob.trigger/srpm_list.diff
if [[ $(cat /pjob.trigger/srpm_list.diff | wc -l) -ne 0 ]]; then
	# output the changes for the log
	echo "TRIGGERING PACKAGES"
	cat /pjob.trigger/srpm_list.diff

	# update the manifest
	#cat $srpm_list > /pjob.trigger/srpm_list.ok

	# set the todo list
	# XXX - out of date and disabled
	#diff -u /pjob.trigger/srpm_list.ok $srpm_list | \
	#	tail -n+4 | grep '^+' | cut -c2 -

	# trigger the job
	rc=0
fi

# update the manifest
cat $srpm_list > /pjob.trigger/srpm_list.ok

#
# cleanup

/pjob.data/shutdown.sh
[[ $? -ne 0 ]] && exit 1

exit $rc
