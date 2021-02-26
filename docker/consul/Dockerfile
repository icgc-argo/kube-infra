FROM alpine:3.9

LABEL org.icgc-argo.consul-backup.version=1.0.0

ENV CONSUL_VERSION=1.7.2
ENV HASHICORP_RELEASES=https://releases.hashicorp.com

RUN addgroup consul && \
    adduser -S -G consul consul

RUN apk add --no-cache ca-certificates curl dumb-init gnupg libcap openssl su-exec iputils jq libc6-compat
RUN set -eux && \
    gpg --keyserver pool.sks-keyservers.net --recv-keys 91A6E7F85D05C65630BEF18951852D87348FFC4C && \
    mkdir -p /tmp/build && \
    cd /tmp/build && \
    apkArch="$(apk --print-arch)" && \
    case "${apkArch}" in \
        aarch64) consulArch='arm64' ;; \
        armhf) consulArch='armhfv6' ;; \
        x86) consulArch='386' ;; \
        x86_64) consulArch='amd64' ;; \
        *) echo >&2 "error: unsupported architecture: ${apkArch} (see ${HASHICORP_RELEASES}/consul/${CONSUL_VERSION}/)" && exit 1 ;; \
    esac && \
    wget ${HASHICORP_RELEASES}/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_${consulArch}.zip && \
    wget ${HASHICORP_RELEASES}/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS && \
    wget ${HASHICORP_RELEASES}/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS.sig && \
    gpg --batch --verify consul_${CONSUL_VERSION}_SHA256SUMS.sig consul_${CONSUL_VERSION}_SHA256SUMS && \
    grep consul_${CONSUL_VERSION}_linux_${consulArch}.zip consul_${CONSUL_VERSION}_SHA256SUMS | sha256sum -c && \
    unzip -d /bin consul_${CONSUL_VERSION}_linux_${consulArch}.zip && \
    cd /tmp && \
    rm -rf /tmp/build && \
    gpgconf --kill all && \
    rm -rf /root/.gnupg && \
    consul version

RUN mkdir -p /consul/data && \
    mkdir -p /consul/config && \
    chown -R consul:consul /consul

RUN test -e /etc/nsswitch.conf || echo 'hosts: files dns' > /etc/nsswitch.conf

VOLUME /consul/data

CMD ["/bin/sh"]
