#! /usr/bin/env bash
set -euf -o pipefail

function errout {
  >&2 echo "usage: $0 lima-instance cluster-name"
  exit 1
}

(($#==2)) || errout

export LIMA_INSTANCE=$1; shift
CLUSTER=$1; shift

. ./source-env.sh

KUBE_CONTEXT=kind-$CLUSTER

# set up argo-cd

# argo-cd helm chart version
ARGOCD_VERSION=6.6.0
ARGOCD_NAME=argo
ARGOCD_NS=argocd

helm repo --kube-context $KUBE_CONTEXT add \
  argo \
  https://argoproj.github.io/argo-helm
helm repo update --kube-context $KUBE_CONTEXT $ARGOCD_NAME
helm upgrade --install \
  $ARGOCD_NAME argo/argo-cd \
  --kube-context $KUBE_CONTEXT \
  --version $ARGOCD_VERSION \
  --namespace $ARGOCD_NS --create-namespace \
  --set configs.params.server.insecure=true
helm install \
  $ARGOCD_NAME argo/argo-cd \
  --kube-context $KUBE_CONTEXT \
  --version $ARGOCD_VERSION \
  --namespace $ARGOCD_NS --create-namespace \
  --dry-run \
  --set configs.params.server.insecure=true > argocd-dry-run.yaml

# expose and tunnel argocd-dex-server

kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

DEX_SERVER_SVC_NAME=argo-argocd-dex-server
# DEX_SERVER_LB_NAME=${DEX_SERVER_SVC_NAME}-lb
# kubectl expose svc/$DEX_SERVER_SVC_NAME \
#   --name $DEX_SERVER_LB_NAME \
#   --context $KUBE_CONTEXT \
#   --namespace $ARGOCD_NS \
#   --target-port $DEX_SERVER_TARGET_PORT \
#   --type LoadBalancer
kubectl patch svc $DEX_SERVER_SVC_NAME -n $ARGOCD_NS -p '{"spec": {"type": "LoadBalancer"}}'

DEX_SERVER_TUNNEL_PORT=5556
bash ./tunnel.sh $DEX_SERVER_TUNNEL_PORT $LIMA_INSTANCE $KUBE_CONTEXT $DEX_SERVER_SVC_NAME $ARGOCD_NS

# expose and tunnel argocd-server

SERVER_SVC_NAME=argo-argocd-server
# SERVER_LB_NAME=${SERVER_SVC_NAME}-lb
# kubectl expose svc/$SERVER_SVC_NAME \
#   --name $SERVER_LB_NAME \
#   --context $KUBE_CONTEXT \
#   --namespace $ARGOCD_NS \
#   --target-port $SERVER_TARGET_PORT \
#   --type LoadBalancer
kubectl patch svc $SERVER_SVC_NAME -n $ARGOCD_NS -p '{"spec": {"type": "LoadBalancer"}}'

SERVER_TUNNEL_PORT=8082
bash ./tunnel.sh $SERVER_TUNNEL_PORT $LIMA_INSTANCE $KUBE_CONTEXT $SERVER_LB_NAME $ARGOCD_NS
