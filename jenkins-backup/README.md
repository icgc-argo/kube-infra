
## Overview

Backup jenkins configuration to a persistent NFS volume claim. This chart uses Thin backup (jenkins plugin) data that is saved to claim attached to jenkins pod.
The TB backup runs every day at set schedule and the jenkins backup cron job runs after the TB backup has been created.
TB backup NFS volume needs to be attached as a claim to `jenkins` pods in `jenkins` namespace and also to `jenkins-backup` pod in `kube-backup` namespace



```
---
  apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: kube-backup
    labels:
      type: kube-backup
  spec:
    capacity:
      storage: 500Gi
    accessModes:
      - ReadWriteMany
    nfs:
      server: x.x.x.x
      path: "/opt/nfs1"
---
  kind: PersistentVolumeClaim
  apiVersion: v1
  metadata:
    name: kube-backup
    labels:
      type: kube-backup
  spec:
    accessModes:
      - ReadWriteMany
    storageClassName: ""
    resources:
      requests:
        storage: 500Gi
```
```
---
  apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: jenkins-thin-backup
  spec:
    capacity:
      storage: 20Gi
    accessModes:
      - ReadWriteMany
    nfs:
      server: 10.10.0.30
      path: "/mnt/jenkins_thin"
---
  kind: PersistentVolumeClaim
  apiVersion: v1
  metadata:
    name: jenkins-thin-backup
  spec:
    accessModes:
      - ReadWriteMany
    storageClassName: ""
    resources:
      requests:
        storage: 20Gi
```






## Install the chart
`
helm upgrade -i jenkins-backup jenkins-backup --set encryptPassword="my_secure_password"
`

## Values

```
image:
  name: icgcargo/consul-backup:latest
  pullPolicy: IfNotPresent
imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""
serviceAccount:
  create: true
  name: jenkins-backup
podSecurityContext: {}
securityContext: {}
resources: {}
tolerations: []
affinity: {}
schedule:  "55 8 * * *"
encryptPassword: ""
nfsUserID: "1000"
targetPvcName: kube-backup
retention: "7"
deployEnv: "infra"
backupID: "jenkins"
thinBackupVolume: "jenkins-thin-backup"
thinBackupPath: "backup"
jenkinsSvcNamespace: "jenkins"
```


## Restore

Restore the backup to TB volume and then restore data in Jenkins Web UI



