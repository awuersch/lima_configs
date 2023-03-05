#!/usr/bin/env bash
set -euf -o pipefail

function errout {
  >&2 echo "usage: $0 lima-instance cluster-name"
  exit 1
}

(($#==2)) || errout

export LIMA_INSTANCE=$1; shift
CLUSTER=$1; shift

. ./source-env.sh

# start kubernetes
CLUSTER_CONFIG=./lima/kind-${CLUSTER}.yaml
kind create cluster --config=${CLUSTER_CONFIG} --image kindest/node:${KIND_NODE_VERSION} --name $CLUSTER --retain

KUBE_CONTEXT="kind-$CLUSTER"

# taint nodes
kubectl --context $KUBE_CONTEXT taint nodes ${CLUSTER}-worker node.cilium.io/agent-not-ready=true:NoSchedule
kubectl --context $KUBE_CONTEXT taint nodes ${CLUSTER}-worker2 node.cilium.io/agent-not-ready=true:NoSchedule
kubectl --context $KUBE_CONTEXT taint nodes ${CLUSTER}-worker3 node.cilium.io/agent-not-ready=true:NoSchedule

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
  kind load docker-image $img --name $CLUSTER
done

# helm setup
helm repo --kube-context $KUBE_CONTEXT add cilium https://helm.cilium.io/

# we assume here the cluster name is "n-NAME" where "n" is a number
# cilium install
helm upgrade --install \
  cilium cilium/cilium \
  --kube-context $KUBE_CONTEXT \
  --version 1.13.0 \
  --namespace kube-system \
  --values - <<EOF
kubeProxyReplacement: strict
k8sServiceHost: ${CLUSTER}-control-plane
k8sServicePort: 6443
ipv4NativeRoutingCIDR: 10.0.0.0/9
autoDirectNodeRoutes: true
tunnel: disabled
cluster:
  name: $CLUSTER
  id: "${CLUSTER%%-*}"
ingressController:
  enabled: true
  loadBalancerMode: dedicated
hostServices:
  enabled: true
socketLB:
  enabled: true
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
cilium --context $KUBE_CONTEXT status --wait
