#!/bin/bash

CONTAINER="devbox"
CONTAINER_HOME_DIR="$HOME/Distrobox/devbox_home"

GIT_NAME="Jonathan"
GIT_EMAIL="jonathan.Y4W@protonmail.com"

if distrobox list | grep -q "$CONTAINER"; then
    echo "Error: "$CONTAINER" already exists!"
    exit 1
fi

mkdir -p "$CONTAINER_HOME_DIR"
distrobox create --name "$CONTAINER" --image fedora:latest --home "$CONTAINER_HOME_DIR"

distrobox enter "$CONTAINER" -- bash <<'EOF'

sudo dnf update -y

sudo dnf install -y \
    git \
    gcc \
    gcc-c++ \
    usbutils \
    SDL2-devel \
    clangd \
    gmp gmp-devel make ncurses ncurses-compat-libs xz perl pkg-config

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

# Ensure git details set correctly
git config --global user.name "$GIT_NAME"
git config --global user.email $GIT_EMAIL"

EOF

echo "makeDevContainer: Done!"
