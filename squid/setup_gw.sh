#!/usr/bin/env bash

set -eu -o pipefail

# copy files
limactl cp ./gw_files/* default-gw:

# run default-gw
limactl shell default-gw sudo cp allowlist.txt squid.conf /etc/squid
limactl shell default-gw sudo ./setup_squid.sh
limactl shell default-gw sudo ./iptables.sh
