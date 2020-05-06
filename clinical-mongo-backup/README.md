## mongo-backup

Backup clinical-mongo data to a persistent volume claim. It is NFS for now and create manually.
Mongo client creates snapshot and saves locally as encrypted file.

## Install the chart

- Before install, configure Vault to allow backup pod to authenticate and retrieve secret. See [this guide](https://github.com/OICR/argo-infra/tree/master/helm/vault) for instruction.\*
- install the chart:
  ```
  helm upgrade -i clinical-mongo-backup clinical-mongo-backup --set encryptPassword="my_secure_password"
  ```

## Values

Mongo client use Vault to authenticate.

Job schedule (cron)

- `schedule: "55 */6 * * *"`

Volume claim name

- `targetPvcName: nfs-1`

Service account:

- `serviceAccount.name`: register this with vault policy

backupConfigs:

- `backupConfigs.MONGO_HOST`: FDQN of mongo to back up
- `backupConfigs.MONGO_PORT`: port number
- `backupConfigs.MONGO_DATABASE`: `clinical` by default
- `backupConfigs.MONGO_REPLICASET`: `rs0` by default
- `backupConfigs.BACKUP_ID`: this goes into `backup_target/<- backupConfigs.BACKUP_ID>` in the nfs
- `backupConfigs.VAULT_SECRET_PATH`: path to mongo secret in vault
- `backupConfigs.VAULT_K8_ROLE`: register this with vault for pod role
- `backupConfigs.VAULT_ADDR`: FDQN of vault to retrieve secret from
