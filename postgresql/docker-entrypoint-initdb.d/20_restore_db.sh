#!/bin/bash

set -e

file1="/docker-entrypoint-initdb.d/ckan.dump"
file2="/docker-entrypoint-initdb.d/doi.dump"

echo "Restoring CKAN DB using $file1"
pg_restore -U postgres --dbname="$CKAN_DB_NAME" --verbose --single-transaction < "$file1" || exit 1

echo "Restoring DOI DB using $file2"
pg_restore -U postgres --dbname="$CKAN_DOI_DB_NAME" --verbose --single-transaction < "$file2" || exit 1
