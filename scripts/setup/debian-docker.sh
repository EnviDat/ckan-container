#!/bin/bash

# Tested for Debian 11 Bookworm

pretty_echo() {
    local message="$1"
    local length=${#message}
    local separator=""

    for ((i=0; i<length+4; i++)); do
        separator="$separator-"
    done

    echo ""
    echo "$separator"
    echo "$message"
    echo "$separator"
    echo ""
}

pretty_echo "Removing old versions of docker"
packages=(
    docker.io
    docker-doc
    docker-compose
    podman-docker
    containerd
    runc
)
for pkg in "${packages[@]}"; do
    sudo apt-get remove "$pkg"
done

pretty_echo "Installing dependencies"
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg \
    uidmap dbus-user-session fuse-overlayfs slirp4netns

pretty_echo "Adding docker gpg key"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "Done"

pretty_echo "Adding docker to apt source"
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
echo "Done"

pretty_echo "Installing Docker"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

pretty_echo "Disabling docker service if running"
sudo systemctl disable --now docker.service docker.socket

pretty_echo "Install rootless docker"
dockerd-rootless-setuptool.sh install

pretty_echo "Updating docker ps formatting"
tee ~/.docker/config.json <<EOF
{
  "psFormat": "table {{.ID}}\\t{{.Image}}\\t{{.Status}}\\t{{.Names}}"
}
EOF

pretty_echo "Adding rootless DOCKER_HOST to bashrc"
user_id=$(id -u)
export DOCKER_HOST="unix:///run/user/$user_id//docker.sock"
echo "export DOCKER_HOST=unix:///run/user/$user_id//docker.sock" >> ~/.bashrc
echo "Done"

pretty_echo "Adding dc='docker compose' alias"
echo "alias dc='docker compose'" >> ~/.bashrc
echo "Done"
