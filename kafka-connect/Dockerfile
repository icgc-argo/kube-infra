FROM bitnami/kafka:latest
USER root
RUN apt-get update && apt-get install -y \
    encfs \
    rsnapshot \
    && rm -rf /var/lib/apt/lists/*
RUN adduser --uid 1001 kafka --system
RUN usermod -G root kafka
USER kafka
CMD /opt/bitnami/kafka/bin/connect-standalone.sh /opt/bitnami/kafka/custConfig/connect-standalone.properties /opt/bitnami/kafka/custConfig/connect-file-sink.properties
