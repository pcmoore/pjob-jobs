#!/bin/bash

# debug
#set -x

####
# config

build_arch=$(uname -m)

####
# function

function rpm_cleanup() {
	# skip if we are on tmpfs
	[[ -d $tmpfsdir ]] && return 0

	(cd $rpmbuild_dir;
		rm -rf BUILD/*;
		rm -rf BUILDROOT/*;
		rm -rf RPMS/noarch/*;
		rm -rf RPMS/$build_arch/*;
		rm -rf SOURCES/*;
		rm -rf SPECS/*;
		rm -rf SRPMS/*;
		rm -rf tmp/*)
	return 0
}

function tmpdir_cleanup () {
	[[ -d $tmpfsdir ]] && umount $tmpfsdir
	[[ -d $tdir ]] && rm -rf $tdir
	return 0
}

function exit_cleanup() {
	rpm_cleanup
	tpmdir_cleanup

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

# generate a temporary build directory
tdir=""
tmpfsdir=""
if [[ -x /pjob.global/tmpfs.sh && -d /pjob.data/t ]]; then
	tdir=$(mktemp -d -p /pjob.data/t -t $PJOB_VAR_HOST-$PJOB_VAR_JOB_ID-XXXX)
	/pjob.global/tmpfs.sh 64G $tdir && tmpfsdir=$tdir
	rpmbuild_dir=$tdir
else
	tdir=$(mktemp -d -p /pjob.data/scratch/t -t $PJOB_VAR_HOST-$PJOB_VAR_JOB_ID-XXXX)
fi
rpmbuild_dir=$tdir

# setup the build directory
> /pjob.data/home/.rpmmacros
echo "%_topdir $rpmbuild_dir" >> /pjob.data/home/.rpmmacros
echo "%_tmppath $rpmbuild_dir/tmp" >> /pjob.data/home/.rpmmacros
mkdir -p $rpmbuild_dir/{BUILD,BUILDROOT,RPMS/noarch,RPMS/$build_arch,SOURCES,SPECS,SRPMS,tmp}

srpm_dir=/pjob.data/repo/rawhide/source
cksum_cmd=sha1sum

# reset the srpm lists
list_built=/pjob.data/scratch/pkg_built.txt
list_failed=/pjob.data/scratch/pkg_failed.txt
touch $list_built
touch $list_failed
> /pjob.data/pkg_todo.txt
> /pjob.data/pkg_tmp_built.txt
> /pjob.data/pkg_tmp_failed.txt

if [[ ! -r /pjob.trigger/pkg_todo.txt ]]; then
	# generate the srpm list to build
	ls -t $srpm_dir/*.src.rpm > /pjob.data/pkg_avail.txt

	# process the srpm lists
	while read pkg; do
		pkg_sum="$($cksum_cmd $pkg)"
		if grep -q "^$pkg_sum" $list_failed >& /dev/null; then
			echo "$pkg_sum" >> /pjob.data/pkg_tmp_failed.txt
		elif grep -q "^$pkg_sum" $list_built >& /dev/null; then
			echo "$pkg_sum" >> /pjob.data/pkg_tmp_built.txt
		else
			echo $pkg >> /pjob.data/pkg_todo.txt
		fi
	done < /pjob.data/pkg_avail.txt

	# update the built and failed list
	mv /pjob.data/pkg_tmp_built.txt $list_built
	mv /pjob.data/pkg_tmp_failed.txt $list_failed
else
	# transfer the srpm list from the trigger
	mv /pjob.trigger/pkg_todo.txt /pjob.data/pkg_todo.txt
fi

# build the srpms on the todo list
> /pjob.data/pkg_tmp_built.txt
> /pjob.data/pkg_tmp_failed.txt
while read pkg; do
	# cleanup the rpm build directory
	rpm_cleanup

	# build the srpm
	# NOTE: use "--noclean" since %clean can be broken, we cleanup anyway
	pkg_sum="$($cksum_cmd $pkg)"
	rpmbuild --noclean --rebuild $pkg
	build_rc=$?
	[[ $build_rc -ne 0 ]] && rc=1

	# copy the packages to the repo
	for arch in $(ls $rpmbuild_dir/RPMS); do
		if ls $rpmbuild_dir/RPMS/$arch/*.rpm >& /dev/null; then
			cp -a -f $rpmbuild_dir/RPMS/$arch/*.rpm \
				/pjob.data/repo/rawhide/$build_arch
		fi
	done

	# update the built and failed list
	if [[ $build_rc -eq 0 ]]; then
		echo "$pkg_sum" >> /pjob.data/pkg_tmp_built.txt
	else
		echo "$pkg_sum" >> /pjob.data/pkg_tmp_failed.txt
	fi
done < /pjob.data/pkg_todo.txt

# update the built and failed list
cat /pjob.data/pkg_tmp_built.txt >> $list_built
cat /pjob.data/pkg_tmp_failed.txt >> $list_failed

cd /pjob.data

#
# cleanup

rpm_cleanup
tmpdir_cleanup

/pjob.data/shutdown.sh
[[ $? -ne 0 ]] && exit 1

exit $rc
