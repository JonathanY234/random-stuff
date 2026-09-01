#!/bin/bash

CONTAINER="devbox"

if distrobox list | grep -q "$CONTAINER"; then
    echo "Error: "$CONTAINER" already exists!"
    exit 1
fi


distrobox create --name "$CONTAINER" --image fedora:latest --home /home/Jonny/Distrobox/devbox_home

distrobox enter "$CONTAINER" -- bash <<'EOF'
echo "I am in the container"

sudo dnf update -y

sudo dnf install -y \
    git \
    gcc \
    gcc-c++ \
    usbutils \
    SDL2-devel

# vs-codium
sudo tee -a /etc/yum.repos.d/vscodium.repo << 'REPO'
[gitlab.com_paulcarroty_vscodium_repo]
name=gitlab.com_paulcarroty_vscodium_repo
baseurl=https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/rpms/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg
metadata_expire=1h
REPO
sudo dnf install -y codium
distrobox-export --app codium


EOF


echo "Done!"
