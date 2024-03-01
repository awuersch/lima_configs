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
KPS_NS=monitoring

helm repo --kube-context $CXT add \
  prometheus-community \
  https://prometheus-community.github.io/helm-charts
helm repo update --kube-context $CXT prometheus-community
helm upgrade --install \
  $KPS_NAME prometheus-community/kube-prometheus-stack \
  --kube-context $CXT \
  --version $KPS_VERSION \
  --namespace $KPS_NS --create-namespace

# get target ports of prometheus apps
echo '{ name: "http-web" }' > args.libsonnet
kubectl get svc -n $KPS_NS > svcs.libsonnet
jsonnet target-ports.jsonnet > target-ports.tsv

# https://stackoverflow.com/questions/9736202/read-tab-separated-file-line-into-array/9736732#9736732
# while IFS=$'\t' read -r -a myArray
# do
#  echo "${myArray[0]}"
#  echo "${myArray[1]}"
#  echo "${myArray[2]}"
# done < myfile

# create lb svcs for apps

while IFS=$'\t' read -r -a tps
do
  svc="${tps[0]}"
  targetPort="${tps[1]}"
  app=${svc##*-}
  kubectl expose svc/$svc \
    --name $app-lb \
    --context $KUBE_CONTEXT \
    --namespace $KPS_NS \
    --target-port $targetPort \
    --type LoadBalancer
  bash ./tunnel.sh $targetPort $LIMA_INSTANCE $KUBE_CONTEXT $app-lb $KPS_NS
done < target-ports.tsv
