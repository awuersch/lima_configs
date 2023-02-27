#!/usr/bin/env bash
set -euf -o pipefail

# find lb address of hubble-ui

context=kind-1-cilium
namespace=kube-system
name=hubble-ui-lb
kubectl --context $context get svc --namespace $namespace --output json $name | jq -r .status.loadBalancer.ingress[0].ip
