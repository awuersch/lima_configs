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

# set up kyverno

# kyverno helm chart version
KYVERNO_NAME=kyverno
KYVERNO_NS=kyverno

helm repo --kube-context $KUBE_CONTEXT add \
  kyverno \
  https://kyverno.github.io/kyverno
helm repo update --kube-context $KUBE_CONTEXT $KYVERNO_NAME
helm install \
  $KYVERNO_NAME kyverno/kyverno \
  --kube-context $KUBE_CONTEXT \
  --namespace $KYVERNO_NS --create-namespace \
  --dry-run > kyverno-dry-run.yaml
helm upgrade --install \
  $KYVERNO_NAME kyverno/kyverno \
  --kube-context $KUBE_CONTEXT \
  --namespace $KYVERNO_NS --create-namespace
