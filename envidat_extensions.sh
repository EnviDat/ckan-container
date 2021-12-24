#!/bin/bash

set -euo pipefail

while IFS=+ read -r _ repo_url; do
    mkdir ./ckanext
    git clone --depth 1 "$repo_url" ./ckanext
    if [ -f ./ckanext/requirements.txt ]; then
        echo "Installing dependencies for $repo_url"
        PIPENV_VENV_IN_PROJECT=1 pipenv run \
            python -m pip install -r "./ckanext/requirements.txt"
    elif [ -f ./ckanext/pip-requirements.txt ]; then
        echo "Installing dependencies for $repo_url"
        PIPENV_VENV_IN_PROJECT=1 pipenv run \
            python -m pip install -r "./ckanext/pip-requirements.txt"
    fi
    rm -rf ./ckanext
done </opt/repos/envidat_extensions.txt
