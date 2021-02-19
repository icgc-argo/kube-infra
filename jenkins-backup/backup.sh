#!/bin/sh
# set -e

export snapshot_list=$(find $TB_PATH -type d  -maxdepth 1 -name "[FULL|DIFF]*" -mtime -7 | sort )
export setdate=$(date +%F)
export metadatainfo=${BACKUP_PATH}/metadata.info

checkdir() {
  mydir=$1
  touch $metadatainfo
  if [ ! -e "$mydir" ]; then
      echo "File $mydir does not exist"
      exit 1
  fi
  echo -n "ThinBackup found: "
  ls -lhd $mydir
}

checkbackup () {
  mydirpath=$1
  existingbackup=$(echo "$mydirpath" | egrep -f $metadatainfo)
  if [[ ! -z "$existingbackup" ]]; then
    echo "Backup exists for the file: $existingbackup, skipping..."
    continue 2
  fi
  }

compressdir() {
  mydirpath=$1
  mydirname=$(basename $mydirpath)
  if [[ ! -f ${BACKUP_PATH}/${mydirname}.tgz ]]; then
    echo "Compressing: ${mydirpath} to ${BACKUP_PATH}/${mydirname}.tgz"
    tar cf - -C ${TB_PATH} "${mydirname}" | gzip -1 - > "${BACKUP_PATH}/${mydirname}.tgz"
    echo -n  "Created archive: "
    ls -lh ${BACKUP_PATH}/${mydirname}.tgz
    else
      echo "File exists: ${BACKUP_PATH}/${mydirname}.tgz"
  fi
}

encryptdir() {
  mydirpath=$1
  mydirname=$(basename $mydirpath)
  echo "Encrypting: ${BACKUP_PATH}/${mydirname}.tgz to ${BACKUP_PATH}/${mydirname}.enc"
  openssl aes-256-cbc -v -a -salt -in "${BACKUP_PATH}/${mydirname}.tgz"  -out "${BACKUP_PATH}/${mydirname}.enc" -pbkdf2 -kfile /etc/encrypt-key/password
  echo -n "Created encrypted archive: "
  ls -lh ${BACKUP_PATH}/${mydirname}.enc

  echo "Deleting original archive: ${BACKUP_PATH}/${mydirname}.tgz"
  rm "${BACKUP_PATH}/${mydirname}.tgz"

  echo "Copying file ${BACKUP_PATH}/${mydirname}.enc  to backup target /backup-target/${BACKUP_ID}"
  cp "${BACKUP_PATH}/${mydirname}.enc" /backup-target/${BACKUP_ID} || exit 1
  echo "File copied:"
  ls -lh /backup-target/${BACKUP_ID}/${mydirname}.enc
}

storemetadata() {
  touch $metadatainfo || exit
  mydirpath=$1
  mydirname=$(basename $mydirpath)
  echo "Updating metadata: \"$mydirpath\""
  echo "$mydirpath"  >> $metadatainfo
}

for i in $snapshot_list;
  do
    checkdir $i
    checkbackup $i
    compressdir $i
    encryptdir $i
    storemetadata $i
  done



export OLD_BACKUPS="$(find /backup-target/${BACKUP_ID}/*.enc -mtime "+$RETENTION")"
export RECENT_BACKUP_COUNT="$(find /backup-target/${BACKUP_ID}/*.enc -mtime "-$RETENTION" | wc -l)"

if [ "$OLD_BACKUPS" ] && [ "$RECENT_BACKUP_COUNT" -ge "$RETENTION" ];
  then echo "Deleting backups older than "$RETENTION" days:";
  echo "$OLD_BACKUPS";
  rm -v $OLD_BACKUPS;
fi

export CURRENT_BACKUPS="$(find /backup-target/${BACKUP_ID}/*.enc)"
if [ "$CURRENT_BACKUPS" ]; then echo "Current backups:"; echo "$CURRENT_BACKUPS"; fi
