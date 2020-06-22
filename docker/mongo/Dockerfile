FROM bitnami/mongodb:4.0.14-debian-9-r0

ADD https://releases.hashicorp.com/vault/1.4.1/vault_1.4.1_linux_amd64.zip /tmp/

USER root

RUN apt-get update; \
    apt-get install unzip jq -y; \
    unzip /tmp/vault_1.4.1_linux_amd64.zip -d /usr/local/bin/; \
    apt-get remove -y unzip;

USER 1001
