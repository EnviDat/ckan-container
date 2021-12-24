#!/bin/bash

set -euo pipefail

while read -r repo_url; do
    mkdir ./ckanext
    git clone --depth 1 "$repo_url" ./ckanext
    if [ -f ./ckanext/requirements.txt ]; then
        echo "Installing dependencies for $repo_url"
        pip install -r ./ckanext/requirements.txt
    fi
    rm -rf ./ckanext
done </opt/repos/envidat_extensions.txt
