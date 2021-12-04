#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username postgres --dbname "$CKAN_DB_NAME" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS postgis;
    CREATE EXTENSION IF NOT EXISTS postgis_topology;
    CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
    CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;
    ALTER VIEW geometry_columns OWNER TO $CKAN_DB_USER;
    ALTER TABLE spatial_ref_sys OWNER TO $CKAN_DB_USER;