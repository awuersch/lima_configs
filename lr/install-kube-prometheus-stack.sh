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

# set up kube-prometheus-stack

# kube-prometheus-stack helm chart version
KPS_VERSION=56.13.1

helm repo --kube-context $KUBE_CONTEXT add \
  prometheus-community \
  https://prometheus-community.github.io/helm-charts
helm repo update --kube-context $KUBE_CONTEXT prometheus-community
helm upgrade --install \
  prom-kube-stack prometheus-community/kube-prometheus-stack \
  --kube-context $KUBE_CONTEXT \
  --version $KPS_VERSION \
  --namespace monitoring --create-namespace
