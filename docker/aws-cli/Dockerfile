FROM bitnami/aws-cli:latest
LABEL org.icgc-argo.aws-cli.version=1.0.0
USER root
RUN apt-get update && apt-get install -y \
    gocryptfs \
    fuse \
    rsnapshot \
    && rm -rf /var/lib/apt/lists/*
RUN addgroup --system --gid 1001 kube-backup \
    && adduser --system --uid 1001 --gid 1001 kube-backup
RUN mkdir /mnt/backup \
    && chown kube-backup /mnt/backup \
    && mkdir /run/backup \
    && chown kube-backup /run/backup \
    && chown -R kube-backup /opt/bitnami
USER 1001
