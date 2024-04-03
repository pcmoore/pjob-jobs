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
        echo "### KERNEL SECURITY" >> $report
        cat $d_kernel_security >> $report
        echo "### END" >> $report
        echo "" >> $report

        # email the report
        cat $report | mutt -e "set copy=no" \
		-s "Automated Kernel Repo Check Results (KERNEL SECURITY) [$(date +"%m/%d/%Y %H:%M")]" \
		-a $o_kernel_security \
                -- guest@example.org
}

####
# main

cd /pjob.data/scratch

k_dir="linux-kernel"
o_kernel_security="/pjob.data/scratch/output_kernel_security.txt"
d_kernel_security="/pjob.data/scratch/output_kernel_security.diff"
tmp_kernel_security="/pjob.data/scratch/tmp_kernel_security.txt"
prev_kernel_security="/pjob.data/scratch/output_kernel_security.txt.prev"


touch $prev_kernel_security
> $o_kernel_security
> $d_kernel_security

# lsm hooks checks
opts="--no-color -c --no-column --no-numbers"
k_subdirs="block crypto fs init ipc kernel lib mm net sound virt io_uring"

echo ">>> checking LSM security hooks on linus/master ..." | tee -a $o_kernel_security
cgrep -c -h --no-numbers "LSM_HOOK" $k_dir/include/linux/lsm_hook_defs.h | awk -F',* ' '{ print "security_"$3 }' > $tmp_kernel_security
(cd $k_dir; cgrep $opts -w -f $tmp_kernel_security $(find $k_subdirs -type f)) | tee -a $o_kernel_security

echo ">>> checking override_creds() on linus/master ..." | tee -a $o_kernel_security
(cd $k_dir; cgrep $opts -w "override_creds" $(find $k_subdirs -type f)) | tee -a $o_kernel_security

echo ">>> checking capable() on linus/master ..." | tee -a $o_kernel_security
(cd $k_dir; cgrep $opts -w "capable" $(find $k_subdirs -type f)) | tee -a $o_kernel_security

echo ">>> checking cap_raised() on linus/master ..." | tee -a $o_kernel_security
(cd $k_dir; cgrep $opts -w "cap_raised" $(find $k_subdirs -type f)) | tee -a $o_kernel_security

echo ">>> checking ns_capable() on linus/master ..." | tee -a $o_kernel_security
(cd $k_dir; cgrep $opts -w "ns_capable" $(find $k_subdirs -type f)) | tee -a $o_kernel_security

echo ">>> checking ns_capable_noaudit() on linus/master ..." | tee -a $o_kernel_security
(cd $k_dir; cgrep $opts -w "ns_capable_noaudit" $(find $k_subdirs -type f)) | tee -a $o_kernel_security

echo ">>> checking ns_capable_setid() on linus/master ..." | tee -a $o_kernel_security
(cd $k_dir; cgrep $opts -w "ns_capable_setid" $(find $k_subdirs -type f)) | tee -a $o_kernel_security

echo ">>> checking sockopt_capable() on linus/master ..." | tee -a $o_kernel_security
(cd $k_dir; cgrep $opts -w "sockopt_capable" $(find $k_subdirs -type f)) | tee -a $o_kernel_security

echo ">>> checking sockopt_ns_capable() on linus/master ..." | tee -a $o_kernel_security
(cd $k_dir; cgrep $opts -w "sockopt_ns_capable" $(find $k_subdirs -type f)) | tee -a $o_kernel_security

echo ">>> checking sk_capable() on linus/master ..." | tee -a $o_kernel_security
(cd $k_dir; cgrep $opts -w "sk_capable" $(find $k_subdirs -type f)) | tee -a $o_kernel_security

echo ">>> checking sk_ns_capable() on linus/master ..." | tee -a $o_kernel_security
(cd $k_dir; cgrep $opts -w "sk_ns_capable" $(find $k_subdirs -type f)) | tee -a $o_kernel_security

echo ">>> checking capability defines on linus/master ..." | tee -a $o_kernel_security
(cd $k_dir; cgrep $opts -G "#define[ \t]+CAP_" include/uapi/linux/capability.h) | tee -a $o_kernel_security

echo ">>> checking io-uring ops on linus/master ..." | tee -a $o_kernel_security
(cd $k_dir; cgrep $opts -p "IORING_OP_" $(find include/uapi -type f)) | tee -a $o_kernel_security

# send a report if needed and update the logs
diff --unified=0 $prev_kernel_security $o_kernel_security | sed '/^---/d;/^+++/d;/^@@.*@@$/d' > $d_kernel_security
[[ $(wc -l $d_kernel_security | awk '{ print $1 }') -ne 0 ]] && report
mv -f $o_kernel_security $prev_kernel_security

cd /pjob.data
exit 0
