#!/bin/sh
set -e

# sets up backup name
export TMP_DIR="/backup"
export SNAPSHOT_NAME="${TMP_DIR}/${BACKUP_ID}-snapshot-$(date +%Y-%m-%d_%H:%M:%S_%Z)"
export VAULT=$(which vault)
export JQ=$(which jq)


# logs into vault
export SA_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token) \
  && export VAULT_TOKEN=$($VAULT write -field=token auth/kubernetes/login role=${VAULT_K8_ROLE} jwt=${SA_TOKEN})


# retrieves secret from vault
export MONGO_USERNAME=$($VAULT kv get -field=CLINICAL_DB_USERNAME ${VAULT_SECRET_PATH})
export MONGO_PASS=$($VAULT kv get -field=CLINICAL_DB_PASSWORD ${VAULT_SECRET_PATH})

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
