FROM ubuntu:focal

ADD https://releases.hashicorp.com/vault/1.4.1/vault_1.4.1_linux_amd64.zip /tmp/
ADD https://releases.hashicorp.com/consul/1.8.0/consul_1.8.0_linux_amd64.zip /tmp

USER root

RUN apt-get update; \
    apt-get install unzip jq openssl curl etcd-client mongodb-clients postgresql-client -y; \
    unzip /tmp/vault_1.4.1_linux_amd64.zip -d /usr/local/bin/; \
    unzip /tmp/vault_1.4.1_linux_amd64.zip -d /usr/local/bin/; \
    apt-get remove -y unzip; \
    useradd -u 1001 backup-infra

USER 1001
