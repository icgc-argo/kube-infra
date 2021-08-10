## mongo-backup

Backup files from S3 bucket to local storage.

## Install the chart

- Before install, configure Vault to allow backup pod to authenticate and retrieve secret. See [this guide](https://github.com/OICR/argo-infra/tree/master/helm/vault) for instruction.\*
- install the chart:
  ```
  helm upgrade -i s3-files-backup s3-files-backup --set encryptPassword="my_secure_password"
  ```

## Values

Job schedule (cron)

- `schedule: "55 */6 * * *"`

Volume claim name

- `targetPvcName: nfs-1`

Service account:

- `serviceAccount.name`: register this with vault policy

backupConfigs:

- `backupConfigs.S3_BUCKET_NAME`: S3 bucket name
- `backupConfigs.S3_ENDPOINT_URL`: S3 endpoint url
- `backupConfigs.BACKUP_ID`: this goes into `backup_target/<- backupConfigs.BACKUP_ID>` in the nfs
- `backupConfigs.VAULT_SECRET_PATH`: path to S3 access keys secret in vault
- `backupConfigs.VAULT_K8_ROLE`: register this with vault for pod role
- `backupConfigs.VAULT_ADDR`: FDQN of vault to retrieve secret from
