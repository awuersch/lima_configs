#!/usr/bin/env bash

set -euf -o pipefail

apt update
apt upgrade -y
apt install inetutils-traceroute
