#!/bin/bash
set -eo pipefail

# Create temp dev databases replicating existing databases.
# Uses the postgres superuser account to dump and pipe in PSQL prompt.
# Preferable to SQL create via template, as does not require disconnections.

sudo -u postgres dropdb dev_ckan_default
sudo -u postgres createdb --owner=ckan_default dev_ckan_default
sudo -u postgres pg_dump ckan_default | sudo -u postgres psql dev_ckan_default

sudo -u postgres dropdb dev_envidat_doi
sudo -u postgres createdb --owner=ckan_default dev_envidat_doi
sudo -u postgres pg_dump envidat_doi | sudo -u postgres psql dev_envidat_doi
