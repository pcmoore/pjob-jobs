#!/bin/bash

dnf clean all
dnf upgrade -y --skip-broken --allowerasing --obsoletes
rc=$?

exit $rc
