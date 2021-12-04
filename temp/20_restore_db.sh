#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username postgres --dbname postgres <<-EOSQL
    CREATE ROLE $CKAN_DB_USER WITH
        NOSUPERUSER
        NOCREATEDB
        NOCREATEROLE
        INHERIT
        LOGIN
        NOREPLICATION
        NOBYPASSRLS
        PASSWORD '$CKAN_DB_PASS';
    CREATE DATABASE $CKAN_DB_NAME WITH OWNER=$CKAN_DB_USER;
    CREATE DATABASE $CKAN_DOI_DB_NAME WITH OWNER=$CKAN_DB_USER;
EOSQL
root@22c63a517f58:/docker-entrypoint-initdb.d# ls
00_init_db.sh  10_postgis.sh  40_restore_db.sh  deleteme
root@22c63a517f58:/docker-entrypoint-initdb.d# cat 40
cat: 40: No such file or directory
root@22c63a517f58:/docker-entrypoint-initdb.d# cat 40_restore_db.sh
#!/bin/bash

file1="/docker-entrypoint-initdb.d/ckan.dump"
file2="/docker-entrypoint-initdb.d/doi.dump"

echo "Restoring CKAN DB using $file1"
pg_restore -U postgres --dbname=$CKAN_DB_NAME --verbose --single-transaction < "$file1" || exit 1

echo "Restoring DOI DB using $file2"
pg_restore -U postgres --dbname=$CKAN_DOI_DB_NAME --verbose --single-transaction < "$file2" || exit 1