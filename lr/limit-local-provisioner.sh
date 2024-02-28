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
TARGET_DIR=/var/local-path-provisioner

RAWFILE_DIR=/var/csi/rawfile
RAWFILE_IMG=${RAWFILE_DIR}/$IMG

# define a script to run on a node, to set up external storage
cat > /tmp/script <<EOF
#! /bin/bash
set -euf -o pipefail
LOOPDEV=\$(losetup -fP --show ${RAWFILE_IMG})
mount \${LOOPDEV} ${TARGET_DIR}
df ${TARGET_DIR}
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
