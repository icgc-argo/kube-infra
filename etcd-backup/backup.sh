#!/bin/sh
set -e
# etcd credentials
. /etc/etcd.env
export SNAPSHOT_NAME="/backup/etcd-snapshot-$(date +%Y-%m-%d_%H:%M:%S_%Z).db"

# dump etcd database
echo "Exporting etcd database..."
etcdctl --cacert="$ETCD_PEER_TRUSTED_CA_FILE" --cert="$ETCD_CERT_FILE" --key="$ETCD_KEY_FILE" snapshot save "$SNAPSHOT_NAME"
gzip "$SNAPSHOT_NAME"
echo "Encrypting backups..."
openssl aes-256-cbc -v -a -salt -in "$SNAPSHOT_NAME.gz"  -out "$SNAPSHOT_NAME.enc" -pbkdf2 -kfile /etc/etcd-encrypt-key/password

# adduser nfs -u "$NFS_USER_ID" --system --no-create-home || true

echo "Copying backups to the target..."
chown -R backup-infra "$SNAPSHOT_NAME.enc"
su backup-infra -s /bin/sh -c 'cp "$SNAPSHOT_NAME.enc" /backup-target/etcd'
rm -f /backup/etcd-snapshot*

# rotate old backups
echo "Rotating backups..."
export OLD_BACKUPS="$(find /backup-target/etcd/* -mtime "+$RETENTION")"
export RECENT_BACKUP_COUNT="$(find /backup-target/etcd/* -mtime "-$RETENTION" | wc -l)"
su backup-infra -s /bin/sh -c  \
  'if [ "$OLD_BACKUPS" ] && [ "$RECENT_BACKUP_COUNT" -ge "$RETENTION" ];
    then echo "Deleting backups older than "$RETENTION" days:";
    echo "$OLD_BACKUPS";
    rm -v $OLD_BACKUPS;
  fi'
export CURRENT_BACKUPS="$(find /backup-target/etcd/*)"
if [ "$CURRENT_BACKUPS" ]; then echo "Current backups:"; echo "$CURRENT_BACKUPS"; fi
