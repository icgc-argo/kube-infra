#!/bin/sh
set -e
DATA_PATH="/kafka/data"
SNAP_PATH="/backup/snapshot"
SNAP_PATH_ENC="/backup/snapshot_enc"
RSNAP_CONFIG="/kafka-connect/rsnapshot.conf"

if [ ! -d  $DATA_PATH ]
  then
    echo "The path does not exist: $DATA_PATH"
    exit
fi
test -d  $SNAP_PATH || mkdir -p $SNAP_PATH
test -d  $SNAP_PATH_ENC || mkdir -p $SNAP_PATH_ENC

# use "standard" mode to allow rsnapshot hard links
(mount | grep "$SNAP_PATH") || ( cat /etc/encrypt-key/password | encfs $SNAP_PATH_ENC $SNAP_PATH --standard -S)

# rsnapshot
rsnapshot -c $RSNAP_CONFIG alpha

# cleanup
#fusermount -u $SNAP_PATH



