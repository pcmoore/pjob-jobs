#!/bin/bash

# load the variables we need 
[[ ! -r /pjob.vars/ipmiinfo ]] && exit 1
. /pjob.vars/ipmiinfo
[[ ! -r /pjob.vars/dispatchinfo ]] && exit 1
. /pjob.vars/dispatchinfo

# load our libraries
[[ ! -r /pjob.global/path.sh ]] && exit 1
. /pjob.global/path.sh
[[ ! -r /pjob.global/ipmi.sh ]] && exit 1
. /pjob.global/ipmi.sh

# attempt to power-on the system and wait until it is on the network
echo "POWERING ON $PJOB_VAR_DISPATCH_TGT_HOST"
ipmi_power_set $PJOB_VAR_DISPATCH_TGT_HOST on || exit 1
ipmi_power_get $PJOB_VAR_DISPATCH_TGT_HOST
count=0
while ! ping -c 5 $PJOB_VAR_DISPATCH_TGT_HOST; do
	[[ $count -ge 60 ]] && exit 1
	count=$(( $count + 1 ))
	sleep 10
done

echo "CHECKING SYSTEM"
ping -c 5 $PJOB_VAR_DISPATCH_TGT_HOST
rc=$?
echo "SYSTEM RESULT (rc=$rc)"

exit $rc
