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

update_wsl_conf() {
    wsl_conf="/etc/wsl.conf"

    # Check if the [network] section exists in wsl.conf
    if sudo grep -q "\[network\]" "$wsl_conf"; then
        # Check if generateResolvConf is already set
        if sudo grep -q "generateResolvConf" "$wsl_conf"; then
            # Replace the existing generateResolvConf line with the new setting
            sudo sed -i 's/^generateResolvConf\s*=.*/generateResolvConf=false/' "$wsl_conf"
        else
            # Add generateResolvConf setting under [network]
            echo "generateResolvConf=false" | sudo tee -a "$wsl_conf" > /dev/null
        fi
    else
        # [network] section does not exist, so create it
        echo "[network]" | sudo tee -a "$wsl_conf" > /dev/null
        echo "generateResolvConf=false" | sudo tee -a "$wsl_conf" > /dev/null
    fi
}

pretty_echo "WSL: setting resolv.conf and disable generateResolvConf"
# /etc/resolv.conf is a symbolic link, delete it to create a regular file
sudo rm /etc/resolv.conf
echo 'nameserver 1.1.1.1' | sudo tee /etc/resolv.conf > /dev/null
sudo chattr +i /etc/resolv.conf
update_wsl_conf
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
user_id=$(id -u)
export DOCKER_HOST="unix:///run/user/$user_id//docker.sock"
echo "export DOCKER_HOST=unix:///run/user/$user_id//docker.sock" >> ~/.bashrc
echo "Done"

pretty_echo "Adding dc='docker compose' alias to bashrc"
echo "alias dc='docker compose'" >> ~/.bashrc
echo "Done"
