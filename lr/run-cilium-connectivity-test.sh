#!/usr/bin/env bash
set -euf -o pipefail

# tunnel hubble-relay-lb to localhost:4245 before running

cilium --context kind-1-cilium connectivity test 2>&1 | tee kind-1-cilium-cilium-connectivity-test.out
