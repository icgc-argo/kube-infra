. /etc/clinical-mongo.env

# sets up backup name
export SNAPSHOT_NAME="${BACKUP_ID}-snapshot-$(date +%Y-%m-%d_%H:%M:%S_%Z)"

# downloads vault binary
export VAULT_BINARY_URL=https://releases.hashicorp.com/vault/1.4.0/vault_1.4.0_linux_amd64.zip \
  && export VAULT_BINARY_ZIP=vault.zip \
  && curl $VAULT_BINARY_URL --output $VAULT_BINARY_ZIP \
  && unzip $VAULT_BINARY_ZIP \
  && rm $VAULT_BINARY_ZIP

# downloads jq binary 
curl -LJO https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 \
  && mv jq-linux64 jq \
  && chmod +x jq

# logs into vault
export SA_TOKEN=$(cat ./var/run/secrets/kubernetes.io/serviceaccount/token) \
  && export VAULT_TOKEN=$(./vault write auth/kubernetes/login role=${VAULT_K8_ROLE} jwt=${SA_TOKEN} -field=token)
  && ./vault login $VAULT_TOKEN

# retrieves secret from vault
export VAULT_MONGO_SECRET="$(./vault read -format=json -field=data ${VAULT_SECRET_PATH})" \
  && export MONGO_USERNAME=$(echo $VAULT_MONGO_SECRET \
    | ./jq '.content' \
    | ./jq 'fromjson.CLINICAL_DB_USERNAME') \
  && export MONGO_PASS=$(echo $VAULT_MONGO_SECRET \
    | ./jq '.content' \
    | ./jq 'fromjson.CLINICAL_DB_PASSWORD')

# cleans up binaries
rm ./vault && rm ./jq

# creates mongo dump
mongodump --host=$MONGO_HOST \
  --port=$MONGO_PORT \
  --username=$MONGO_USERNAME \
  --password=$MONGO_PASS \
  --authenticationDatabase=$MONGO_DATABASE \
  --out=$SNAPSHOT_NAME \
  && tar -cv $SNAPSHOT_NAME | gzip > "${SNAPSHOT_NAME}.tar.gz" \
  && rm -rf $SNAPSHOT_NAME

# moves mongo dump to backup backup volume
openssl aes-256-cbc -a -salt -in "${SNAPSHOT_NAME}.tar.gz"  -out "$SNAPSHOT_NAME.enc" -pbkdf2 -kfile "/etc/${BACKUP_ID}-encrypt-key/password"
adduser nfs -u "$NFS_USER_ID" --system --no-create-home || true
chown -R nfs "$SNAPSHOT_NAME.enc"
su nfs -s /bin/sh -c 'cp "$SNAPSHOT_NAME.enc" /backup-target/${BACKUP_ID}'
export OLD_BACKUPS="$(find /backup-target/${BACKUP_ID}/* -mtime "+$RETENTION")"
export RECENT_BACKUP_COUNT="$(find /backup-target/${BACKUP_ID}/* -mtime "-$RETENTION" | wc -l)"
su nfs -s /bin/sh -c  \
  'if [ "$OLD_BACKUPS" ] && [ "$RECENT_BACKUP_COUNT" -ge "$RETENTION" ];
    then echo "Deleting backups older than "$RETENTION" days:";
    echo "$OLD_BACKUPS";
    rm -v $OLD_BACKUPS;
  fi'
export CURRENT_BACKUPS="$(find /backup-target/${BACKUP_ID}/*)"
if [ "$CURRENT_BACKUPS" ]; then echo "Current backups:"; echo "$CURRENT_BACKUPS"; fi
