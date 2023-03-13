#!/usr/bin/env bash
set -euf -o pipefail

function errout {
  >&2 echo "usage: $0 lima-instance"
  exit 1
}

(($#==1)) || errout

export LIMA_INSTANCE=$1

. ./source-env.sh

function image-loaded-check { # image-tag
  local tag="$1"
  docker image ls --format '{{.Repository}}:{{.Tag}}' | { grep "$tag" || true; } | wc -l | tr -d " "
}

NAME=${LIMA_INSTANCE}
mkdir $LIMA_HOST_TMP_DIR $LIMA_HOST_DATA_DIR

# start vm
limactl start ./lima/$NAME.yaml --tty=false --name $NAME

echo "Creating the 'kind' docker network, type bridge"
docker network create \
    -d=bridge \
    --scope=local \
    --attachable=false \
    --gateway=172.18.0.1 \
    --ingress=false \
    --internal=false \
    --subnet=172.18.0.0/16 \
    -o "com.docker.network.bridge.enable_ip_masquerade"="true" \
    -o "com.docker.network.driver.mtu"="1500" kind || true
