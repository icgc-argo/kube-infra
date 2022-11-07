#!/bin/sh
set -e
TEST_DATA_PATH="/tmp/kafka/data"
TEST_DATA_FILE="file-$(date +%s)"
BACKUP_PATH="/tmp/backup"
BACKUP_PATH_ENC="/tmp/backup_enc"
SNAP_PATH="/tmp/snap"
SNAP_PATH_ENC="/tmp/snap_enc"


RSNAP_CONFIG="/kafka-connect/rsnapshot.conf"

test -d  $TEST_DATA_PATH || mkdir -p $TEST_DATA_PATH
# test -d  $BACKUP_PATH || mkdir -p $BACKUP_PATH
# test -d  $BACKUP_PATH_ENC || mkdir -p $BACKUP_PATH_ENC
test -d  $SNAP_PATH || mkdir -p $SNAP_PATH
test -d  $SNAP_PATH_ENC || mkdir -p $SNAP_PATH_ENC


#mount enc fs
ENC_PASSWORD=123

# use "standard" mode to allow rsnapshot hard links

# (mount | grep "$BACKUP_PATH") || (echo $ENC_PASSWORD | encfs $BACKUP_PATH_ENC $BACKUP_PATH --standard -S)
(mount | grep "$SNAP_PATH") || (echo $ENC_PASSWORD | encfs $SNAP_PATH_ENC $SNAP_PATH --standard -S)

# create test files
TOPIC_NAME=foo
SINK_NAME=bar
SINK_PATH="${TEST_DATA_PATH}"
SINK_FILE=${SINK_PATH}/${TOPIC_NAME}-${SINK_NAME}-$(date +%Y-%m).sink
test -f $SINK_FILE || dd if=/dev/urandom of=$SINK_FILE  bs=1M count=6
test -f ${TEST_DATA_PATH}/foo-bar-2020-12.sink || dd if=/dev/urandom of=${TEST_DATA_PATH}/foo-bar-2020-12.sink  bs=1M count=6
test -f ${TEST_DATA_PATH}/foo-bar-2020-11.sink || dd if=/dev/urandom of=${TEST_DATA_PATH}/foo-bar-2020-11.sink  bs=1M count=6
test -f ${TEST_DATA_PATH}/foo-bar-2020-10.sink || dd if=/dev/urandom of=${TEST_DATA_PATH}/foo-bar-2020-10.sink  bs=1M count=6
test -f ${TEST_DATA_PATH}/foo-bar-2020-09.sink || dd if=/dev/urandom of=${TEST_DATA_PATH}/foo-bar-2020-09.sink  bs=1M count=6
# ls -la $SINK_PATH/fo*


SNAPSHOT_NAME=$SINK_FILE
SNAPSHOT_DATE=$(date +%s)
SNAPSHOT_NAME_TGZ=$SNAPSHOT_NAME-$SNAPSHOT_DATE.tgz
SNAPSHOT_NAME_ENC=$SNAPSHOT_NAME-$SNAPSHOT_DATE.tgz.enc
SNAPSHOT_NAME_TGZ_LATEST=$SNAPSHOT_NAME-$SNAPSHOT_DATE-latest.tgz
SNAPSHOT_NAME_ENC_LATEST=$SNAPSHOT_NAME-$SNAPSHOT_DATE-latest.tgz.enc
# ENC_PASSWORD=/tmp/enc_password
# echo "123" > $ENC_PASSWORD


#rsync backup

# echo "rsync -avz $TEST_DATA_PATH $BACKUP_PATH"
# rsync -avz $TEST_DATA_PATH $BACKUP_PATH


# rsnapshot

rsnapshot -c $RSNAP_CONFIG alpha

# cleanup
  # fusermount -u $SNAP_PATH


# backup
# tar czf "${SNAPSHOT_NAME_TGZ}" "$SNAPSHOT_NAME" || exit 1
# echo "Created archive: ${SNAPSHOT_NAME_TGZ}"


# openssl aes-256-cbc -v -a -salt -in "${SNAPSHOT_NAME_TGZ}"  -out "${SNAPSHOT_NAME_ENC}" -pbkdf2 -kfile $ENC_PASSWORD
# rm "${SNAPSHOT_NAME_TGZ}"
# # ls -la $SINK_PATH/fo*
# RETENTION_MIN=7
# RETENTION_MAX=7
# OLD_BACKUPS=$(find $SNAPSHOT_NAME*tgz.enc -mtime +$RETENTION_MAX)
# OLD_BACKUPS_COUNT=$(find $SNAPSHOT_NAME*tgz.enc -mtime +$RETENTION_MAX | wc -l)
# RECENT_BACKUP=$(find $SNAPSHOT_NAME*tgz.enc -mtime -$RETENTION_MIN)
# RECENT_BACKUP_COUNT=$(find $SNAPSHOT_NAME*tgz.enc -mtime -$RETENTION_MIN | wc -l)
# echo Old backups: $OLD_BACKUPS
# echo Old backups count: $OLD_BACKUPS_COUNT
# echo Recent backups: $RECENT_BACKUP
# echo Recent backups count: $RECENT_BACKUP_COUNT

# if [ "$OLD_BACKUPS" ] && [ "$RECENT_BACKUP_COUNT" -ge "$RETENTION_MIN" ];
#   then
#     echo Removing $OLD_BACKUPS
#     # rm $OLD_BACKUPS

# fi

# cp "${BACKUP_PATH}/${SNAPSHOT_NAME_ENC}" ${BACKUP_TARGET} || exit 1
