#! /usr/bin/env bash
set -euf -o pipefail

docker build -t rg1.tony.wuersch.name:443/arm64v8/nsd:4.6.1 .
