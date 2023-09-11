#!/bin/bash

echo "*******************************************"
echo " _____                _ ______         _   "
echo "|  ___|              (_)|  _  \       | |  "
echo "| |__   _ __  __   __ _ | | | |  __ _ | |_ "
echo "|  __| | '_ \ \ \ / /| || | | | / _  || __|"
echo "| |___ | | | | \ V / | || |/ / | (_| || |_ "
echo "\____/ |_| |_|  \_/  |_||___/   \__,_| \__|"
echo "*******************************************"
echo ""
echo ""

### Formatted echo ###
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

### Docker Install Options ###
docker_remove_old_install() {
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
}

install_docker_rootless() {
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

    pretty_echo "Adding dc='docker compose' alias"
    echo "alias dc='docker compose'" >> ~/.bashrc
    echo "Done"
}

docker_debian_install() {
    docker_remove_old_install

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

    install_docker_rootless
}

docker_ubuntu_install() {
    docker_remove_old_install

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

    install_docker_rootless
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

docker_wsl_ubuntu_install() {
    pretty_echo "WSL: setting resolv.conf and disable generateResolvConf"
    # /etc/resolv.conf is a symbolic link, delete it to create a regular file
    sudo rm /etc/resolv.conf
    echo 'nameserver 1.1.1.1' | sudo tee /etc/resolv.conf > /dev/null
    sudo chattr +i /etc/resolv.conf
    update_wsl_conf
    echo "Done"

    docker_ubuntu_install
}

### Write Dev .db.env ###
write_db_env() {
    {
        echo "DB_HOST=$DB_HOST"
        echo "DB_USER=$DB_USER"
        echo "DB_PASS=$DB_PASS"
        echo "DB_CKAN_NAME=$DB_CKAN_NAME"
        echo "DB_DOI_NAME=$DB_DOI_NAME"
    } > "$current_dir/.db.env"

    echo "Credentials saved to $current_dir/.db.env"
}

### Write Prod .solr.env ###
write_solr_env() {
    {
        echo "SOLR_ADMIN_PASS=$SOLR_ADMIN_PASS"
        echo "SOLR_CKAN_PASS=$SOLR_CKAN_PASS"
    } > "$current_dir/.solr.env"

    echo "Credentials saved to $current_dir/.solr.env"
}

### DOCKER ###
install_docker() {
    read -rp "Do you want to install Docker? (y/n): " install_docker

    if [ "$install_docker" == "y" ]; then
        read -rp "Select your distribution (ubuntu/debian): " distribution

        if [ "$distribution" == "ubuntu" ]; then
            read -rp "Are you on WSL (y/n): " is_wsl
            if [ "$is_wsl" == "y" ]; then
                # Install Docker on Ubuntu
                pretty_echo "Installing Docker on WSL Ubuntu"
                docker_wsl_ubuntu_install
            else
                # Install Docker on Ubuntu
                pretty_echo "Installing Docker on Ubuntu"
                docker_ubuntu_install
            fi

        elif [ "$distribution" == "debian" ]; then
            # Install Docker on Debian
            pretty_echo "Installing Docker on Debian"
            docker_debian_install

        else
            echo "Invalid distribution choice. Exiting."
            exit 1
        fi

        pretty_echo "Docker installation completed"

    else
        pretty_echo "Docker installation skipped"
    fi
}

### DB Recovery ###
set_db_recovery_creds() {
    pretty_echo "DB Recovery"

    read -rp "Do you want to recover a remote database? (y/n): " db_recover

    while true; do
        if [ "$db_recover" == "y" ]; then
            if [ -f "$current_dir/.db.env" ]; then
                read -rp "Do you wish to overwrite existing $current_dir/.db.env? (y/n): " overwrite_db_env
            fi
            if [ "$overwrite_db_env" == "n" ]; then
                echo "Continuing..."
                break  # Exit the loop if .db.env exists
            fi

            read -rp "Enter your database host: " db_host
            read -rp "Enter your database user: " db_user
            read -rp "Enter your database password: " db_pass
            read -rp "Enter your CKAN database name: " db_ckan_name
            read -rp "Enter your DOI database name: " db_doi_name

            DB_HOST=$db_host
            DB_CKAN_NAME=$db_ckan_name
            DB_USER=$db_user
            DB_PASS=$db_pass
            DB_DOI_NAME=$db_doi_name

            pretty_echo "Your provided credentials are:"
            echo "DB_HOST=$DB_HOST"
            echo "DB_USER=$DB_USER"
            echo "DB_PASS=$DB_PASS"
            echo "DB_CKAN_NAME=$DB_CKAN_NAME"
            echo "DB_DOI_NAME=$DB_DOI_NAME"
            echo ""

            read -rp "Are these correct? (y/n): " creds_confirmed

            if [ "$creds_confirmed" == "y" ]; then

                if [ "$overwrite_db_env" == "y" ]; then
                    # Attempt to remove the file first
                    if rm -f "$current_dir/.db.env"; then
                        write_db_env
                        break  # Exit the loop as .db.env written
                    else
                        echo "Failed to remove $current_dir/.db.env and regenerate."
                        echo "Please delete it first."
                        exit 1
                    fi
                else
                    write_db_env
                    break  # Exit the loop as .db.env written
                fi
            fi
        else
            pretty_echo "Using a fresh database"
            break  # Exit the loop if not recovering a remote database
        fi
    done
}

### Solr Creds ###
set_solr_creds() {
    pretty_echo "Solr Credentials"

    while true; do
        if [ -f "$current_dir/.solr.env" ]; then
            read -rp "Do you wish to overwrite existing $current_dir/.solr.env? (y/n): " overwrite_solr_env
        fi
        if [ "$overwrite_solr_env" == "n" ]; then
            echo "Continuing..."
            break  # Exit the loop if .solr.env exists
        fi

        read -rp "Enter a password for the admin: " admin_pass
        read -rp "Enter a password for ckan user: " ckan_pass

        SOLR_ADMIN_PASS=$admin_pass
        SOLR_CKAN_PASS=$ckan_pass

        pretty_echo "Your provided credentials are:"
        echo "SOLR_ADMIN_PASS=$SOLR_ADMIN_PASS"
        echo "SOLR_CKAN_PASS=$SOLR_CKAN_PASS"
        echo ""

        read -rp "Are these correct? (y/n): " creds_confirmed

        if [ "$creds_confirmed" == "y" ]; then

            if [ "$overwrite_solr_env" == "y" ]; then
                # Attempt to remove the file first
                if rm -f "$current_dir/.solr.env"; then
                    write_solr_env
                    break  # Exit the loop as .solr.env written
                else
                    echo "Failed to remove $current_dir/.solr.env and regenerate."
                    echo "Please delete it first."
                    exit 1
                fi
            else
                write_solr_env
                break  # Exit the loop as .solr.env written
            fi
        fi
    done
}

### WSL Warning ###
wsl_restart_warning() {
    pretty_echo "Running in WSL"
    echo "If docker was installed on a fresh machine then"
    echo "pulling the container images may fail."
    echo ""
    echo "To solve this, WSL may have to be restarted via powershell:"
    echo ""
    echo "wsl --shutdown"
    echo ""
    read -rp "Do you wish to continue? (y/n): " continue
    if [ "$continue" != "y" ]; then
        exit 1
    fi
}

### CKAN INI Check ###
check_ckan_ini() {
    ckan_ini_file="$current_dir/config/ckan.ini"

    if [ -f "$ckan_ini_file" ]; then
        pretty_echo "$current_dir/config/ckan.ini present"
    else
        pretty_echo "$current_dir/config/ckan.ini not found"
        echo "Please generate a ckan.ini first."
        echo "A template can be generated with:"
        echo ""
        echo 'docker run --rm --entrypoint=sh \
        registry-gitlab.wsl.ch/envidat/ckan-container/ckan:2.10.1-main \
        -c "ckan generate config ckan.ini && cat ckan.ini"'
        echo ""
        exit 1
    fi
}

### Start CKAN ###
start_ckan() {
    pretty_echo "Starting CKAN"

    if [ "$prod" == "y" ]; then
        docker compose -f docker-compose.prod.yml up -d
    else
        if [ "$db_recover" == "y" ]; then
            docker compose up -d
        else
            DB_ENV_FILE=/dev/null docker compose up -d
        fi
    fi
}

### Create Frontend .env.development ###
update_frontend_dotenv() {
    # Define the new values for the variables
    export VITE_DOMAIN=http://localhost:8990
    export VITE_API_ROOT=http://localhost:8989

    # Loop through the variables and update their values in the file
    for var in VITE_DOMAIN VITE_API_ROOT; do
        sed -i "s|^$var=.*$|$var=${!var}|" "$current_dir/EnviDat-Frontend/.env.development"
    done

    echo "Updated .env.development with new values."
}

### Start Frontend ###
start_frontend() {
    pretty_echo "Starting EnviDat Prod Frontend"

    default_frontend_version="0.8.0"
    echo "Override frontend version? (default 0.8.0)"
    read -rp "Press Enter to continue, or input a version: " frontend_version
    if [ -z "$frontend_version" ]; then
        frontend_version="$default_frontend_version"
    fi

    docker run -d \
        --name envidat_frontend \
        -p 8990:80 \
        "registry-gitlab.wsl.ch/envidat/envidat-frontend:$frontend_version-main"
}
start_frontend_dev() {
    pretty_echo "Starting EnviDat Dev Frontend"

    git clone --depth 1 --single-branch -b develop \
        https://gitlabext.wsl.ch/EnviDat/EnviDat-Frontend.git

    update_frontend_dotenv

    cd "EnviDat-Frontend" || echo "Did the EnviDat-Frontend repo clone successfully?"
    docker compose pull
    docker compose up -d
    cd .. || exit
}


### Main Start ###

# Get current dir
current_dir="${PWD}"

# Global vars
prod=""
is_wsl=""
db_recover=""

### Prerequisites ###
# Get CURL if doesn't exist
if ! command -v curl &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y curl
fi
# Get GIT if doesn't exist
if ! command -v git &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y git --no-install-recommends
fi
# Download docker-compose files
if [ "$(basename "$current_dir")" != "ckan-container" ]; then
    pretty_echo "Downloading required files"
    curl -LO https://gitlabext.wsl.ch/EnviDat/ckan-container/-/raw/main/.env
    curl -LO https://gitlabext.wsl.ch/EnviDat/ckan-container/-/raw/main/docker-compose.yml
    curl -LO https://gitlabext.wsl.ch/EnviDat/ckan-container/-/raw/main/docker-compose.prod.yml
fi
# Docker
install_docker
if [ "$is_wsl" == "y" ]; then
    wsl_restart_warning
fi
check_ckan_ini

### Prod / Dev Run ###
read -rp "Are you running production? (y/n): " prod
if [ "$prod" == "y" ]; then
    set_solr_creds
else
    set_db_recovery_creds
fi

# Start Containers
start_ckan
if [ "$prod" == "y" ]; then
    start_frontend
    pretty_echo "Script Finished"
    echo "Update proxy rules for https://envidat.ch"
    echo "and redirect envidat.ch endpoints to CKAN:"
    echo ""
    echo "<this_machine_domain>:8989"
    echo ""
    echo "Ensure the frontend image is built with var:"
    echo ""
    echo "VITE_API_ROOT=https://envidat.ch"
else
    start_frontend_dev
    pretty_echo "Script Finished"
    echo "Access services:"
    echo ""
    echo "EnviDat Frontend: http://localhost:8990"
    echo "CKAN Backend: http://localhost:8989"
    echo ""
fi
