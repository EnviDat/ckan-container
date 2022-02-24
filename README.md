# ckan-container

Containerised CKAN, Postgres, Solr using Docker.

Use cases:

- Replicating an existing database, then running a dev CKAN server.
- Running production CKAN with an existing database.

## Production

- Helm deploy from chart dir.

## Development

#### Modify .env for environment

- Optional: change versions, registry connections.

#### Add secrets before running
- Create three files in the root of the repo:

**ckan.ini** contains the config for CKAN, including connection urls.

**.db.env** contains:
- Postgres password for local database.
- Credentials the remote database to replicate:
```
POSTGRES_PASSWORD=xxxxxx
DB_HOST=xxxxxx.wsl.ch
DB_CKAN_NAME=envidat
DB_USER=xxenvidat
DB_PASS=xxxxxx
DB_DOI_NAME=envidat_doi
```

**.solr.env** contains:
- Credentials for setting and connecting as users for Solr:
```
SOLR_ADMIN_PASS=xxxxxx
SOLR_CKAN_PASS=xxxxxx
```

#### Running

- Once the .env is configured, build the images with `docker compose build`
- Then once the secrets are set, run with `docker compose up -d`

#### Reinstalling ckanext_xxx after editing

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
