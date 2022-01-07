#!/bin/bash
set -e

PGPASSWORD="$CKAN_DB_PASS" pg_dump -C --format c\
    --host "$CKAN_DB_HOST" --username "$CKAN_DB_USER" \
    "$CKAN_DB_NAME" | \
    pg_restore --exit-on-error \
    --username postgres --dbname "$CKAN_DB_NAME"

PGPASSWORD="$CKAN_DB_PASS" pg_dump -C --format c\
    --host "$CKAN_DB_HOST" --username "$CKAN_DB_USER" \
    "$CKAN_DOI_DB_NAME" | \
    pg_restore --exit-on-error \
    --username postgres --dbname "$CKAN_DOI_DB_NAME"
