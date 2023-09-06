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

write_db_env() {
    {
        echo "DB_HOST=$DB_HOST"
        echo "DB_USER=$DB_USER"
        echo "DB_PASS=$DB_PASS"
        echo "DB_CKAN_NAME=$DB_CKAN_NAME"
        echo "DB_DOI_NAME=$DB_DOI_NAME"
    } > "$repo_dir/.db.env"

    echo "Credentials saved to $repo_dir/.db.env"
}

write_solr_env() {
    {
        echo "SOLR_ADMIN_PASS=$SOLR_ADMIN_PASS"
        echo "SOLR_CKAN_PASS=$SOLR_CKAN_PASS"
    } > "$repo_dir/.solr.env"

    echo "Credentials saved to $repo_dir/.solr.env"
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
                pretty_echo "Installing Docker on WSL Ubuntu..."
                source "$repo_dir/scripts/setup/wsl-ubuntu-docker.sh"
            else
                # Install Docker on Ubuntu
                pretty_echo "Installing Docker on Ubuntu..."
                source "$repo_dir/scripts/setup/ubuntu-docker.sh"
            fi

        elif [ "$distribution" == "debian" ]; then
            # Install Docker on Debian
            pretty_echo "Installing Docker on Debian..."
            source "$repo_dir/scripts/setup/debian-docker.sh"

        else
            echo "Invalid distribution choice. Exiting."
            exit 1
        fi

        pretty_echo "Docker installation completed."

    else
        pretty_echo "Docker installation skipped."
    fi
}

### DB Recovery ###
set_db_recovery_creds() {
    pretty_echo "DB Recovery"

    read -rp "Do you want to recover a remote database? (y/n): " db_recover

    while true; do
        if [ "$db_recover" == "y" ]; then
            if [ -f "$repo_dir/.db.env" ]; then
                read -rp "Do you wish to overwrite existing $repo_dir/.db.env? (y/n): " overwrite_db_env
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
                    if rm -f "$repo_dir/.db.env"; then
                        write_db_env
                        break  # Exit the loop as .db.env written
                    else
                        echo "Failed to remove $repo_dir/.db.env and regenerate."
                        echo "Please delete it first."
                        exit 1
                    fi
                else
                    write_db_env
                    break  # Exit the loop as .db.env written
                fi
            fi
        else
            pretty_echo "Using a fresh database."
            break  # Exit the loop if not recovering a remote database
        fi
    done
}

### Solr Creds ###
set_solr_creds() {
    pretty_echo "Solr Credentials"

    while true; do
        if [ -f "$repo_dir/.solr.env" ]; then
            read -rp "Do you wish to overwrite existing $repo_dir/.solr.env? (y/n): " overwrite_solr_env
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
                if rm -f "$repo_dir/.solr.env"; then
                    write_solr_env
                    break  # Exit the loop as .solr.env written
                else
                    echo "Failed to remove $repo_dir/.solr.env and regenerate."
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


### Main START ###

# Get repo root dir
current_dir="$(dirname "${BASH_SOURCE[0]}")"
repo_dir="$(dirname "$current_dir")"

# Global vars
db_recover=""

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

# Optional docker install
install_docker

### Prod / Dev ###

read -rp "Are you running production? (y/n): " prod

if [ "$prod" == "y" ]; then
    set_solr_creds
else
    set_db_recovery_creds
fi

### Start Containers ###

pretty_echo "Starting CKAN."

if [ "$prod" == "y" ]; then
    docker compose -f docker-compose.prod.yml up -d
else
    if [ "$db_recover" == "y" ]; then
        docker compose up -d
    else
        DB_ENV_FILE=/dev/null docker compose up -d
    fi
fi
