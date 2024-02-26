#! /usr/bin/env bash
set -euf -o pipefail

function errout { 
  >&2 echo "usage: $0 lima-instance cluster-name"
  exit 1
}

(($#==2)) || errout

export LIMA_INSTANCE=$1; shift
CLUSTER=$1; shift

. ./source-env.sh

KUBE_CONTEXT=kind-$CLUSTER

# set up rawfiles for openebs

# basename of image file
IMG=ext4fs.img

# path in node to external storage mount point
RAWFILE_DIR=/var/csi/rawfile

RAWFILE_IMG=${RAWFILE_DIR}/$IMG

# define a script to run on a node, to set up external storage
cat > /tmp/script <<EOF
#! /bin/bash
set -euf -o pipefail
LOOPDEV=\$(losetup -fP --show ${RAWFILE_IMG})
mount \${LOOPDEV} ${RAWFILE_DIR}
df ${RAWFILE_DIR}
EOF

# mount rawfiles

for node in $(kind get nodes -n $CLUSTER)
do
  # copy script to node
  docker cp /tmp/script ${node}:script.sh
  # run script on node
  docker exec ${node} bash -c "chown root /script.sh; chmod +x /script.sh; /script.sh"
  # remove script
  docker exec ${node} bash -c "rm /script.sh"
done

# set up kube-prometheus-stack

helm repo --kube-context $KUBE_CONTEXT add \
  prometheus-community \
  https://prometheus-community.github.io/helm-charts
helm repo update --kube-context $KUBE_CONTEXT
kubectl create --context $KUBE_CONTEXT namespace prometheus || true
helm install \
  --kube-context $KUBE_CONTEXT \
  --namespace prometheus \
  --generate-name prometheus-community/kube-prometheus-stack

# set up openebs

OPENEBS_GITHUB_DIR=~/workspace/src/git/github.com/openebs
mkdir -p $OPENEBS_GITHUB_DIR
cd $OPENEBS_GITHUB_DIR
[[ -d rawfile-localpv ]] || {
  git clone https://github.com/openebs/rawfile-localpv.git
}
cd rawfile-localpv
git fetch -a
git pull
helm install -n kube-system rawfile-csi ./deploy/charts/rawfile-csi/

# create a StorageClass with desired options

kubectl apply --context $KUBE_CONTEXT -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-device
provisioner: rawfile.csi.openebs.io
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF

# make the new StorageClass the default storage class

kubectl patch storageclass standard -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

kubectl patch storageclass local-device -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# delete the old storage class

kubectl delete storageclass standard

# see https://openebs.io/docs/user-guides/localpv-device for examples of use.
