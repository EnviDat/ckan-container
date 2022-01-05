#!/bin/bash
set -eo pipefail


if [[ -f "/run/secrets/db_env_secret" ]]; then
    echo "db_env_secret secret found, sourcing..."
    source /run/secrets/db_env_secret
else
    echo "db_env_secret secret not found."
fi