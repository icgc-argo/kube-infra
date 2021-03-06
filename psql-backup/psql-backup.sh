#!/bin/sh
set -e

# sets up backup name
export TMP_DIR="/backup"
export SNAPSHOT_NAME="${TMP_DIR}/${BACKUP_ID}-snapshot-$(date +%Y-%m-%d_%H:%M:%S_%Z)"

# logs into vault
export SA_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token) \
  && export VAULT_TOKEN=$(vault write auth/kubernetes/login role=${VAULT_K8_ROLE} jwt=${SA_TOKEN} -format=json | jq -r '.auth.client_token')

# retrieves secret from vault
export PS_SECRETS="$(vault read -format=json -field=data ${VAULT_SECRET_PATH})" \
  && export PG_USER=$(echo $PS_SECRETS | jq -r '.["spring.datasource.username"]') \
  && export PGPASSWORD=$(echo $PS_SECRETS | jq -r '.["spring.datasource.password"]')

# Dump Database from postgresql
echo "Connecting to postgres database...."
pg_dump --host=$PG_HOST \
    --port=$PG_PORT \
    --username=$PG_USER \
    --dbname=$PG_DATABASE \
    --verbose \
    --format=tar > "${SNAPSHOT_NAME}.tar"
test -e "${SNAPSHOT_NAME}.tar"
echo "Created archive: ${SNAPSHOT_NAME}.tar"
gzip "${SNAPSHOT_NAME}.tar"

# moves psql dump to backup volume
echo "Encrypting...."
openssl aes-256-cbc -v -a -salt -in "${SNAPSHOT_NAME}.tar.gz"  -out "${SNAPSHOT_NAME}.enc" -pbkdf2 -kfile "/etc/psql-encrypt-key/password"
cp "${SNAPSHOT_NAME}.enc" /backup-target/${BACKUP_ID}
export OLD_BACKUPS="$(find /backup-target/${BACKUP_ID}/* -mtime "+$RETENTION")"
export RECENT_BACKUP_COUNT="$(find /backup-target/${BACKUP_ID}/* -mtime "-${RETENTION}" | wc -l)"
if [ "$OLD_BACKUPS" ] && [ "$RECENT_BACKUP_COUNT" -ge "$RETENTION" ];
  then echo "Deleting backups older than "$RETENTION" days:";
  echo "$OLD_BACKUPS";
  rm -v $OLD_BACKUPS;
fi
export CURRENT_BACKUPS="$(find /backup-target/${BACKUP_ID}/*)"
if [ "$CURRENT_BACKUPS" ]; then echo "Current backups:"; echo "$CURRENT_BACKUPS"; fi
