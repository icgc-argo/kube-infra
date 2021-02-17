FROM bitnami/kafka:latest
LABEL org.icgc-argo.kafka-connect.version=1.0.0
USER root
RUN apt-get update && apt-get install -y \
    gocryptfs \
    rsnapshot \
    && rm -rf /var/lib/apt/lists/*
RUN addgroup --gid 1001 kafka --system \
    adduser --uid 1001 -gid 1001 kafka --system
RUN mkdir /mnt/backup \
    chown kafka /mnt/backup \
    mkdir /run/backup \
    chown kafka /run/backup \
    chown -R kafka /opt/bitnami
USER 1001
CMD /opt/bitnami/kafka/bin/connect-standalone.sh /opt/bitnami/kafka/custConfig/connect-standalone.properties /opt/bitnami/kafka/custConfig/connect-file-sink.properties
