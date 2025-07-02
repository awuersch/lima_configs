#!/usr/bin/env bash

set -euf -o pipefail

# ./delete_containers.sh

rm -rf lima_net
./generate_yamls.sh
echo "start containers .. this can take time"
./start_containers.sh > /dev/null 2>&1
echo "test routing without squid"
./test_routing.sh
./setup_gw.sh
./stop_squid.sh
./start_squid.sh
sleep 1
./status_squid.sh
echo "test routing with squid"
./test_routing.sh
echo "show logs"
./logs_squid.sh
