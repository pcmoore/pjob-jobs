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
        cat $o_netlabel >> $report
        echo "### END" >> $report
        echo "" >> $report

        # email the report
        cat $report | mutt -e "set copy=no" \
		-s "Automated Kernel Repo Check Results (NETLABEL) [$(date +"%m/%d/%Y %H:%M")]" \
                -- guest@example.org
}

####
# main

cd /pjob.data/scratch

k_dir="linux-kernel"
o_netlabel="/pjob.data/scratch/output_netlabel.txt"
prev_netlabel="/pjob.data/scratch/output_netlabel.txt.prev"

touch $prev_netlabel
> $o_netlabel

# netlabel checks
paths_netlabel=""
paths_netlabel+=" net/netlabel include/net/netlabel.h"
paths_netlabel+=" net/ipv4/cipso_ipv4.c include/net/cipso_ipv4.h"
paths_netlabel+=" net/ipv6/calipso.c include/net/calipso.h"
paths_netlabel+=" net/netfilter/xt_SECMARK.c"
pahts_netlabel+=" include/uapi/linux/netfilter/xt_SECMARK.h"
paths_netlabel+=" net/netfilter/xt_CONNSECMARK.c"
pahts_netlabel+=" include/uapi/linux/netfilter/xt_CONNSECMARK.h" 
stable_netlabel=$(stable_latest $k_dir netlabel)
echo "> checking netlabel on linus/master (lsm/main..linus/master)" | tee -a $o_netlabel
(cd $k_dir; git log --oneline --no-merges lsm/main..linus/master $paths_netlabel;) | tee -a $o_netlabel
echo "> checking netlabel on next/master (lsm/main..next/master)" | tee -a $o_netlabel
(cd $k_dir; git log --oneline --no-merges lsm/main..next/master $paths_netlabel;) | tee -a $o_netlabel

# send a report if needed and update the logs
cmp -s $prev_netlabel $o_netlabel
[[ $? -ne 0 ]] && report
mv -f $o_netlabel $prev_netlabel

cd /pjob.data
exit 0
