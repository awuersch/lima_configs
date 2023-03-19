#!/usr/bin/env bash
set -euf -o pipefail

# start dns in lima instance

export LIMA_INSTANCE=lr0
. ./source-env.sh

VOLUME_DIR=/opt/lima/volumes/nsd

docker run \
  -d \
  --network kind \
  -v ${VOLUME_DIR}/nsd.conf:/etc/nsd/nsd.conf \
  -v ${VOLUME_DIR}/zones:/etc/nsd/zones \
  -v ${VOLUME_DIR}/nsd.conf:/usr/local/etc/nsd/nsd.conf:rw \
  -v ${VOLUME_DIR}/zones:/usr/local/etc/nsd/zones:rw \
  --name nsd \
  rg1.tony.wuersch.name:443/arm64v8/nsd:4.6.1

# -v ${VOLUME_DIR}/nsd.conf:/usr/local/etc/nsd/nsd.conf \
# -v ${VOLUME_DIR}/zones:/usr/local/etc/nsd/zones \
