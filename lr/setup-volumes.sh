#! /usr/bin/env bash
set -euf -o pipefail

# set up volumes for lima

# how many gigabytes for each external storage instance
MAX_SIZE_GIGABYTES=30

# directory on mac of external storage
VOLUME_DIR=~/workspace/volumes

# basename of image file
IMG=ext4fs.img

for suffix in control-plane worker worker2 worker3
do
  set -x
  d=${VOLUME_DIR}/kind-${suffix}
  mkdir -p $d
  f=$d/${IMG}
  if [[ ! -f ${f} ]]; then
    # create a local file whose size will be the max size of external storage for a node
    dd if=/dev/zero of=${f} bs=1G count=0 seek=${MAX_SIZE_GIGABYTES}
  fi
done
