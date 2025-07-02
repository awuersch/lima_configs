#!/usr/bin/env bash

set -euf -o pipefail

cd lima_net

# Start instances
limactl start ./default-gw.yaml --name=default-gw --yes
limactl start ./routed-client.yaml --name=routed-client --yes

echo "✅ Lima instances launched and network routing configured."
