#!/usr/bin/env bash

set -euf -o pipefail

limactl shell --tty default-gw sudo service squid status
