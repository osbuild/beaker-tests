#!/bin/bash
set -euxo pipefail

# Set variables.
source /etc/os-release
MOCK_CONFIG="${ID}-${VERSION_ID%.*}-$(uname -m)"
REPO_DIR=/opt/osbuild/repo

# Ensure EPEL is installed on RHEL.
if [[ $ID == rhel ]]; then
    curl --retry 5 -LsO https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    rpm -Uvh epel-release-latest-8.noarch.rpm
fi

# Update the OS and install packages.
dnf -y upgrade
dnf -y install ansible createrepo_c chrony dnf-plugins-core git \
    make mock podman policycoreutils-python-utils python3 python3-pip \
    rpm-build vi vim xz

# Clone osbuild-composer.
git clone --recursive https://github.com/osbuild/osbuild-composer

# Build source RPMs.
make -C osbuild-composer srpm
make -C osbuild-composer/osbuild srpm

# Compile RPMs in a mock chroot
mkdir -p $REPO_DIR
mock -r $MOCK_CONFIG --no-bootstrap-chroot \
    --resultdir $REPO_DIR --with=tests \
    osbuild-composer/rpmbuild/SRPMS/*.src.rpm \
    osbuild-composer/osbuild/rpmbuild/SRPMS/*.src.rpm

# Create a repo of the built RPMs.
createrepo_c ${REPO_DIR}

# Set up a dnf repository.
tee /etc/yum.repos.d/osbuild-mock.repo << EOF
[osbuild-mock]
name=osbuild mock
baseurl=file://${REPO_DIR}
enabled=1
gpgcheck=0
# Default dnf repo priority is 99. Lower number means higher priority.
priority=5
EOF

# Ensure the repository is working properly.
sudo dnf repository-packages osbuild-mock list