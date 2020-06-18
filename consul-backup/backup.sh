#!/bin/sh
set -e

export TMP_DIR="/backup"
export SNAPSHOT_NAME="${TMP_DIR}/${BACKUP_ID}-snapshot-$(date +%Y-%m-%d_%H:%M:%S_%Z)"
export CONSUL_BIN="/bin/consul"


${CONSUL_BIN} snapshot save ${SNAPSHOT_NAME} || exit 1
test -e ${SNAPSHOT_NAME} || exit 1

gzip "${SNAPSHOT_NAME}"
openssl aes-256-cbc -v -a -salt -in "${SNAPSHOT_NAME}.gz"  -out "${SNAPSHOT_NAME}.enc" -pbkdf2 -kfile /etc/encrypt-key/password

cp "${SNAPSHOT_NAME}.enc" /backup-target/${BACKUP_ID}

export OLD_BACKUPS="$(find /backup-target/${BACKUP_ID}/* -mtime "+$RETENTION")"
export RECENT_BACKUP_COUNT="$(find /backup-target/${BACKUP_ID}/* -mtime "-$RETENTION" | wc -l)"

if [ "$OLD_BACKUPS" ] && [ "$RECENT_BACKUP_COUNT" -ge "$RETENTION" ];
  then echo "Deleting backups older than "$RETENTION" days:";
  echo "$OLD_BACKUPS";
  rm -v $OLD_BACKUPS;
fi

export CURRENT_BACKUPS="$(find /backup-target/${BACKUP_ID}/*)"

if [ "$CURRENT_BACKUPS" ]; then echo "Current backups:"; echo "$CURRENT_BACKUPS"; fi
