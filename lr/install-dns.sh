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

function setup_registry { # cache_dir cache_name domain port base_yml
  local cache_dir=$1 cache_name=$2 domain=$3 port=$4 base_yml=$5
  local cache_running="$(docker inspect -f '{{.State.Running}}' "${cache_name}" 2>/dev/null || true)"
  if [ "${cache_running}" = "false" ]; then
    echo "Removing stopped container ${cache_name}"
    docker rm -f "${cache_name}" 2>/dev/null || true
  fi
  if [ -z "${cache_running}" -o "${cache_running}" = "false" ]; then
    echo "{ domain: \"${domain}\", port: $port }" > lima/templates/args.libsonnet
    jsonnet ./lima/templates/cache-config.jsonnet | yq -P > ${KIND_HOST_HOME_DIR}/$base_yml
    echo "Starting $domain mirror"
    docker run \
      -d --restart=always -v ${KIND_VM_HOME_DIR}/$base_yml:/etc/docker/registry/config.yml -p $port:$port \
      -v $cache_dir:/var/lib/registry --name "$cache_name" "${REGISTRY_IMAGE_TAG}"
    docker network connect kind $cache_name 2>/dev/null
  fi
}

NSD_IMAGE_TAG="rg1.tony.wuersch.name:443/arm64v8/nsd:4.6.1"

function dns { #
  # DOCKER IMAGE CACHES ("registry v2" or "distribution:2.8.2")
  registry_img_loaded=$(image-loaded-check "$NSD_IMAGE_TAG")
  if [ ${registry_img_loaded} -ne 1 ]; then
    echo "Loading the ${NSD_IMAGE_TAG} image into the VM..."
    docker load < ${LIMA_DATA_DIR}/rg1.tony.wuersch.name-arm64v8-nsd-4.6.1.tar
  fi
  docker run -v /workdir/volumes/nsd/zones:/etc/nsd/zones
}
