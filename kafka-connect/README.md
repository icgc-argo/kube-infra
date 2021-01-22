### **Backup overview**

Kafka connect chart does the following:

1. Kafka connect reads data from the Kafka topic and writes to a file using a Sink Connector. The file is stored on a persistent volume attached to the Kafka connect pod.
2. Kafka backup (optional) - back up the files created by Kafka connect to backup storage


**Backup content:**

Kafka topics written to file by Kafka connect to a directory. New file is created every month to prevent the file size grow indefinitely.

**Backup target:**

 Kafka backup uses NFS volume as a backup target storage. The NFS volume is mounted in the pod, and the mounted volume content is encrypted using encfs

    SNAP_PATH="/mnt/backup"
    SNAP_PATH_ENC="/mnt/backup_nfs_enc"
    cat /etc/encrypt-key/password | encfs $SNAP_PATH_ENC $SNAP_PATH --standard -S

The encryption password is stored in kubernetes secret and used when the filesystem is mounted.

**Backup tools:**

rsnapshot is used to back up the files. rsnapshot uses rsync to transfer the files. A file is backed up to a snapshot folder and then rotated using filesystem hard links to maintain desired number of versions. If a file has changed a new rsync copy is created and existing hardlinks are rotated. If a file changes every day, one copy for each day is stored up to the desired retention value.
If a file has not been updated for specified period, it is compressed to save disk space.

**File retention**

For files that have not been modified for more than ( retention * days ), one copy is kept forever. For currently used files, a daily copy of the file is kept for ( retention * days) .


**Sink connector configuration**

    name=local-file-sink
    connector.class=FileStreamSink
    tasks.max=1
    file=/opt/bitnami/kafka/filesink/kafka.sink.txt
    topics=connect1


**Kafka connect configuration**

    key.converter=org.apache.kafka.connect.storage.StringConverter
    value.converter=org.apache.kafka.connect.storage.StringConverter
    key.converter.schemas.enable=false
    value.converter.schemas.enable=false
    offset.storage.file.filename=/tmp/connect.offsets
    offset.flush.interval.ms=10000

**Installation**

**Values**

    image:
      name: icgcargo/kafka-connect:latest
    serviceAccount:
      create: true
      name: kafka-connect
    kafkaSvcNamespace: "kafka-namespace"
    kafkaSvcName: "kafka-headless"
    replicaCount: 1

**Persistent volume size**

    storage:
      size: 20Gi

**Topic to backup**

    topic: mytopic

**Sink name, this is used to identify the consumer group**

    sinkName: local-file-sink-backup

**This value is used to set up frequency of backups, the connect process is terminated and backups sripts starts to backup to NFS volume  **

    restartTimeout: "23h"




## Restore kafka topic from backup


## Overview

The following steps can be executed from kafka-connect pod in kube-backup namespace. Kafka commands are also available from Kafka application pods, after the restore, to reset the topic offset, the kafka connect pod needs to be stopped.

- **Stop kafka activity**

- Move current filesink files to a new directory as they will be overwritten once the kafka Connect resumes after restore. The new snapshot directory will be used to restore the data from

      mkdir snapshot
      mv connect1-sink29-202* snapshot


- **Delete the topic**

      kafka-topics.sh --zookeeper kafka-zookeeper-headless:2181 --delete --topic connect1

  **Check the topic**

      kafka-topics.sh --zookeeper kafka-zookeeper-headless:2181 --list

- **Create new topic**
  (in RDPC the topics are created by workflow relay)

      kafka-topics.sh --create --zookeeper kafka-zookeeper:2181 --topic connect1 --replication-factor 3 --partitions 4

- **Restore data from file to kafka topic**

      sh /opt/bitnami/kafka/filesink/restore.sh restore_topic kafka_server "restore_files"  "restore_from_time"

    **restore_topic**: destination topic to restore to

    **kafka_server**: kafka server"

    **restore_files**: path to the files to restore from, example "/opt/bitnami/kafka/filesink/connect*.sink" - quoted string

    **restore_from_time**: timestamp to restore from, example "2021-01-19T15:57" - quoted string

  **Example**

      sh /opt/bitnami/kafka/filesink/restore.sh connect1 kafka "/opt/bitnami/kafka/filesink/snapshot/connect*.sink"  "2021-01-19T15:57"

    The script will prompt for confirmation before proceeding.


- **Check the topic**

  The topic should now have restored data

      kafka-console-consumer.sh --bootstrap-server kafka:9092 --from-beginning  --topic connect1

- **Stop Kafka Connect**

      kubectl scale deployment kafka-connect-file --replicas 0


- **Reset consumer group id for Kafka Connect**

  Run the following from a kafka pod since connect pod has just been terminated!!

      kafka-consumer-groups.sh --bootstrap-server kafka:9092 --group connect-sink29 --describe
      kafka-consumer-groups.sh --bootstrap-server kafka:9092 --group connect-sink29 --reset-offsets --to-earliest --topic connect1 --execute

- **Restart Kafka Connect**

      kubectl scale deployment kafka-connect-file --replicas 1


- **Restart kafka activity**

- **Clean up**

  Delete the snapshot directory, if no longer needed. Verify that kafka connect works, by validating the filesink files in /opt/bitnami/kafka/filesink/ directory.
