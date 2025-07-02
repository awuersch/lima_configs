#!/usr/bin/env bash

set -euf -o pipefail

# stop and delete instances
for container in default-gw routed-client
do
  limactl stop $container
  limactl delete $container
done

echo "✅ Lima instances stopped and deleted"
