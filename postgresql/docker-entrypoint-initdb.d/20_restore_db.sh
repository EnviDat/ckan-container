#!/bin/bash
set -e

if [ -z "$DB_HOST" ]; then
    echo "Halted recovering DB: DB_HOST is not set."
    exit 1
fi

echo "Backup and restoring $DB_CKAN_NAME via pipe to new host."
PGPASSWORD="$DB_PASS" pg_dump --verbose --format c \
    --extension=plpgsql \
    --exclude-table=package_extent --exclude-table=spatial_ref_sys \
    --host "$DB_HOST" --username "$DB_USER" "$DB_CKAN_NAME" \
    | pg_restore --verbose --exit-on-error \
    --username postgres --dbname "$DB_CKAN_NAME"

echo "Backup and restoring $DB_DOI_NAME via pipe to new host."
PGPASSWORD="$DB_PASS" pg_dump --verbose --format c \
    --extension=plpgsql \
    --exclude-table=package_extent --exclude-table=spatial_ref_sys \
    --host "$DB_HOST" --username "$DB_USER" "$DB_DOI_NAME" \
    | pg_restore --verbose --exit-on-error \
    --username postgres --dbname "$DB_DOI_NAME"
