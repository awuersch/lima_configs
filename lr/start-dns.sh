#!/usr/bin/env bash
set -euf -o pipefail

# start dns in lima instance

export LIMA_INSTANCE=lr0
. ./source-env.sh

#  --user nsd:nsd \

docker run \
  -d \
  --network kind \
  --volume /opt/lima/volumes/nsd:/etc/nsd:rw \
  --name nsd \
  rg1.tony.wuersch.name:443/arm64v8/nsd:4.6.1
