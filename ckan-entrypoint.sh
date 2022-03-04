#!/bin/bash
set -eo pipefail

CONFIG="${CKAN_CONFIG}/production.ini"
export CKAN_STORAGE_PATH=/opt/ckan/data

abort () {
    echo "$@" >&2
    exit 1
}

if [ -f "/home/ckan/ckan.ini" ]; then
    echo "Linking existing config to $CONFIG"
    ln -sf /home/ckan/ckan.ini "$CONFIG"
fi
if [ -f "$CONFIG" ]; then
    echo "Extracting CKAN_SQLALCHEMY_URL"
    CKAN_SQLALCHEMY_URL=$(awk -F " = " '/sqlalchemy.url/ {print $2;exit;}' "$CONFIG")
    echo "Extracting SOLR_HOST"
    SOLR_HOST=$(awk -F " = " '/solr_url/ {print $2;exit;}' "$CONFIG" | sed -e 's/\/solr\/ckan$//')
    echo "Extracting SOLR_USER"
    SOLR_USER=$(awk -F " = " '/solr_user/ {print $2;exit;}' "$CONFIG")
    echo "Extracting SOLR_PASS"
    SOLR_PASS=$(awk -F " = " '/solr_password/ {print $2;exit;}' "$CONFIG")
else
    abort "ERROR: No ckan.ini file found."
fi

# Wait for PostgreSQL
while ! pg_isready -d "$CKAN_SQLALCHEMY_URL"; do
    sleep 1;
done

echo "Attempting connection to Solr, please wait..."
# Wait for Solr
while [[ $response != "200" ]]; do
    response=$(curl --user "$SOLR_USER:$SOLR_PASS" \
        -s -o /dev/null -I -w '%{http_code}' \
        "$SOLR_HOST/solr/admin/cores?action=STATUS")
    echo "Response: $response"
    if [[ $response != "200" ]]; then
        echo "No status from Solr. Is it running or errored?"
        sleep 5;
    else
        echo "Successfully connected to Solr at $SOLR_HOST"
    fi
done

# Rebuild Solr search index
ckan --config /etc/ckan/production.ini search-index rebuild --only-missing

# Build web assets
ckan --config /etc/ckan/production.ini asset build

# Re-init cloudstorage db tables
ckan --config /etc/ckan/production.ini cloudstorage initdb

exec "$@"
