#!/bin/sh
set -e

export SNAPSHOT_NAME=$(basename $(find $TB_PATH -type d  -maxdepth 1 -name FULL* -mtime -1 | sort | tail -1))
if [ ! -e "${TB_PATH}/${SNAPSHOT_NAME}" ]; then
    echo "File ${TB_PATH}/${SNAPSHOT_NAME} does not exist"
    exit 1
fi
echo "Backup found: $SNAPSHOT_NAME"

tar czf "${BACKUP_PATH}/${SNAPSHOT_NAME}.tgz" -C ${TB_PATH} "${SNAPSHOT_NAME}" || exit 1
echo "Created archive: ${BACKUP_PATH}/${SNAPSHOT_NAME}.tgz"

openssl aes-256-cbc -v -a -salt -in "${BACKUP_PATH}/${SNAPSHOT_NAME}.tgz"  -out "${BACKUP_PATH}/${SNAPSHOT_NAME}.enc" -pbkdf2 -kfile /etc/encrypt-key/password
rm "${BACKUP_PATH}/${SNAPSHOT_NAME}.tgz"
cp "${BACKUP_PATH}/${SNAPSHOT_NAME}.enc" /backup-target/${BACKUP_ID} || exit 1

export OLD_BACKUPS="$(find /backup-target/${BACKUP_ID}/*.enc -mtime "+$RETENTION")"
export RECENT_BACKUP_COUNT="$(find /backup-target/${BACKUP_ID}/*.enc -mtime "-$RETENTION" | wc -l)"

if [ "$OLD_BACKUPS" ] && [ "$RECENT_BACKUP_COUNT" -ge "$RETENTION" ];
  then echo "Deleting backups older than "$RETENTION" days:";
  echo "$OLD_BACKUPS";
  rm -v $OLD_BACKUPS;
fi

export CURRENT_BACKUPS="$(find /backup-target/${BACKUP_ID}/*.enc)"
if [ "$CURRENT_BACKUPS" ]; then echo "Current backups:"; echo "$CURRENT_BACKUPS"; fi
