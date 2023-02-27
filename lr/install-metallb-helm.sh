#!/usr/bin/env bash
set -euf -o pipefail

KUBE_CONTEXT=kind-1-cilium

kubectl --context $KUBE_CONTEXT apply -f metallb/namespace.yaml

KIND_NET_CIDR=$(docker network inspect kind -f '{{(index .IPAM.Config 0).Subnet}}')
METALLB_IP_START=$(echo ${KIND_NET_CIDR} | sed "s@0.0/16@255.200@")
METALLB_IP_END=$(echo ${KIND_NET_CIDR} | sed "s@0.0/16@255.250@")
METALLB_IP_RANGE="${METALLB_IP_START}-${METALLB_IP_END}"

helm upgrade --install --kube-context $KUBE_CONTEXT --namespace metallb-system metallb ./helm-metallb/metallb

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
