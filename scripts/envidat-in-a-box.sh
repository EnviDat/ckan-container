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

### Write Dev .db.env ###
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

### Write Prod .solr.env ###
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
}

### Start CKAN ###
start_ckan() {
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
}

### Create Frontend .env.development ###
gen_frontend_dotenv() {
    cat <<EOF > "$repo_dir/.env.development"
VITE_USE_TESTDATA=false
VITE_ERROR_REPORTING_ENABLED=true
VITE_CONFIG_URL=./testdata/config.json
VITE_STATIC_ROOT=https://frontend-static.s3-zh.os.switch.ch
VITE_DOMAIN=http://localhost:8990
VITE_API_ROOT=http://localhost:8989
VITE_API_BASE_URL=/api/action/
EOF

    echo "Generated .env.development with vars:"
    echo "VITE_USE_TESTDATA=false"
    echo "VITE_ERROR_REPORTING_ENABLED=true"
    echo "VITE_CONFIG_URL=./testdata/config.json"
    echo "VITE_STATIC_ROOT=https://frontend-static.s3-zh.os.switch.ch"
    echo "VITE_DOMAIN=http://localhost:8990"
    echo "VITE_API_ROOT=http://localhost:8989"
    echo "VITE_API_BASE_URL=/api/action/"
}

### Start Frontend ###
start_frontend() {
    pretty_echo "Starting EnviDat Frontend."

    default_frontend_version="0.8.04"
    echo "Override frontend version? (default 0.8.04)"
    read -rp "Press Enter to continue, or input a version: " frontend_version
    if [ -z "$frontend_version" ]; then
        frontend_version="$default_frontend_version"
    fi

    gen_frontend_dotenv

    docker run -d \
        --name envidat_frontend \
        -p 8990:8080 \
        -v "$repo_dir/.env.development:/app/.env.development" \
        "registry-gitlab.wsl.ch/envidat/envidat-frontend:$frontend_version-dev"
}


### Main START ###

# Get repo root dir
current_dir="$(dirname "${BASH_SOURCE[0]}")"
repo_dir="$(dirname "$current_dir")"

# Global vars
prod=""
is_wsl=""
db_recover=""

# Prerequisites
install_docker
if [ "$is_wsl" == "y" ]; then
    wsl_restart_warning
fi
check_ckan_ini

# Prod / Dev Setup
read -rp "Are you running production? (y/n): " prod
if [ "$prod" == "y" ]; then
    set_solr_creds
else
    set_db_recovery_creds
fi

# Run Containers
start_ckan
if [ "$prod" == "y" ]; then
    pretty_echo "Script Finished."
    echo "Update proxy rules for https://envidat.ch"
    echo "and point your S3-based frontend to:"
    echo ""
    echo "VITE_API_ROOT=https://envidat.ch"
    echo ""
    echo "during build."
else
    start_frontend
fi
