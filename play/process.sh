#!/usr/bin/env bash
set -euf -o pipefail

jsonnet -S toml.jsonnet | sed -n '/^        /p' | sed 's/^        //' > xx.libsonnet
jsonnet tolist.jsonnet | yq -P
