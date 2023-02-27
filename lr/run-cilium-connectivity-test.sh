#!/usr/bin/env bash
set -euf -o pipefail

# tunnel hubble-relay-ui to localhost:4245 before running

# export HUBBLE_SYSTEM="localhost:4245"
cilium connectivity test 2>&1 | tee cilium-connectivity-test.out
