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
        echo "### SELINUX" >> $report
        cat $o_selinux >> $report
        echo "### END" >> $report
        echo "" >> $report

        # email the report
        cat $report | mutt -e "set copy=no" \
		-s "Automated Kernel Repo Check Results (SELINUX) [$(date +"%m/%d/%Y %H:%M")]" \
                -- guest@example.org
}

####
# main

cd /pjob.data/scratch

k_dir="linux-kernel"
o_selinux="/pjob.data/scratch/output_selinux.txt"
prev_selinux="/pjob.data/scratch/output_selinux.txt.prev"

touch $prev_selinux
> $o_selinux

# selinux checks
paths_selinux="security/selinux scripts/selinux"
stable_selinux=$(stable_latest $k_dir selinux)
echo "> checking selinux on linus/master (selinux/${stable_selinux}..linus/master)" | tee -a $o_selinux
(cd $k_dir; git log --oneline --no-merges selinux/${stable_selinux}..linus/master $paths_selinux;) | tee -a $o_selinux
echo "> checking selinux on next/master (selinux/next..next/master)" | tee -a $o_selinux
(cd $k_dir; git log --oneline --no-merges selinux/next..next/master $paths_selinux;) | tee -a $o_selinux

# send a report if needed and update the logs
cmp -s $prev_selinux $o_selinux
[[ $? -ne 0 ]] && report
mv -f $o_selinux $prev_selinux

cd /pjob.data
exit 0
