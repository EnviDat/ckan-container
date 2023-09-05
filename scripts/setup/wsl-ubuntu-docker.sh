#!/bin/bash

# Note: this script is WSL specific.
# Use another script if you are not running WSL.
# Tested for Ubuntu 22.04 LTS

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

pretty_echo "WSL: setting resolv.conf"
echo 'nameserver 1.1.1.1' | sudo tee /etc/resolv.conf > /dev/null
echo "Done"

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
    uidmap dbus-user-session slirp4netns

pretty_echo "Adding docker gpg key"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "Done"

pretty_echo "Adding docker to apt source"
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
echo "Done"

pretty_echo "Installing Docker"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

pretty_echo "Disabling docker service if running"
sudo systemctl disable --now docker.service docker.socket

pretty_echo "Changing to rootless docker"
dockerd-rootless-setuptool.sh install --skip-iptables

pretty_echo "Updating docker ps formatting"
tee ~/.docker/config.json <<EOF
{
  "psFormat": "table {{.ID}}\\t{{.Image}}\\t{{.Status}}\\t{{.Names}}"
}
EOF

pretty_echo "Adding rootless DOCKER_HOST to bashrc"
echo "export DOCKER_HOST=unix:///run/user/1000//docker.sock" >> ~/.bashrc
# shellcheck disable=SC1090
source ~/.bashrc
echo "Done"

pretty_echo "Adding dc='docker compose' alias to bashrc"
echo "alias dc='docker compose'" >> ~/.bashrc
echo "Done"
