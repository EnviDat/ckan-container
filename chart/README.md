# EnviDat CKAN Chart
Chart for WSL EnviDat CKAN Backend.
- Interfaces with production database.
- Can autoscale with load.

## Secrets
Requires secrets to be pre-populated.

- **db-ckan-creds** for local database
  - key: postgres-password
  - key: password (for user dbenvidat)
  ```bash
  kubectl create secret generic db-ckan-creds \
    --from-literal=password=xxxxxxx \
    --from-literal=postgres-password=xxxxxxx
  ```

- **db-ckan-backup-vars** backup db credentials for replication
  ```bash
  kubectl create secret generic db-ckan-backup-vars \
    --from-literal=DB_HOST=db-ckan-backup-postgresql.ckan.svc.cluster.local \
    --from-literal=DB_PASS=xxxxxxx \
    --from-literal=DB_USER=dbenvidat
  ```

- **solr-ckan-vars** for local solr and ckan var injection
  - key: SOLR_HOST  (note: port also required)
  - key: SOLR_ADMIN_PASS
  - key: SOLR_CKAN_PASS
  ```bash
  kubectl create secret generic solr-ckan-vars \
    --from-literal=SOLR_HOST=ckan-dev-solr.ckan.svc.cluster.local:8983 \
    --from-literal=SOLR_ADMIN_PASS=xxxxxxx \
    --from-literal=SOLR_CKAN_PASS=xxxxxxx
  ```

- **ckan-config-ini** for ckan config
  - file: ckan.ini
    description: CKAN specific config file
  ```bash
  kubectl create secret generic ckan-config-ini --from-file ckan.ini
  ```

- **envidat-star** for https / tls certs
  - Standard Kubernetes TLS secret for *.envidat.ch
- **solr.envidat.ch-tls**
  - A copy of the envidat-star cert (name required for Solr).
  - To copy the secret from envidat-star, use:
  ```bash
  kubectl get secret envidat-star -o json \
  | jq 'del(.metadata["namespace","creationTimestamp","resourceVersion","selfLink","uid","annotations"])' \
  jq '.metadata.name = "solr.envidat.ch-tls"' | kubectl apply -f -
  ```

## Deployment
`helm upgrade --install ckan oci://registry.envidat.ch/envidat/envidat-frontend --namespace ckan`

For staging/develop versions, change release name & override values with `--values values.yaml`.
