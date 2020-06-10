#!/bin/bash
set -euxo pipefail

# Set variables.
source /etc/os-release
WORKSPACE=$(pwd)
export WORKSPACE

# Get osbuild-composer again.
git clone --recursive --depth 5 https://github.com/osbuild/osbuild-composer
cd osbuild-composer

# Install required packages.
dnf -y install jq

# Run qcow2 test.
test/image-tests/qemu.sh qcow2

# Run openstack test.
test/image-tests/qemu.sh openstack

# Run vhd test.
test/image-tests/qemu.sh vhd

# Run vmdk test.
test/image-tests/qemu.sh vmdk