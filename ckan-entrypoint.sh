#!/bin/bash
set -eo pipefail

CONFIG="${CKAN_CONFIG}/production.ini"
export CKAN_STORAGE_PATH=/var/lib/ckan

abort () {
    echo "$@" >&2
    exit 1
}

create_sqlalchemy_url () {
    local user=$CKAN_DB_USER
    local pass=$CKAN_DB_PASS
    local db=$CKAN_DB_NAME
    local host=$CKAN_DB_HOST
    local port=$CKAN_DB_PORT
    export CKAN_SQLALCHEMY_URL="postgresql://${user}:${pass}@${host}:${port}/${db}"
}

read_secrets () {
    if [ -z "$CKAN_CONFIG_PATH" ]; then
        # Use existing config file
        if [ -f "/run/secrets/ckan_config" ] && [ -f "/run/secrets/db_secret" ]; then
            abort "Both CKAN config and DB secret file specified. Please use one only."
        elif [ -f "/run/secrets/ckan_config" ] && [ -f "/run/secrets/smtp_secret" ]; then
            abort "Both CKAN config and SMTP secret file specified. Please use one only."
        elif [ -f "/run/secrets/ckan_config" ]; then
            echo "Linking existing config to $CONFIG"
            ln -sf /run/secrets/ckan_config "$CONFIG"
            echo "Extracting CKAN_SQLALCHEMY_URL"
            ######## LOGIC EXTRACT CKAN_SQLALCHEMY_URL from config file
        else
            echo "CKAN_CONFIG_PATH specified, but file doesn't exist"
        fi

    else
        echo "No CKAN config file provided."
        # Read DB Secret
        if [ -f "/run/secrets/db_secret" ]; then
            echo "database connection secret found, using variables for CKAN_SQLALCHEMY_URL"
            source /run/secrets/db_secret
            create_sqlalchemy_url
        else
            abort "ERROR: no db credentials secret found"
        fi
        # Read SMTP Secret
        if [ -f "/run/secrets/smtp_secret" ]; then
            echo "mailserver connection secret found, using variables"
            source /run/secrets/smtp_secret
        else
            abort "ERROR: no mailserver credentials secret found"
        fi
    fi
}

write_config () {
    echo "Generating config at ${CONFIG}..."
    ckan generate config "$CONFIG"
}


##### SCRIPT START #####

read_secrets

# Extract credentials from CKAN_SQLALCHEMY_URL
IFS=@ read -r CREDENTIALS CONNECTION <<< "$CKAN_SQLALCHEMY_URL"
IFS=/ read -r PG_DB SCHEMA <<< "$CREDENTIALS"
IFS=// read -r CONN_TYPE PG_CREDS <<< "$CONNECTION"
IFS=: read -r PG_USER PG_PASS <<< "$PG_CREDS"
# Wait for PostgreSQL
while ! pg_isready -h "$PG_DB" -U "$PG_USER"; do
    sleep 1;
done

# If we already have a config file, use it
if [ -f "$CONFIG" ]; then
    echo "production.ini found, using config file to start CKAN..."
    exec "$@"
fi

# Get or create CKAN_SQLALCHEMY_URL
if [ -z "$CKAN_SQLALCHEMY_URL" ]; then
    abort "ERROR: no CKAN_SQLALCHEMY_URL in env"
fi

if [ -z "$CKAN_SOLR_URL" ]; then
    abort "ERROR: no CKAN_SOLR_URL in env"
fi

if [ -z "$CKAN_REDIS_URL" ]; then
    abort "ERROR: no CKAN_REDIS_URL in env"
fi

# Create config .ini
write_config

# Add additional CKAN config
ckan config-tool "$CONFIG" "debug = $CKAN_DEBUG"
ckan config-tool "$CONFIG" "ckan.plugins = ${CKAN_PLUGINS}"
# # # ... add all config params

# Init DB and start
ckan --config "$CONFIG" db init
exec "$@"
