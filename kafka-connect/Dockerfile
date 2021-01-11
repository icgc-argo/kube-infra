FROM bitnami/kafka:latest
USER root
RUN apt-get update && apt-get install -y \
    encfs \
    rsnapshot \
    && rm -rf /var/lib/apt/lists/*
RUN adduser --uid 1001 kafka --system
RUN mkdir /mnt/backup
RUN chown kafka /mnt/backup
RUN mkdir /run/backup
RUN chown kafka /run/backup
USER 1001
CMD /opt/bitnami/kafka/bin/connect-standalone.sh /opt/bitnami/kafka/custConfig/connect-standalone.properties /opt/bitnami/kafka/custConfig/connect-file-sink.properties
