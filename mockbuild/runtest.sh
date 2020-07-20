#!/bin/bash
set -euxo pipefail

# Set variables.
source /etc/os-release
ARCH=$(uname -m)
MOCK_CONFIG="${ID}-${VERSION_ID%.*}-$(uname -m)"
REPO_DIR=/opt/osbuild/repo

# Handle RHEL-specific tasks.
if [[ $ID == rhel ]]; then
    # Add EPEL to get mock.
    if ! rpm -qi epel-release > /dev/null 2>&1; then
        curl --retry 5 -LsO \
            https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
        rpm -Uvh epel-release-latest-8.noarch.rpm
    fi

    # Register via staging RHN, attach the beta pool, and add the CRB repo.
    if ! subscription-manager status > /dev/null 2>&1; then
        curl --retry 5 -sk https://gitlab.cee.redhat.com/snippets/2308/raw | bash
    fi

    # List enabled repositories.
    subscription-manager repos --list-enabled
fi

# Update the OS and install packages.
dnf -y upgrade
dnf -y install createrepo_c dnf-plugins-core git htop make mock \
    python3 python3-pip rpm-build xz

# Update the mock configs if we are on 8.3 beta.
if [[ $VERSION_ID == 8.3 ]]; then
    sed -i '/# repos/q' /etc/mock/templates/rhel-8.tpl
    cat /etc/yum.repos.d/redhat.repo | tee -a /etc/mock/templates/rhel-8.tpl
    echo '"""' | tee -a /etc/mock/templates/rhel-8.tpl
fi

# Clone osbuild-composer.
rm -rf osbuild-composer
git clone --recursive --depth 5 https://github.com/osbuild/osbuild-composer

# Build source RPMs.
make -C osbuild-composer srpm
make -C osbuild-composer/osbuild srpm

# Compile RPMs in a mock chroot
mkdir -p $REPO_DIR
mock -v -r $MOCK_CONFIG --no-bootstrap-chroot \
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