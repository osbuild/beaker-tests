#!/bin/bash
set -euxo pipefail

# Set variables.
source /etc/os-release

# Ensure the repository is working properly.
sudo dnf repository-packages osbuild-mock list

# Install the Image Builder packages.
dnf -y install cockpit cockpit-composer composer-cli osbuild osbuild-ostree \
    osbuild-composer osbuild-composer-rcm osbuild-composer-tests \
    osbuild-composer-worker python3-osbuild

# Start services.
systemctl enable --now osbuild-rcm.socket
systemctl enable --now osbuild-composer.socket
systemctl enable --now cockpit.socket

# Verify that the API is running.
composer-cli status show
composer-cli sources list