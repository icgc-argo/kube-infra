FROM bitnami/kafka:latest
CMD /opt/bitnami/kafka/bin/connect-standalone.sh /opt/bitnami/kafka/custConfig/connect-standalone.properties /opt/bitnami/kafka/custConfig/connect-file-sink.properties
RUN apt-get update && apt-get install -y \
    rsync \
 && rm -rf /var/lib/apt/lists/*
