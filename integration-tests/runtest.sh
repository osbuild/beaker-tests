#!/bin/bash
set -euxo pipefail

# Set variables.
source /etc/os-release
TEST_IMAGE_TYPE=${TEST_IMAGE_TYPE:-qcow2}

# Get osbuild-composer again.
rm -f osbuild-composer
git clone --single-branch \
    --branch multi-arch-beaker \
    https://github.com/major/osbuild-composer
cd osbuild-composer

# Set up WORKSPACE location.
WORKSPACE=$(pwd)
export WORKSPACE

# Dump logs/metadata from a failed test.
logdump () {
    for LOGFILE in *.{json,log}; do
        echo "---------------------------------------------------------------"
        echo ">>>>> ${LOGFILE} <<<<<"
        if [[ $LOGFILE == *json ]]; then
            jq -M "." $LOGFILE
        else
            cat $LOGFILE
        fi
    done
}

# Install required packages.
dnf -y install jq

# Run test.
if ! test/image-tests/qemu.sh $TEST_IMAGE_TYPE | ts -s; then
    logdump
    sleep 5
    exit 1
fi

echo "🤠 If we made it this far, everything passed!"
