#!/bin/bash

set -euo pipefail

while IFS=+ read -r _ repo_url; do
    mkdir ./ckanext
    git clone --depth 1 "$repo_url" ./ckanext
    if [ -f ./ckanext/requirements.txt ]; then
        echo "Installing dependencies for $repo_url"
        pip install --user --no-warn-script-location \
            --no-cache-dir -r ./ckanext/requirements.txt
    fi
    rm -rf ./ckanext
done < ./envidat_extensions.txt
