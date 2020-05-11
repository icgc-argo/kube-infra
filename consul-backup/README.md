
## consul-backup

Backup etcd data to a persistent volume claim. It is NFS for now and create manually.
Etcd client creates snapshot and saves locally as encrypted file.



```
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-1
  labels:
    type: nfs-test
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
  name: nfs-1
  labels:
    type: nfs-test
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ""
  resources:
    requests:
      storage: 500Gi
```


## Install the chart
`
helm upgrade -i consul-backup consul-backup --set encryptPassword="my_secure_password"
`

## Values

Etcd client use certificates to authenticate. Run on a master node to mount the certs.

`
nodeSelector:
  kubernetes.io/hostname: "gammaray-k8s-master-0"
`

Job schedule  (cron)

`
schedule:  "55 */6 * * *"
`

Set password when installing the chart, the password is stored in secret

`
encryptPassword: ""
`

NFS export UID

`
nfsUserID: "1000"
`

Volume claim name

`
targetPvcName: nfs-1
`



