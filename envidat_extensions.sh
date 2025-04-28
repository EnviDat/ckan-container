#!/bin/bash

set -euo pipefail
EXT_DIR=./ckanext
echo "modifying $EXT_DIR"

mkdir -p "$EXT_DIR"
while IFS=+ read -r _ repo_url; do
    repo_name=$(basename "$repo_url" .git)
    repo_name="${repo_name%.git}"
    target_dir="$EXT_DIR/$repo_name"

    echo "Cloning $repo_url into $target_dir"
    git clone --depth 1 "$repo_url" "$target_dir"

done < ./envidat_extensions.txt
