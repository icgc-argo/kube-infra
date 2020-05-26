# export TMP_DIR="/backup"
# export SNAPSHOT_NAME="${TMP_DIR}/${BACKUP_ID}-snapshot-$(date +%Y-%m-%d_%H:%M:%S_%Z)"
# export CONSUL_BIN="/bin/jenkins"
# export TB_PATH="/bin/jenkins"

export SNAPSHOT_NAME=$(basename $(find $TB_PATH -type d  -maxdepth 1 -name FULL* -mtime -1 | sort | tail -1))

if [ ! -e "${TB_PATH}/${SNAPSHOT_NAME}" ]; then
    echo "File ${TB_PATH}/${SNAPSHOT_NAME} does not exist"
    exit 1
fi
echo "Backup found: $SNAPSHOT_NAME"

tar czf "${TB_PATH}/${SNAPSHOT_NAME}.tgz" -C ${TB_PATH} "${SNAPSHOT_NAME}"
echo "Created archive: ${TB_PATH}/${SNAPSHOT_NAME}.tgz"

openssl aes-256-cbc -a -salt -in "${TB_PATH}/${SNAPSHOT_NAME}.tgz"  -out "${TB_PATH}/${SNAPSHOT_NAME}.enc" -pbkdf2 -kfile /etc/encrypt-key/password
rm  "${TB_PATH}/${SNAPSHOT_NAME}.tgz"
mv "${TB_PATH}/${SNAPSHOT_NAME}.enc" /backup-target/${BACKUP_ID}

export OLD_BACKUPS="$(find /backup-target/${BACKUP_ID}/*.enc -mtime "+$RETENTION")"
export RECENT_BACKUP_COUNT="$(find /backup-target/${BACKUP_ID}/* -mtime "-$RETENTION" | wc -l)"

if [ "$OLD_BACKUPS" ] && [ "$RECENT_BACKUP_COUNT" -ge "$RETENTION" ];
  then echo "Deleting backups older than "$RETENTION" days:";
  echo "$OLD_BACKUPS";
  rm -v $OLD_BACKUPS;
fi

export CURRENT_BACKUPS="$(find /backup-target/${BACKUP_ID}/*.enc)"

if [ "$CURRENT_BACKUPS" ]; then echo "Current backups:"; echo "$CURRENT_BACKUPS"; fi
