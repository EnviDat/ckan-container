# EnviDat CKAN Chart

Chart for WSL EnviDat CKAN Backend.

- Interfaces with production database.
- Can autoscale with load.

## Secrets

Requires secrets to be pre-populated.

- Note: production variables. For another branch add a suffix, e.g. db-ckan-**dev**-vars.

- **db-ckan-creds** for postgres database (required by helm chart)

  - key: postgres-password
  - key: password (for user dbenvidat)

  ```bash
  kubectl create secret generic db-ckan-creds \
    --from-literal=password=xxxxxxx \
    --from-literal=postgres-password=xxxxxxx
  ```

- **db-ckan-vars** restore db (postgres user) credentials for replication

  ```bash
  kubectl create secret generic db-ckan-vars \
  --from-literal=RESTORE_DB_HOST=ckan-db.ckan.svc.cluster.local \
  --from-literal=RESTORE_DB_PG_PASS=xxxxxxx
  ```

- **db-ckan-backup-vars** backup db credentials for replication

  ```bash
  kubectl create secret generic db-ckan-backup-vars \
    --from-literal=BACKUP_DB_HOST=db-ckan-backup-postgresql.ckan.svc.
    cluster.local \
    --from-literal=BACKUP_DB_PASS=xxxxxxx \
    --from-literal
  ```

- **solr-ckan-vars** for local solr and ckan var injection

  - key: SOLR_HOST (note: port also required)
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

  - Standard Kubernetes TLS secret for \*.envidat.ch

- **solr.envidat.ch-tls**

  - A copy of the envidat-star cert (name required for Solr).
  - To copy the secret from envidat-star, use:

  ```bash
  kubectl get secret envidat-star -o json \
  | jq 'del(.metadata["namespace","creationTimestamp","resourceVersion",
  "selfLink","uid","annotations"])' \
  jq '.metadata.name = "solr.envidat.ch-tls"' | kubectl apply -f -
  ```

## Deployment

```shell
helm upgrade --install ckan oci://registry.envidat.ch/envidat/
envidat-frontend --namespace ckan
```

For staging/develop versions, change release name & override values with  
`--values values.yaml` or with `--set parameters`:

```shell
helm upgrade --install frontend-dev . \
  --set image.tag=0.7.0-dev \
  --set image.pullPolicy="Always" \
  --set ingress.hosts[0].host="frontend-dev.envidat.ch" \
  --set ingress.hosts[0].paths[0].path="/" \
  --set ingress.hosts[0].paths[0].pathType="ImplementationSpecific" \
  --set ingress.tls[0].secretName="envidat-star" \
  --set ingress.tls[0].hosts[0]="frontend-dev.envidat.ch" \
  --set autoscaling.enabled=false
```
