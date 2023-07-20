#!/bin/sh

set -eu

# Wait for CKAN host to be available with a timeout of 30 seconds
if ! timeout 30 wait-for-it "${CKAN_HOST}" --timeout=30; then
    echo "ERROR: CKAN host not available after waiting for 30 seconds."
    exit 1
fi
