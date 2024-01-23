#!/bin/bash
set -e

export BACKUP_PATH="/backup-target/s3-bucket-${S3_BUCKET_NAME}/${S3_BUCKET_PATH}"
export SNAP_PATH="/backup-target/s3-bucket-${S3_BUCKET_NAME}/snap"
export EFFECTIVE_USER=$(whoami)

if ! [[ -d $BACKUP_PATH ]]; then
  echo "$BACKUP_PATH directory doesnt exist, creating ... "
  mkdir -p $BACKUP_PATH
fi

if ! [[ -d $SNAP_PATH ]]; then
  echo "$SNAP_PATH directory doesnt exist, creating ... "
  mkdir -p $SNAP_PATH
fi

#rsnapshot needs this
if ! [[ -O $SNAP_PATH ]]; then
  echo "$SNAP_PATH not owned by $EFFECTIVE_USER, chowning ... "
  chown -v $(whoami) $SNAP_PATH
fi

echo "Back up bucket: s3://${S3_BUCKET_NAME}/${S3_BUCKET_PATH}"
echo "Back up target: $BACKUP_PATH"
echo "Backup started."
aws s3 sync s3://${S3_BUCKET_NAME}/${S3_BUCKET_PATH} $BACKUP_PATH
echo "Backup completed."

# rsnapshot
echo "Creating snapshot."
rsnapshot -c /opt/rsnapshot-conf/rsnapshot.conf alpha
echo "Completed snapshot."


