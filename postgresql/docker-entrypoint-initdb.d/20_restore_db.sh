#!/bin/bash
set -e

echo "Backup and restoring $DB_CKAN_NAME via pipe to new host."
PGPASSWORD="$DB_PASS" pg_dump --verbose --format c \
    --host "$DB_HOST" --username "$DB_USER" "$DB_CKAN_NAME" \
    | pg_restore --verbose --exit-on-error \
    --username postgres --dbname postgres

echo "Backup and restoring $DB_DOI_NAME via pipe to new host."
PGPASSWORD="$DB_PASS" pg_dump --verbose --format c \
    --host "$DB_HOST" --username "$DB_USER" "$DB_DOI_NAME" \
    | pg_restore --verbose --exit-on-error \
    --username postgres --dbname postgres
