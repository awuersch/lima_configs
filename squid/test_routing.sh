#!/usr/bin/env bash

set -uf -o pipefail

URL1="https://github.com"
URL2="https://tony.wuersch.name/resume.txt"

limactl shell routed-client curl -I $URL1 > /dev/null 2>&1
r="$?"
if ((r==0)); then
  echo "$URL1 OK"
else
  echo "$URL1 not OK"
fi

limactl shell routed-client curl -I $URL2 > /dev/null 2>&1
r="$?"
if ((r==0)); then
  echo "$URL2 OK"
else
  echo "$URL2 not OK"
fi
