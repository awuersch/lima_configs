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

CHARTS_PATH=helm-charts
CHART_DOMAIN=grafana.github.io
CHART_URL=https://$CHART_DOMAIN/$CHARTS_PATH
CHART_REPO=grafana
CHART_NS=loki

helm repo --kube-context $KUBE_CONTEXT add $CHART_REPO $CHART_URL
helm repo update --kube-context $KUBE_CONTEXT $CHART_REPO
for CHART_NAME in loki promtail; do
  helm upgrade --install \
    $CHART_NAME $CHART_REPO/$CHART_NAME \
    --kube-context $KUBE_CONTEXT \
    --namespace $CHART_NS --create-namespace \
    --set config.logFormat=json 
  helm install \
    $CHART_NAME $CHART_REPO/$CHART_NAME \
    --kube-context $KUBE_CONTEXT \
    --namespace $CHART_NS --create-namespace \
    --set config.logFormat=json \
    --dry-run > ${CHART_NAME}-dry-run.yaml
done
