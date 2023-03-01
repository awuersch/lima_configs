#!/usr/bin/env bash
set -euf -o pipefail

function errout {
  >&2 echo "usage: $0 lima-instance cluster"
  exit 1
}

(($#==2)) || errout

export LIMA_INSTANCE=$1; shift
CLUSTER=$1; shift

. ./source-env.sh

KUBE_CONTEXT=kind-$CLUSTER

echo "installing metallb in cluster $CLUSTER of lima VM $LIMA_INSTANCE"
echo ""
echo "creating namespace metallb-system"
kubectl --context $KUBE_CONTEXT apply -f metallb/namespace.yaml || true

echo "installing metallb with helm"
helm upgrade --install --kube-context $KUBE_CONTEXT --namespace metallb-system metallb ./helm-metallb/metallb

# wait till all pods running
echo ""
echo "waiting for all pods running"
sleep 5

while true; do
  status="$(kubectl --context $KUBE_CONTEXT get pods --namespace metallb-system --output json |\
            jq -r '.items[] | .status.containerStatuses[].state | keys[]' |\
            uniq)"
  if [[ "$status" == "running" ]]; then
    break
  else
    echo "not all pods are running yet"
    sleep 5
  fi
done

LIMA_INSTANCE_NIBBLE_PARAM="${CLUSTER%%-*}"

# set third nibble to 255 minus param
((THIRD_NIBBLE=255-LIMA_INSTANCE_NIBBLE_PARAM)) || true

KIND_NET_CIDR=$(docker network inspect kind -f '{{(index .IPAM.Config 0).Subnet}}')
METALLB_IP_START=$(echo ${KIND_NET_CIDR} | sed "s@0.0/16@${THIRD_NIBBLE}.200@")
METALLB_IP_END=$(echo ${KIND_NET_CIDR} | sed "s@0.0/16@${THIRD_NIBBLE}.250@")
METALLB_IP_RANGE="${METALLB_IP_START}-${METALLB_IP_END}"

echo ""
echo "adding IPv4 address range and L2 Advertisement CRDs"
echo "IPv4 address range will be $METALLB_IP_RANGE"

cat > metallb/addresses.yaml <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default
  namespace: metallb-system
spec:
  addresses:
  - ${METALLB_IP_RANGE}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
EOF

kubectl --context $KUBE_CONTEXT apply -f metallb/addresses.yaml
