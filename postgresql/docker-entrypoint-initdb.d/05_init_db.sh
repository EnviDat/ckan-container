#!/bin/bash
set -e

DB_USER="${DB_USER:-dbenvidat}"
DB_USER="${DB_USER:-password}"
DB_CKAN_NAME="${DB_CKAN_NAME:-envidat}"
DB_DOI_NAME="${DB_DOI_NAME:-envidat_doi}"

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
