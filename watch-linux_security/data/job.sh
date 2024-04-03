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

k_dir="linux-kernel"
o_selinux="/pjob.data/scratch/output_selinux.txt"
prev_selinux="/pjob.data/scratch/output_selinux.txt.prev"
o_audit="/pjob.data/scratch/output_audit.txt"
prev_audit="/pjob.data/scratch/output_audit.txt.prev"

# update the local git repo
(cd $k_dir; git remote update || exit_cleanup)
(cd $k_dir; git checkout --force master || exit_cleanup)
(cd $k_dir; git reset --hard linus/master || exit_cleanup)
(cd $k_dir; git gc)

# run checks
for i in chk_*.sh; do
        if [[ -x ./$i ]]; then
               echo ">>> RUNNING $i"
               ./$i
        fi
done

cd /pjob.data

#
# cleanup

/pjob.data/shutdown.sh
[[ $? -ne 0 ]] && exit 1

exit 0
