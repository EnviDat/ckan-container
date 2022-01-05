# ckan-container

Containerised CKAN, Postgres, Solr using Docker.

Use cases:

- Replicating an existing database, then running a dev CKAN server.
- Running production CKAN with an existing database.

## Add secrets before running

_.postgres.secret_ contains the password for postgres superuser only

_.db.secret_ contains the postgres connection credentials for
the remote database (for replication), in format:
CKAN_DB_HOST=xxxxxx.wsl.ch
CKAN_DB_NAME=ckan_default
CKAN_DB_USER=ckan_default
CKAN_DB_PASS=xxxxxx
CKAN_DOI_DB_NAME=envidat_doi

_.solr.secret_ contains the credentials for setting and
connecting as users for Solr, in format:
SOLR_ADMIN_PASS=xxxxxx
SOLR_CKAN_PASS=xxxxxx

## Running

- Once the secrets are set, run with `docker compose up -d`
