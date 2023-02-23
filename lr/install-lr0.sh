#! /usr/bin/env bash
set -euf -o pipefail

# startup experimental bc2
. Makefile.funcs

# registry storage setup
NAME=lr0
mkdir /tmp/lima/$NAME /opt/lima/$NAME

# start vm
limactl start ./lima/$NAME.yaml --tty=false --name $NAME

# env variables
export \
  KUBECONFIG=~/workspace/vms/lima/bc/home/$NAME/.kube/config \
  DOCKER_HOST=unix:///Users/tony/workspace/vms/lima/bc/home/$NAME/docker.sock \
  LIMA_DATA_DIR=/opt/lima \
  CLUSTER_CONFIG_FILE=./lima/$NAME-kind.yaml

# get images
prepare-mac-host

# set up registries
registries

# start kubernetes
CLUSTER_NAME=1-cilium
kind create cluster --config=${CLUSTER_CONFIG_FILE} --image kindest/node:${KIND_NODE_VERSION} --name $CLUSTER_NAME --retain

kubectl config use-context kind-$CLUSTER_NAME

# image loads
# for img in \
#     quay.io/cilium/cilium:v1.13.0 \
#     quay.io/metallb/controller:v0.13.7 \
#     quay.io/metallb/speaker:v0.13.7
# do
#   # replace forward slashes and colon by hyphens
#   s=${img//\//-}
#   TAR=${LIMA_DATA_DIR}/${s/:/-}.tar
#   if [[ ! -f $TAR ]]; then
#     docker pull $img
#     docker save $img > $TAR
#   else
#     docker load < $TAR
#   fi
#   kind load docker-image $img --name $CLUSTER_NAME
# done

# helm setup
helm repo add cilium https://helm.cilium.io/

# cilium install
helm upgrade --install \
  cilium cilium/cilium \
  --version 1.13.0 \
  --namespace kube-system \
  --values - <<EOF
kubeProxyReplacement: strict
k8sServiceHost: kind-control-plane
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