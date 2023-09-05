#!/bin/bash

# Get repo root dir
current_dir="$(dirname "${BASH_SOURCE[0]}")"
repo_dir="$(dirname "$current_dir")"

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

### CKAN INI ###

ckan_ini_file="$repo_dir/config/ckan.ini"

if [ -f "$ckan_ini_file" ]; then
    pretty_echo "$repo_dir/config/ckan.ini present."
else
    pretty_echo "$repo_dir/config/ckan.ini not found."
    echo "Please generate a ckan.ini first."
    echo "A template can be generated with:"
    echo ""
    echo 'docker run --rm --entrypoint=sh \
    registry-gitlab.wsl.ch/envidat/ckan-container/ckan:2.10.1-main \
    -c "ckan generate config ckan.ini && cat ckan.ini"'
    echo ""
    exit 1
fi


### DOCKER ###

read -rp "Do you want to install Docker? (y/n): " install_docker

if [ "$install_docker" == "y" ]; then
    read -rp "Select your distribution (ubuntu/debian): " distribution

    if [ "$distribution" == "ubuntu" ]; then
        # Install Docker on Ubuntu
        pretty_echo "Installing Docker on Ubuntu..."
        bash "$repo_dir/scripts/setup/ubuntu-docker.sh"

    elif [ "$distribution" == "debian" ]; then
        # Install Docker on Debian
        pretty_echo "Installing Docker on Debian..."
        bash "$repo_dir/scripts/setup/debian-docker.sh"

    else
        echo "Invalid distribution choice. Exiting."
        exit 1
    fi

    pretty_echo "Docker installation completed."

else
    pretty_echo "Docker installation skipped."
fi


### DB Recovery ###

read -rp "Do you want to recover a remote database? (y/n): " db_recover

while true; do
    if [ "$db_recover" == "y" ]; then
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
            # Attempt to remove the file first
            if rm -f "$repo_dir/.db.env"; then
                {
                    echo "DB_HOST=$DB_HOST"
                    echo "DB_USER=$DB_USER"
                    echo "DB_PASS=$DB_PASS"
                    echo "DB_CKAN_NAME=$DB_CKAN_NAME"
                    echo "DB_DOI_NAME=$DB_DOI_NAME"
                } > "$repo_dir/.db.env"

                echo "Credentials saved to $repo_dir/.db.env"
                break  # Exit the loop if credentials are confirmed
            else
                echo "Failed to remove $repo_dir/.db.env and regenerate."
                echo "Please delete it first."
                exit 1
            fi
        fi
    else
        pretty_echo "Using a fresh database."
        break  # Exit the loop if not recovering a remote database
    fi
done

### Start Containers ###

pretty_echo "Starting CKAN."

if [ "$db_recover" == "y" ]; then
    docker compose -f docker-compose.prod.yml up -d
else
    docker compose -f docker-compose.prod.yml -f docker-compose.newdb.yml up -d
fi
