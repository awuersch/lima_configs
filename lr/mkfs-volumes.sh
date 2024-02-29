#! /usr/bin/env bash
set -euf -o pipefail

# this should be run inside an lr0 VM

# directory on mac of external storage
VOLUME_DIR=/volumes

# basename of image file
IMG=ext4fs.img

# fs type of external storage
FSTYPE=ext4

for suffix in control-plane worker worker2 worker3
do
  mkfs.${FSTYPE} ${VOLUME_DIR}/kind-${suffix}/$IMG
done
