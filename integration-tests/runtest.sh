#!/bin/bash
set -euxo pipefail

# Set variables.
source /etc/os-release

# Get osbuild-composer again.
git clone --recursive --depth 5 https://github.com/osbuild/osbuild-composer
cd osbuild-composer

# Set up WORKSPACE location.
WORKSPACE=$(pwd)
export WORKSPACE

# Dump logs/metadata from a failed test.
logdump () {
    WORKSPACE_LOGS=$(find . -regextype egrep -regex ".*\.(json|log)$")
    for LOGFILE in WORKSPACE_LOGS; do
        echo "---------------------------------------------------------------"
        echo ">>>>> ${LOGFILE} <<<<<"
        cat $LOGFILE
    done
}

# Install required packages.
dnf -y install jq

# Run qcow2 test.
if ! test/image-tests/qemu.sh qcow2; then
    logdump
    exit 1
fi

# Run openstack test.
if ! test/image-tests/qemu.sh openstack; then
    logdump
    exit 1
fi

# Run vhd test.
if ! test/image-tests/qemu.sh vhd; then
    logdump
    exit 1
fi

# Run vmdk test.
if test/image-tests/qemu.sh vmdk; then
    logdump
    exit 1
fi

echo "🤠 If we made it this far, everything passed!"
