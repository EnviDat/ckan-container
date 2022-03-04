#!/usr/local/bin/bash

abort () {
    echo "$@" >&2
    exit 1
}

# Check env vars
if [ -z "$SOLR_HOST" ]; then
    abort "ERROR: Solr host url not set in environment."
elif [ -z "$SOLR_ADMIN_PASS" ]; then
    abort "ERROR: Solr admin password not set in environment."
elif [ -z "$SOLR_CKAN_PASS" ]; then
    abort "ERROR: Solr user password not set in environment."
fi

echo "Attempting connection to Solr, please wait..."
# Wait for Solr
while [[ $response != "200" ]]; do
    response=$(curl --user "solr:SolrRocks" \
        -s -o /dev/null -I -w '%{http_code}' \
        "$SOLR_HOST/solr/admin/cores?action=STATUS")
    if [[ $response != "200" ]]; then
        if [[ $response == "401" ]]; then
            abort "Solr access unauthorised. Password already set."
        else
            echo "No response from Solr. Is it running?"
            sleep 5;
        fi
    else
        echo "Successfully connected to Solr."
    fi
done

curl --user "solr:SolrRocks" \
    "$SOLR_HOST/solr/admin/authentication" \
    -H 'Content-type:application/json' \
    -d '{"set-user": {"solr" : "'"${SOLR_ADMIN_PASS}"'" }}'

curl --user "solr:${SOLR_ADMIN_PASS}" \
    "$SOLR_HOST/solr/admin/authentication" \
    -H 'Content-type:application/json' \
    -d '{"set-user": {"ckan":"'"${SOLR_CKAN_PASS}"'"}}'

curl --user "solr:${SOLR_ADMIN_PASS}" \
    "$SOLR_HOST/solr/admin/authorization" \
    -H 'Content-type:application/json' \
    -d '{"set-user-role" : {"ckan": "basic"}}'
