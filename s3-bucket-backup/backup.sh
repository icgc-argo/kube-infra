#!/bin/bash
set -e

export BACKUP_DEV_ENC="/backup-target/s3-bucket-${S3_BUCKET_NAME}"
export BACKUP_DEV="/backup"
export BACKUP_PATH="/backup/replica"
export BACKUP_DEV_MOUNTED=$(mount | grep "$BACKUP_DEV type fuse.gocryptfs")


if [[ ! -d $BACKUP_DEV ]]
  then
  echo "Creating replica directory: $BACKUP_DEV"
  mkdir $BACKUP_DEV
fi


# Check if directory is not mounted, initialize if empty
if [[ -z $BACKUP_DEV_MOUNTED ]]
  then
    if [[ ! -f $BACKUP_DEV_ENC/gocryptfs.conf ]]
      then
      echo "Initializing encrypted volume."
      gocryptfs -init -plaintextnames -passfile /etc/encrypt-key/password $BACKUP_DEV_ENC
    fi
  echo "Mounting encrypted filesystem."
  gocryptfs -nosyslog -q -passfile /etc/encrypt-key/password $BACKUP_DEV_ENC $BACKUP_DEV || exit
  export BACKUP_DEV_MOUNTED=$(mount | grep "$BACKUP_DEV type fuse.gocryptfs" | awk '{print $1,$2,$3}')
  echo "Filesystem mounted: $BACKUP_DEV_MOUNTED"
fi

#check if mounted successfully
export BACKUP_DEV_MOUNTED=$(mount | grep "$BACKUP_DEV type fuse.gocryptfs")

if [[ -z $BACKUP_DEV_MOUNTED ]]
  then
    echo "Target filesystem not mounted. Exiting."
    exit
fi


echo "Back up bucket: s3://${S3_BUCKET_NAME}"
echo "Back up target: $BACKUP_DEV_ENC"
echo "Endpoint URL: $S3_ENDPOINT_URL"
echo "Backup started."
aws s3 sync s3://${S3_BUCKET_NAME} $BACKUP_PATH  --endpoint-url $S3_ENDPOINT_URL
echo "Backup completed."

# rsnapshot
echo "Creating snapshot."
rsnapshot -c /opt/rsnapshot-conf/rsnapshot.conf alpha

# cleanup
echo "Unmounting encrypted filesystem."
fusermount -u $BACKUP_DEV



