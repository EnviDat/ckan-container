# ckan-container

Containerised CKAN, Postgres, Solr using Docker.

Use cases:

- Replicating an existing database, then running a dev CKAN server.
- Running production CKAN with an existing database.

## Production - Docker

The easiest way is to run using the [interactive script](#envidat-in-a-box).

Alternativly, follow the steps below.

### Setting the Solr credentials

- During development dummy credentials are used for Solr.
- In production we must set the Solr container user and password.

> The SOLR_CKAN_PASS must match the credentials specified in `ckan.ini`.

**.solr.env** contains credentials of the Solr instance.

```dotenv
SOLR_ADMIN_PASS=xxxx
SOLR_CKAN_PASS=xxxx
```

### Run the production containers

```bash
docker compose -f docker-compose.prod.yml up -d
```

## Development

### Modify .env for environment (optional)

- Change versions, registry connections, etc.

### Create config/ckan.ini

This file contains the config for CKAN, including connection urls.

To generate an example `ckan.ini` file via terminal:

```bash
docker run --rm --entrypoint=sh \
    registry-gitlab.wsl.ch/envidat/ckan-container/ckan:2.10.1-main \
    -c "ckan generate config ckan.ini && cat ckan.ini"
```

### A) Replicating an existing DB

This is the default configuration when running `docker-compose.yml`.

**.db.env** contains credentials of the remote database to replicate.

```dotenv
DB_HOST=xxxxxx.wsl.ch
DB_CKAN_NAME=envidat
DB_USER=xxenvidat
DB_PASS=xxxxxx
DB_DOI_NAME=envidat_doi
```

- Build the images with `docker compose build`.
- Then run with `docker compose up -d`.

> The database will be replicated when the containers start.

### B) Using a fresh DB

Alternatively, a fresh database can be used for CKAN.

To do this, run with this command instead:

```bash
DB_ENV_FILE=/dev/null docker compose up -d
```

### Reinstalling ckanext_xxx after editing

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

### Using local dev version of ckan or ckanext

- Create a symlink to the code:

```bash
ln -s ../ckan/ckan ./ckan
ln -s ../ckanext-passwordless_api/ckanext/passwordless_api ./ckanext/passwordless_api
```

- Mount the directories in your container:

```yaml
# docker-compose.yaml
---
volumes:
  - ../ckan:/usr/lib/ckan/.local/lib/python3.10/site-packages/ckan
  - ./ckanext/passwordless_api:/usr/lib/ckan/.local/lib/python3.10/site-packages/ckanext/passwordless_api
```

## Production - K8S

- Helm deploy (see chart directory README.md with values and secrets).
- Modify ckan.ini secret (example parameters below):

```ini
beaker.session.secret = xxx
app_instance_uuid = xxx-xxx-xxx-xxx-xxx
ckan.site_url = ingress_host_url
ckan.site_description = EnviDat Prod
ckan.storage_path = /data/ckan/default
ckan.cors.origin_whitelist = envidat.ch frontend.envidat.ch
sqlalchemy.url = SERVICE_NAME.NAMESPACE.svc.cluster.local:5432
solr_url = SERVICE_NAME.NAMESPACE.svc.cluster.local:8983
solr_password = xxx
ckan.redis.url = SERVICE_NAME.NAMESPACE.svc.cluster.local:6379
ckanext.cloudstorage.container_name = envidat-dev
ckanext.cloudstorage.driver_options = {"key": "xxx", "secret": "xxx", "host": "https://minio.envidat.ch"}
ckanext.cloudstorage.use_secure_urls = 0
recaptcha.keys = xxx
```

## EnviDat In A Box

The goal of this script is to start both the EnviDat backend and frontend interactively.

It achieves three things:

- Setting up the environment, including installing Docker.
- Setting the configuration required to run the containers.
- Running the containers.

## Via statically linked binary

```bash
curl -LO https://gitlabext.wsl.ch/EnviDat/ckan-container/-/jobs/19149/artifacts/raw/envidat
chmod +x envidat
sudo mv envidat /usr/local/bin/
envidat
```

This will add the envidat program to your PATH for easy execution.

## Via SH

```sh
. scripts/envidat-in-a-box.sh
```

## Via BASH

```sh
source scripts/envidat-in-a-box.sh
```
