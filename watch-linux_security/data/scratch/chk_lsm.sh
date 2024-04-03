#!/bin/bash

# debug
#set -x

####
# function

function stable_latest() {
	[[ ! -d $1 || -z $2 ]] && return
	(cd $1; git show-ref) | \
		grep -e "refs/remotes/$2/stable-[0-9]*\.[0-9]*$" | \
		sort -k2 -V | tail -n1 | sed 's/.*\/\(.*\)/\1/'
}

function report() {
        local report=report.txt

        # generate the report
	> $report
	echo "SYSTEM: $(hostname --fqdn)" >> $report
        echo "DATE: $(date -R)" >> $report
        echo "" >> $report
        echo "### LSM" >> $report
        cat $o_lsm >> $report
        echo "### END" >> $report
        echo "" >> $report

        # email the report
        cat $report | mutt -e "set copy=no" \
		-s "Automated Kernel Repo Check Results (LSM) [$(date +"%m/%d/%Y %H:%M")]" \
                -- guest@example.org
}

####
# main

cd /pjob.data/scratch

k_dir="linux-kernel"
o_lsm="/pjob.data/scratch/output_lsm.txt"
prev_lsm="/pjob.data/scratch/output_lsm.txt.prev"

touch $prev_lsm
> $o_lsm

# lsm checks
paths_lsm="security/*.c include/linux/lsm_*.h"
stable_lsm=$(stable_latest $k_dir lsm)
echo "> checking lsm on linus/master (lsm/${stable_lsm}..linus/master)" | tee -a $o_lsm
(cd $k_dir; git log --oneline --no-merges lsm/${stable_lsm}..linus/master $paths_lsm;) | tee -a $o_lsm
echo "> checking lsm on next/master (lsm/next..next/master)" | tee -a $o_lsm
(cd $k_dir; git log --oneline --no-merges lsm/next..next/master $paths_lsm;) | tee -a $o_lsm

# send a report if needed and update the logs
cmp -s $prev_lsm $o_lsm
[[ $? -ne 0 ]] && report
mv -f $o_lsm $prev_lsm

cd /pjob.data
exit 0
