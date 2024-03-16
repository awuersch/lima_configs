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

# set up loki and promtail

CHART_PATH=grafana
CHART_DOMAIN=grafana.github.io
CHART_URL=https://$CHART_DOMAIN/$CHART_PATH
CHART_REPO=grafana
CHART_NAME=loki
CHART_NS=loki

helm repo --kube-context $KUBE_CONTEXT add $CHART_REPO $CHART_URL
helm repo update --kube-context $KUBE_CONTEXT $CHART_REPO
for HELM_NAME in loki promtail; do
  helm upgrade --install \
    $HELM_NAME $CHART_REPO/$CHART_NAME \
    --kube-context $KUBE_CONTEXT \
    --namespace $CHART_NS --create-namespace
  helm install \
    $HELM_NAME $CHART_REPO/$CHART_NAME \
    --kube-context $KUBE_CONTEXT \
    --namespace $CHART_NS --create-namespace \
    --dry-run > ${HELM_NAME}-dry-run.yaml
done
