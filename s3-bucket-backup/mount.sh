#!/bin/bash
set -e

export BACKUP_DEV_ENC="/backup-target/s3-bucket-${S3_BUCKET_NAME}"
export BACKUP_DEV="/backup"
export BACKUP_PATH="/backup/replica"
export BACKUP_DEV_MOUNTED=$(mount | grep "$BACKUP_DEV type fuse.gocryptfs")
export GOCRYPTFS_CONF="$BACKUP_DEV_ENC/gocryptfs.conf"
export GOCRYPTFS_PASSWD="/etc/encrypt-key/password"

if [[ ! -d $BACKUP_DEV ]]
  then
  echo "Creating backup device directory: $BACKUP_DEV"
  mkdir $BACKUP_DEV
fi

# Check if directory is not mounted, initialize if empty
if [[ -z $BACKUP_DEV_MOUNTED ]]
  then
  echo "Mounting encrypted filesystem."
  gocryptfs -nosyslog -q -passfile $GOCRYPTFS_PASSWD $BACKUP_DEV_ENC $BACKUP_DEV || exit
  export BACKUP_DEV_MOUNTED=$(mount | grep "$BACKUP_DEV type fuse.gocryptfs" | awk '{print $1,$2,$3}')
  echo "Filesystem mounted: $BACKUP_DEV_MOUNTED"
fi

sleep 3600
