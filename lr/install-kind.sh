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

KUBE_CONTEXT=kind-${CLUSTER}

# start kubernetes
CLUSTER_CONFIG=./lima/kind-${CLUSTER}.yaml
kind create cluster --config=${CLUSTER_CONFIG} --image kindest/node:${KIND_NODE_VERSION} --name $CLUSTER --retain

# copy mirror registry specs with host.toml files
for node in $(kind get nodes -n $CLUSTER); do
   docker exec $node rm -rf /etc/contaienrd/certs.d
   docker cp ./containerd/certs.d $node:/etc/containerd
   docker exec $node chown -R root:root /etc/containerd/certs.d
done

KUBE_CONTEXT="kind-$CLUSTER"

# taint nodes
# kubectl --context $KUBE_CONTEXT taint nodes ${CLUSTER}-worker node.cilium.io/agent-not-ready=true:NoSchedule
# kubectl --context $KUBE_CONTEXT taint nodes ${CLUSTER}-worker2 node.cilium.io/agent-not-ready=true:NoSchedule
# kubectl --context $KUBE_CONTEXT taint nodes ${CLUSTER}-worker3 node.cilium.io/agent-not-ready=true:NoSchedule

# image loads
for img in \
    quay.io/cilium/cilium:v1.15.1
do
  # replace forward slashes and colon by hyphens
  s=${img//\//-}
  TAR=${LIMA_HOST_DATA_DIR}/${s/:/-}.tar
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
helm repo update --kube-context $KUBE_CONTEXT

# we assume here the cluster name is "n-NAME" where "n" is a number
# cilium install
helm upgrade --install \
  cilium cilium/cilium \
  --kube-context $KUBE_CONTEXT \
  --version 1.15.1 \
  --namespace kube-system \
  --set kubeProxyReplacement=true \
  --set socketLB.hostNamespaceOnly=true \
  --set k8sServiceHost=${CLUSTER}-control-plane \
  --set k8sServicePort=6443 \
  --set ipam.mode=kubernetes \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true

# wait for status up
cilium --context $KUBE_CONTEXT status --wait

# set up a Cilium IP pool

kubectl apply --context $KUBE_CONTEXT -f - <<EOF
apiVersion: "cilium.io/v2alpha1"
kind: CiliumLoadBalancerIPPool
metadata:
  name: "basic-pool"
spec:
  cidrs:
  - cidr: "172.18.254.0/24"
EOF

# install cilium L2 announcements

helm upgrade \
  cilium cilium/cilium \
  --kube-context $KUBE_CONTEXT \
  --version 1.15.1 \
  --namespace kube-system \
  --reuse-values \
  --set l2announcements.enabled=true \
  --set devices=eth0

# restart stuff

STDARGS="--context $KUBE_CONTEXT --namespace kube-system"

kubectl rollout restart $STDARGS deployment/cilium-operator
kubectl rollout restart $STDARGS ds/cilium

# create a policy to allow announcements

kubectl apply --context $KUBE_CONTEXT -f - <<EOF
apiVersion: "cilium.io/v2alpha1"
kind: CiliumL2AnnouncementPolicy
metadata:
  name: "basic-policy"
spec:
  interfaces:
  - eth0
  externalIPs: true
  loadBalancerIPs: true
EOF

SVC=hubble-ui
NS=kube-system
PORT=8081
# patch and tunnel to hubble-ui
# kubectl expose svc/$SVC \
#   --name ${SVC}-lb \
#   --context $KUBE_CONTEXT \
#   --namespace $NS \
#   --target-port $PORT \
#   --type LoadBalancer
kubectl patch svc $SVC -n $NS -p '{"spec": {"type": "LoadBalancer"}}'

# bash ./tunnel.sh $PORT $LIMA_INSTANCE $KUBE_CONTEXT ${SVC}-lb $NS
bash ./tunnel.sh $PORT $LIMA_INSTANCE $KUBE_CONTEXT $SVC $NS
