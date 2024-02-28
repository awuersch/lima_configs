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

CXT=kind-$CLUSTER

# set up kube-prometheus-stack

# kube-prometheus-stack helm chart version
KPS_VERSION=56.13.1
KPS_NAME=prom-kube-stack

helm repo --kube-context $CXT add \
  prometheus-community \
  https://prometheus-community.github.io/helm-charts
helm repo update --kube-context $CXT prometheus-community
helm upgrade --install \
  $KPS_NAME prometheus-community/kube-prometheus-stack \
  --kube-context $CXT \
  --version $KPS_VERSION \
  --namespace monitoring --create-namespace

KPS_PREFIX=$KPS_NAME
for svc in grafana kube-prome-prometheus kube-prome-alertmanager
do
  kpssrc=$KPS_PREFIX-$svc

  kubectl expose svc/$kpssrc \
    --name $kpssrc-lb \
    --context $CXT \
    --namespace monitoring \
    --type LoadBalancer
done

# create tunnels to localhost ports
bash ./tunnel.sh 8090 $LIMA_INSTANCE $CXT $KPS_PREFIX-grafana-lb monitoring 80
bash ./tunnel.sh 9093 $LIMA_INSTANCE $CXT $KPS_PREFIX-kube-prome-alertmanager-lb monitoring 9093
bash ./tunnel.sh 9090 $LIMA_INSTANCE $CXT $KPS_PREFIX-kube-prome-prometheus-lb monitoring 9090
