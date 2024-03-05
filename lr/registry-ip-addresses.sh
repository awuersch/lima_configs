#! /usr/bin/env bash
set -euf -o pipefail

# get registry ip addresses
for name in us-docker-pkg-dev k8sio gcrio quayio dockerio ghcrio; do
  echo -n "${name} "
  docker container inspect registry-${name} | jq -r '.[].NetworkSettings.Networks.kind.IPAddress'
done
