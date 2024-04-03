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
        echo "### AUDIT" >> $report
        cat $o_audit >> $report
        echo "### END" >> $report
        echo "" >> $report

        # email the report
        cat $report | mutt -e "set copy=no" \
		-s "Automated Kernel Repo Check Results (AUDIT) [$(date +"%m/%d/%Y %H:%M")]" \
                -- guest@example.org
}

####
# main

cd /pjob.data/scratch

k_dir="linux-kernel"
o_audit="/pjob.data/scratch/output_audit.txt"
prev_audit="/pjob.data/scratch/output_audit.txt.prev"

touch $prev_audit
> $o_audit

# audit checks
paths_audit="kernel/audit* include/linux/audit.h include/uapi/linux/audit.h"
stable_audit=$(stable_latest $k_dir audit)
echo "> checking audit on linus/master (audit/${stable_audit}..linus/master)" | tee -a $o_audit
(cd $k_dir; git log --oneline --no-merges audit/${stable_audit}..linus/master $paths_audit;) | tee -a $o_audit
echo "> checking audit on next/master (audit/next..next/master)" | tee -a $o_audit
(cd $k_dir; git log --oneline --no-merges audit/next..next/master $paths_audit;) | tee -a $o_audit

# send a report if needed and update the logs
cmp -s $prev_audit $o_audit
[[ $? -ne 0 ]] && report
mv -f $o_audit $prev_audit

cd /pjob.data
exit 0
