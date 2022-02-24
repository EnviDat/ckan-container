#!/bin/sh

abort () {
    echo "$@" >&2
    exit 1
}

if [ -z "$SOLR_CKAN_PASS" ]; then
    abort "ERROR: Solr passwords not set in environment."
fi

echo "Sleeping 5 seconds."
sleep 5;

curl --user solr:SolrRocks \
    http://solr:8983/solr/admin/authentication \
    -H 'Content-type:application/json' \
    -d '{"set-user": {"solr" : "'"${SOLR_ADMIN_PASS}"'" }}'

curl --user "solr:${SOLR_ADMIN_PASS}" \
    http://solr:8983/solr/admin/authentication \
    -H 'Content-type:application/json' \
    -d '{"set-user": {"ckan":"'"${SOLR_CKAN_PASS}"'"}}'

curl --user "solr:${SOLR_ADMIN_PASS}" \
    http://solr:8983/solr/admin/authorization \
    -H 'Content-type:application/json' \
    -d '{"set-user-role" : {"ckan": "basic"}}'
