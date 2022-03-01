Chart for WSL EnviDat CKAN Backend.
- Interfaces with production database.
- Can autoscale with load.

Requires secrets to be pre-populated:
- **db-ckan-creds**
  - key: postgres-password
  - key: password (for user dbenvidat)
- **db-ckan-backup-creds**
  - key: DB_HOST
  - key: DB_USER
  - key: DB_PASS
- **solr-ckan-creds**
  - key: SOLR_HOST
  - key: SOLR_ADMIN_PASS
  - key: SOLR_CKAN_PASS
- **ckan-config-ini**
  - file: ckan.ini
    description: CKAN specific config file
- **envidat-star**
  - TLS cert
- **solr.envidat.ch-tls**
  - A copy of the envidat-star cert (name required for Solr).
  - To copy the secret from envidat-star, use:
  ```bash
  kubectl get secret envidat-star -o json \
  | jq 'del(.metadata["namespace","creationTimestamp","resourceVersion","selfLink","uid","annotations"])' \
  jq '.metadata.name = "solr.envidat.ch-tls"' | kubectl apply -f -
  ```
