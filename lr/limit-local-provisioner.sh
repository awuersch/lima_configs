#! /usr/bin/env bash
set -euf -o pipefail

# mount rawfiles as loopdev local provisioners, to limit risk to host

function errout { 
  >&2 echo "usage: $0 lima-instance cluster-name"
  exit 1
}

(($#==2)) || errout

export LIMA_INSTANCE=$1; shift
CLUSTER=$1; shift

. ./source-env.sh

KUBE_CONTEXT=kind-$CLUSTER

# basename of image file
IMG=ext4fs.img

# path in node to external storage mount point
TARGET_DIR=/var/local-path-provisioner

RAWFILE_DIR=/var/csi/rawfile
RAWFILE_IMG=${RAWFILE_DIR}/$IMG

# define a script to run on a node, to set up external storage

cat > /tmp/script <<EOF
#! /bin/bash
set -euf -o pipefail
LOOPDEV=\$(losetup -fP --show ${RAWFILE_IMG})
mkdir -p $TARGET_DIR
mount \${LOOPDEV} ${TARGET_DIR}
df ${TARGET_DIR}
EOF

for node in $(kind get nodes -n $CLUSTER)
do
  # copy script to node
  docker cp /tmp/script ${node}:script.sh
  # run script on node
  docker exec ${node} bash -c "chown root /script.sh; chmod +x /script.sh; /script.sh"
  # remove script
  docker exec ${node} bash -c "rm /script.sh"
done

# update local-path storage class from Delete to Retain

kubectl delete storageclass standard
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
  name: standard
provisioner: rancher.io/local-path
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
EOF
