# ckan-container

Containerised CKAN, Postgres, Solr using Docker.

Use cases:

- Replicating an existing database, then running a dev CKAN server.
- Running production CKAN with an existing database.

## Add secrets before running

**ckan.ini** contains the config for CKAN, including connection urls

**.postgres.secret** contains the password for postgres superuser only

**.db.secret** contains the postgres connection credentials for
the remote database (for replication), in format:
CKAN_DB_HOST=xxxxxx.wsl.ch
CKAN_DB_NAME=envidat
CKAN_DB_USER=xxenvidat
CKAN_DB_PASS=xxxxxx
CKAN_DOI_DB_NAME=envidat_doi

**.solr.secret** contains the credentials for setting and
connecting as users for Solr, in format:
SOLR_ADMIN_PASS=xxxxxx
SOLR_CKAN_PASS=xxxxxx

## Modify .env for environment

- Change the _INTERNAL_REG_ variable to match the desired container registry.

## Running

- Once the .env is configured, build the images with `docker compose build`
- Then once the secrets are set, run with `docker compose up -d`

## Reinstalling ckanext_xxx after editing

```bash
GIT_REPO=https://github.com/EnviDat/ckanext-cloudstorage.git
GIT_BRANCH=main

docker exec -it -u root:root ckan \
    bash -c 'apt update \
    && apt install git -y --no-install-recommends'

docker exec -it -u root:root ckan \
    pip install --upgrade --no-deps --force-reinstall \
    "git+${GIT_REPO}@${GIT_BRANCH}"
```
