. /etc/etcd.env
export SNAPSHOT_NAME="/backup/etcd-snapshot-$(date +%Y-%m-%d_%H:%M:%S_%Z).db"
etcdctl --cacert="$ETCD_PEER_TRUSTED_CA_FILE" --cert="$ETCD_CERT_FILE" --key="$ETCD_KEY_FILE" snapshot save "$SNAPSHOT_NAME"
gzip "$SNAPSHOT_NAME"
openssl aes-256-cbc -a -salt -in "$SNAPSHOT_NAME.gz"  -out "$SNAPSHOT_NAME.enc" -pbkdf2 -kfile /etc/etcd-encrypt-key/password
adduser nfs -u "$NFS_USER_ID" --system --no-create-home || true
chown -R nfs "$SNAPSHOT_NAME.enc"
su nfs -s /bin/sh -c 'cp "$SNAPSHOT_NAME.enc" /backup-target/etcd'
rm -f /backup/etcd-snapshot*
export OLD_BACKUPS="$(find /backup-target/etcd/* -mtime "+$RETENTION")"
export RECENT_BACKUP_COUNT="$(find /backup-target/etcd/* -mtime "-$RETENTION" | wc -l)"
su nfs -s /bin/sh -c  \
  'if [ "$OLD_BACKUPS" ] && [ "$RECENT_BACKUP_COUNT" -ge "$RETENTION" ];
    then echo "Deleting backups older than "$RETENTION" days:";
    echo "$OLD_BACKUPS";
    rm -v $OLD_BACKUPS;
  fi'
export CURRENT_BACKUPS="$(find /backup-target/etcd/*)"
if [ "$CURRENT_BACKUPS" ]; then echo "Current backups:"; echo "$CURRENT_BACKUPS"; fi
