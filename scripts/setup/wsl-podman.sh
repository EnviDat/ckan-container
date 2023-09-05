#!/bin/bash

# Note: this script is WSL specific.
# Use another script if you are not running WSL.
# Tested for Ubuntu 22.04 LTS & Debian 11 Bookworm

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

pretty_echo "WSL: setting resolv.conf and disable generateResolvConf"
echo 'nameserver 1.1.1.1' | sudo tee /etc/resolv.conf > /dev/null
echo '[network]' | sudo tee /etc/wsl.conf > /dev/null
echo 'generateResolvConf = false' | sudo tee /etc/wsl.conf > /dev/null
echo "Done"

pretty_echo "Installing Podman"
sudo apt-get update
sudo apt-get install -y podman

pretty_echo "Add workaround systemctl & journalctl"
sudo tee /etc/containers/containers.conf <<EOF
[engine]
cgroup_manager = "cgroupfs"
events_logger = "file"
EOF
echo "Done"

pretty_echo "Allowing privileged port usage"
sudo tee -a /etc/sysctl.conf <<EOF
net.ipv4.ip_unprivileged_port_start=0
EOF
sudo sysctl -p
echo "Done"

pretty_echo "Adding docker='podman' alias"
echo "alias docker='podman'" >> ~/.bashrc
echo "Done"
