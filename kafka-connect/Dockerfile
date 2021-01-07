FROM bitnami/kafka:latest
USER root
RUN apt-get update && apt-get install -y \
    rsync \
    encfs \
    rsnapshot \
    && rm -rf /var/lib/apt/lists/*
CMD /opt/bitnami/kafka/bin/connect-standalone.sh /opt/bitnami/kafka/custConfig/connect-standalone.properties /opt/bitnami/kafka/custConfig/connect-file-sink.properties
