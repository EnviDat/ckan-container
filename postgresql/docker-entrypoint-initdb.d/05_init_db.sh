#!/bin/bash
set -e

if [ -n "$NEW_DB" ]; then
    DB_USER="dbenvidat"
    DB_CKAN_NAME="envidat"
    DB_DOI_NAME="envidat_doi"
fi

psql -v ON_ERROR_STOP=1 --username postgres --dbname postgres <<-EOSQL
    CREATE ROLE $DB_USER WITH
        NOSUPERUSER
        NOCREATEDB
        NOCREATEROLE
        INHERIT
        LOGIN
        NOREPLICATION
        NOBYPASSRLS
        PASSWORD '$DB_PASS';
    CREATE DATABASE $DB_CKAN_NAME WITH OWNER=$DB_USER;
    CREATE DATABASE $DB_DOI_NAME WITH OWNER=$DB_USER;
EOSQL