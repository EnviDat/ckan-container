#!/bin/bash
set -eo pipefail

abort () {
    echo "$@" >&2
    exit 1
}

if [ -f "$CKAN_INI" ]; then
    echo "Extracting CKAN_SQLALCHEMY_URL"
    CKAN_SQLALCHEMY_URL=$(awk -F " = " '/sqlalchemy.url/ {print $2;exit;}' "$CKAN_INI")
    echo "Extracting SOLR_HOST"
    SOLR_HOST=$(awk -F " = " '/solr_url/ {print $2;exit;}' "$CKAN_INI" | sed -e 's/\/solr\/ckan$//')
    echo "Extracting SOLR_USER"
    SOLR_USER=$(awk -F " = " '/solr_user/ {print $2;exit;}' "$CKAN_INI")
    echo "Extracting SOLR_PASS"
    SOLR_PASS=$(awk -F " = " '/solr_password/ {print $2;exit;}' "$CKAN_INI")
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

# Re-init core db tables
echo "Migrating database tables if required..."
ckan db init

# Re-init cloudstorage db tables
echo "Initialising cloudstorage database tables..."
ckan cloudstorage initdb

# Rebuild Solr search index
echo "Rebuilding Solr search index..."
ckan search-index rebuild --only-missing

# Build web assets
echo "Building web assets..."
ckan asset build

echo "---------------------"
echo "Init script complete."
echo "---------------------"
echo "Starting CKAN..."

exec "$@"
