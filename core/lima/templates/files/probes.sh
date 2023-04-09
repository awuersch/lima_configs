#!/bin/bash
set -eux -o pipefail
if ! timeout 30s bash -c "until command -v docker >/dev/null 2>&1; do sleep 3; done"; then
  echo >&2 "docker is not installed yet"
  exit 1
fi
if ! timeout 30s bash -c "until pgrep dockerd; do sleep 3; done"; then
  echo >&2 "dockerd is not running"
  exit 1
fi
