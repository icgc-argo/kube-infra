FROM alpine:3.9

LABEL org.icgc-argo.jenkins-backup.version=1.0.0

RUN addgroup jenkins-backup && \
    adduser -S -G jenkins-backup jenkins-backup

RUN set -eux && \
    apk add --no-cache ca-certificates curl dumb-init gnupg libcap openssl su-exec iputils jq libc6-compat && \
    cd /tmp && \
    rm -rf /tmp/build && \
    rm -rf /root/.gnupg

RUN test -e /etc/nsswitch.conf || echo 'hosts: files dns' > /etc/nsswitch.conf

CMD ["/bin/sh"]
