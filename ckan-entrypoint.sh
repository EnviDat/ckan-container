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
        SOLR_USER=$(awk -F " = " '/solr_user/ {print $2;exit;}' "$CONFIG")
        SOLR_PASS=$(awk -F " = " '/solr_password/ {print $2;exit;}' "$CONFIG")
    else
        abort "ERROR: CKAN_CONFIG_PATH specified, but file doesn't exist."
    fi

else
    abort "ERROR: No CKAN config file provided."
fi

# Wait for PostgreSQL
while ! pg_isready -d "$CKAN_SQLALCHEMY_URL"; do
    sleep 1;
done

# Wait for Solr
while [[ $response != "200" ]]; do
    response=$(curl --user "$SOLR_USER:$SOLR_PASS" \
        -s -o /dev/null -I -w '%{http_code}' \
        http://solr:8983/solr/admin/cores?action=STATUS)
    if [[ $response != "200" ]]; then
        echo "No response from Solr. Is it running?"
        sleep 5;
    else
        echo "Successfully connected to Solr."
    fi
done

exec "$@"
