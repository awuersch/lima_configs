#! /usr/bin/env bash
set -euf -o pipefail

# set up rawfiles for openebs

# name of cluster
CLUSTER=1-cilium

# how many gigabytes for each external storage instance
MAX_SIZE_GIGABYTES=30

# directory on mac of external storage
VOLUME_DIR=~/workspace/volumes

# basename of image file
IMG=ext4fs.img

# path in node to external storage mount point
RAWFILE_DIR=/var/csi/rawfile

# fs type of external storage
FSTYPE=ext4

# path in node to external storage data for loop device
REMOTE_IMG=${RAWFILE_DIR}/${IMG}

# define a script to run on a node, to set up external storage
cat > /tmp/script <<EOF
#! /bin/bash
set -euf -o pipefail
LOOPDEV=\$(losetup -fP --show ${REMOTE_IMG})
mount \${LOOPDEV} ${RAWFILE_DIR}
df ${RAWFILE_DIR}
EOF

for suffix in control-plane worker worker2 worker3
do
  set -x
  node=$CLUSTER-${suffix}
  f=${VOLUME_DIR}/kind-${suffix}/${IMG}
  if [[ ! -f ${f} ]]; then
    # create a local file whose size will be the max size of external storage for a node
    dd if=/dev/zero of=${f} bs=1G count=0 seek=${MAX_SIZE_GIGABYTES}
    # put an ${FSTYPE} file system on the file
    docker exec ${node} bash -c "mkfs.${FSTYPE} ${REMOTE_IMG}"
  fi
  # copy script to node
  docker cp /tmp/script ${node}:script.sh
  # run script on node
  docker exec ${node} bash -c "chown root /script.sh; chmod +x /script.sh; /script.sh"
  set +x
done
