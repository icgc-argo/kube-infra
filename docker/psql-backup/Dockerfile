FROM  bitnami/postgresql:11.7.0-debian-10-r97

ADD https://releases.hashicorp.com/vault/1.4.1/vault_1.4.1_linux_amd64.zip /tmp/

USER root

RUN apt-get update; \
    apt-get install unzip jq -y; \
    unzip /tmp/vault_1.4.1_linux_amd64.zip -d /usr/local/bin/; \
    apt-get remove -y unzip;

USER 1001
