#!/usr/bin/env bash

set -euf -o pipefail

limactl shell default-gw sudo cat /var/log/squid/access.log
