#!/usr/bin/env bash
set -euf -o pipefail

export LIMA_INSTANCE=bc1
mkdir -p home

# source funcs
. ./Makefile.funcs

# main
create
config-network-end-to-end
# kind-delete-all
kind-create 1 1-istio
kind-create 2 2-gloo-edge
kind-create 3 3-gloo-mesh-mgmt
kind-create 4 4-gloo-mesh-cluster1
kind-create 5 5-gloo-mesh-cluster2
kind-list
# test
# clean-test
