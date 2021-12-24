#!/bin/bash
set -eo pipefail

CONFIG="${CKAN_CONFIG}/production.ini"
export CKAN_STORAGE_PATH=/var/lib/ckan

abort () {
    echo "$@" >&2
    exit 1
}

if [ -z "$CKAN_CONFIG_PATH" ]; then
    if [ -f "/run/secrets/ckan_config" ]; then
        echo "Linking existing config to $CONFIG"
        ln -sf /run/secrets/ckan_config "$CONFIG"
        echo "Extracting CKAN_SQLALCHEMY_URL"
        CKAN_SQLALCHEMY_URL=$(awk -F " = " '/sqlalchemy.url/ {print $2;exit;}' "$CONFIG")
    else
        abort "ERROR: CKAN_CONFIG_PATH specified, but file doesn't exist."
    fi

else
    abort "ERROR: No CKAN config file provided."
fi

# Extract credentials from CKAN_SQLALCHEMY_URL
IFS=@ read -r CREDENTIALS CONNECTION <<< "$CKAN_SQLALCHEMY_URL"
IFS=/ read -r PG_DB _ <<< "$CREDENTIALS"
IFS=// read -r _ PG_CREDS <<< "$CONNECTION"
IFS=: read -r PG_USER _ <<< "$PG_CREDS"
# Wait for PostgreSQL
while ! pg_isready -h "$PG_DB" -U "$PG_USER"; do
    sleep 1;
done

exec "$@"
