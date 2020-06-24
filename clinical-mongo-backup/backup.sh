#!/bin/sh
set -e

# sets up backup name
export TMP_DIR="/backup"
export SNAPSHOT_NAME="${TMP_DIR}/${BACKUP_ID}-snapshot-$(date +%Y-%m-%d_%H:%M:%S_%Z)"
export VAULT=$(which vault)
export JQ=$(which jq)

# # downloads vault binary
# export VAULT_BINARY_URL=https://releases.hashicorp.com/vault/1.4.0/vault_1.4.0_linux_amd64.zip \
#   && export VAULT_BINARY_ZIP="${TMP_DIR}/vault.zip" \
#   && curl $VAULT_BINARY_URL --output $VAULT_BINARY_ZIP \
#   && unzip $VAULT_BINARY_ZIP -d $TMP_DIR \
#   && rm $VAULT_BINARY_ZIP \
#   && export VAULT="${TMP_DIR}/vault"

# # downloads jq binary
# export JQ_BINARY_PATH="${TMP_DIR}/jq" \
#   && curl -LJ https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 --output $JQ_BINARY_PATH \
#   && chmod +x $JQ_BINARY_PATH \
#   && export JQ=$JQ_BINARY_PATH


# logs into vault
export SA_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token) \
  && export VAULT_TOKEN=$($VAULT write auth/kubernetes/login role=${VAULT_K8_ROLE} jwt=${SA_TOKEN} -format=json | $JQ --raw-output '.auth.client_token')

# retrieves secret from vault
export VAULT_MONGO_SECRET="$($VAULT read -format=json -field=data ${VAULT_SECRET_PATH})" \
  && export MONGO_USERNAME=$(echo $VAULT_MONGO_SECRET \
    | $JQ --raw-output ".CLINICAL_DB_USERNAME") \
  && export MONGO_PASS=$(echo $VAULT_MONGO_SECRET \
    | $JQ --raw-output ".CLINICAL_DB_PASSWORD")

# creates mongo dump
echo "Creating mongo dump...."
mongodump --uri="mongodb://$MONGO_USERNAME:$MONGO_PASS@$MONGO_HOST:$MONGO_PORT/$MONGO_DATABASE?replicaSet=$MONGO_REPLICASET" \
  --out=$SNAPSHOT_NAME \
  && tar -cv $SNAPSHOT_NAME | gzip > "${SNAPSHOT_NAME}.tar.gz" \
  && rm -rf $SNAPSHOT_NAME

# moves mongo dump to backup backup volume
echo "Encrypting mongo dump...."
openssl aes-256-cbc -v -a -salt -in "${SNAPSHOT_NAME}.tar.gz"  -out "${SNAPSHOT_NAME}.enc" -kfile "/etc/encrypt-key/password"
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
