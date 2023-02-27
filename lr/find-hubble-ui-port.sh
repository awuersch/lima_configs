#!/usr/bin/env bash
set -euf -o pipefail

# find port of hubble-ui

# jq '.items[] | select(.kind=="Pod") | .spec.containers[] | select(.name=="frontend") | .ports[] | select(.protocol=="http")'

kind=Pod
container=frontend
name=http
protocol=TCP
frontend=".items[] | select(.kind==\"$kind\") | .spec.containers[] | select(.name==\"$container\")"
rest="| .ports[] | select(.name==\"$name\" and .protocol==\"$protocol\") | .containerPort"

context=kind-1-cilium
namespace=kube-system
selector="k8s-app==hubble-ui"
kubectl --context $context get pod --namespace $namespace --selector $selector --output json | jq "$frontend $rest"
