# ckan-container

Containerised CKAN, Postgres, Solr using Docker.

Use cases:

- Replicating an existing database, then running a dev CKAN server.
- Running production CKAN with an existing database.

## Production

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
datacite_publication.sqlalchemy.url = SERVICE_NAME.NAMESPACE.svc.cluster.local:5432
datacite_publication.site_id = xxx
datacite_publication.url_prefix = https://ingress_host_url/dataset/
datacite_publication.datacite_url = https://api.test.datacite.org/dois
datacite_publication.account_name = xxx
datacite_publication.account_password = xxx
ckanext.cloudstorage.container_name = envidat-dev
ckanext.cloudstorage.driver_options = {"key": "xxx", "secret": "xxx", "host": "https://minio.envidat.ch"}
ckanext.cloudstorage.use_secure_urls = 0
recaptcha.keys = xxx
```

## Development

### Modify .env for environment (optional)

- Change versions, registry connections, etc.

### Add secrets before running

- Create three files in the root of the repo:

**ckan.ini** contains the config for CKAN, including connection urls.

**.db.env** contains credentials of the remote database to replicate.

```dotenv
DB_HOST=xxxxxx.wsl.ch
DB_CKAN_NAME=envidat
DB_USER=xxenvidat
DB_PASS=xxxxxx
DB_DOI_NAME=envidat_doi
```

### Running

- Once the .env is configured, build the images with `docker compose build`
- Then once the secrets are set, run with `docker compose up -d`

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
