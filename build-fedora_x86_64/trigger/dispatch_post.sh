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

# uncomment to skip powering-off the system here, relying on the keepalive
#exit 0

# attempt to power-on the system and wait until it is on the network
echo "POWERING OFF $PJOB_VAR_DISPATCH_TGT_HOST"
ipmi_power_set $PJOB_VAR_DISPATCH_TGT_HOST off

echo "CHECKING SYSTEM"
ipmi_power_get $PJOB_VAR_DISPATCH_TGT_HOST
ipmi_power_get $PJOB_VAR_DISPATCH_TGT_HOST status | grep -q "off"
rc=$?
echo "SYSTEM RESULT (rc=$?)"

exit $rc
