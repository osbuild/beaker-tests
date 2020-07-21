#!/bin/bash
set -euxo pipefail

# Set variables.
source /etc/os-release

# Ensure we have jq to parse journalctl output.
dnf -y install jq

# Get osbuild-composer again.
rm -f osbuild-composer
git clone --single-branch \
    --branch multi-arch-beaker \
    https://github.com/major/osbuild-composer
cd osbuild-composer

# Set up WORKSPACE location.
WORKSPACE=$(pwd)
export WORKSPACE

# Get the current journal cursor.
JOURNALD_CURSOR=$(journalctl -n 1 -o json | jq -r ".__CURSOR")

# Dump logs from a failed test.
logdump () {
    journalctl --cursor="${JOURNALD_CURSOR}"
    sleep 5
    exit 1
}

# Catch errors and dump logs.
trap logdump ERR

# Run tests.
schutzbot/run_image_tests.sh

echo "🤠 If we made it this far, everything passed!"
