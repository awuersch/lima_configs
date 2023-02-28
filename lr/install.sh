#!/usr/bin/env bash
set -euf -o pipefail

function errout {
  >&2 echo "usage: $0 lima-instance"
  exit 1
}

(($#==1)) || errout

export LIMA_INSTANCE=$1

. ./env.sh

function prepare-mac-host { #
  # origin: bcollard ./macos-setup/05-prepare-mac-host.sh

  # docker work dir and cache dirs
  mkdir -p ${LIMA_HOST_DATA_DIR}

  # pull and save images
  for img in \
      distribution/distribution:2.8.1 \
      quay.io/metallb/controller:v0.13.7 \
      quay.io/metallb/speaker:v0.13.7
  do
    # replace forward slashes and colon by hyphens
    s=${img//\//-}
    TAR=${LIMA_DATA_DIR}/${s/:/-}.tar
    if [[ ! -f $TAR ]]; then
      docker pull $img
      docker save $img > $TAR
    fi
  done

  # the img-tar xform for the kindest/node image is different ...
  TAR="${LIMA_DATA_DIR}/kind-${KIND_NODE_VERSION}-image.tar"
  if [[ ! -f $TAR ]]; then
    img="kindest/node:${KIND_NODE_VERSION}"
    docker pull $img
    docker save $img > $TAR
  fi
}

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
  fi
  docker network connect kind $cache_name 2>/dev/null || true
}

function registries { #
  # origin: bcollard ./lima/17-docker-registries.sh

  # DOCKER IMAGE CACHES ("registry v2" or "distribution:2.8.1")
  registry_img_loaded=$(image-loaded-check "$REGISTRY_IMAGE_TAG")
  if [ ${registry_img_loaded} -ne 1 ]; then
    echo "Loading the ${REGISTRY_IMAGE_TAG} image into the VM..."
    docker load < ${LIMA_DATA_DIR}/distribution-distribution-2.8.1.tar
  fi

  # docker.io mirror
  cache_dir=${DOCKERIO_CACHE_DIR}
  cache_name=${DOCKERIO_CACHE_NAME}
  domain=registry-1.docker.io
  port=${DOCKERIO_CACHE_PORT}
  base_yml=dockerio-cache-config.yml
  setup_registry $cache_dir $cache_name $domain $port $base_yml

  # quay.io mirror
  cache_dir=${QUAYIO_CACHE_DIR}
  cache_name=${QUAYIO_CACHE_NAME}
  domain=quay.io
  port=${QUAYIO_CACHE_PORT}
  base_yml=quayio-cache-config.yml
  setup_registry $cache_dir $cache_name $domain $port $base_yml

  # gcr.io mirror
  cache_dir=${GCRIO_CACHE_DIR}
  cache_name=${GCRIO_CACHE_NAME}
  domain=gcr.io
  port=${GCRIO_CACHE_PORT}
  base_yml=grcio-cache-config.yml
  setup_registry $cache_dir $cache_name $domain $port $base_yml

  # us-docker.pkg.dev mirror
  cache_dir=${USDOCKERPKGDEV_CACHE_DIR}
  cache_name=${USDOCKERPKGDEV_CACHE_NAME}
  domain=us-docker.pkg.dev
  port=${USDOCKERPKGDEV_CACHE_PORT}
  base_yml=us-docker.pkg.dev-cache-config.yml
  setup_registry $cache_dir $cache_name $domain $port $base_yml
}

# registry storage setup
NAME=${LIMA_INSTANCE}
KIND_NAME="1-cilium"
mkdir $LIMA_HOST_TMP_DIR $LIMA_HOST_DATA_DIR

# start vm
limactl start ./lima/$NAME.yaml --tty=false --name $NAME

# env variables
export \
  KUBECONFIG=$KUBE_HOST_DIR/config \
  KUBECACHEDIR=$KUBE_HOST_DIR/cache \
  DOCKER_HOST=unix://$HOST_INSTANCE_HOME/docker.sock \
  CLUSTER_CONFIG_FILE=./lima/kind-${KIND_NAME}.yaml

# get images
prepare-mac-host

mkdir -p ${KIND_HOST_HOME_DIR}

# set up registries
registries

# start kubernetes
CLUSTER_NAME=1-cilium
kind create cluster --config=${CLUSTER_CONFIG_FILE} --image kindest/node:${KIND_NODE_VERSION} --name $CLUSTER_NAME --retain

KUBE_CONTEXT="kind-$CLUSTER_NAME"
kubectl config use-context $KUBE_CONTEXT

# taint nodes
kubectl taint nodes 1-cilium-worker node.cilium.io/agent-not-ready=true:NoSchedule
kubectl taint nodes 1-cilium-worker2 node.cilium.io/agent-not-ready=true:NoSchedule
kubectl taint nodes 1-cilium-worker3 node.cilium.io/agent-not-ready=true:NoSchedule

# image loads
for img in \
    quay.io/cilium/cilium:v1.13.0 \
    quay.io/metallb/controller:v0.13.7 \
    quay.io/metallb/speaker:v0.13.7
do
  # replace forward slashes and colon by hyphens
  s=${img//\//-}
  TAR=${LIMA_DATA_DIR}/${s/:/-}.tar
  if [[ ! -f $TAR ]]; then
    docker pull $img
    docker save $img > $TAR
  else
    docker load < $TAR
  fi
  kind load docker-image $img --name $CLUSTER_NAME
done

# helm setup
helm repo add cilium https://helm.cilium.io/

# cilium install
helm upgrade --install \
  cilium cilium/cilium \
  --kube-context $KUBE_CONTEXT \
  --version 1.13.0 \
  --namespace kube-system \
  --values - <<EOF
kubeProxyReplacement: strict
k8sServiceHost: ${KIND_NAME}-control-plane
k8sServicePort: 6443
hostServices:
  enabled: true
ingressController:
  enabled: true
  loadBalancerMode: dedicated
externalIPs:
  enabled: true
nodePort:
  enabled: true
hostPort:
  enabled: true
image:
  pullPolicy: IfNotPresent
ipam:
  mode: kubernetes
hubble:
  enabled: true
  relay:
    enabled: true
  ui:
    enabled: true
EOF

# wait for status up
cilium status --wait
