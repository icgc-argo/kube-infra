FROM python:3.9.15

LABEL org.icgc-argo.python-kubespray.version=1.0.0

# ADD https://releases.hashicorp.com/vault/1.4.1/vault_1.4.1_linux_amd64.zip /tmp/

USER root

RUN apt-get update; \
    apt install git; \
    git clone https://github.com/kubernetes-sigs/kubespray.git; \
    cd kubespray; \
    git checkout v2.17.1; \
    pip3 install -r requirements.txt; \
    useradd -u 1001 kubespray

USER 1001
