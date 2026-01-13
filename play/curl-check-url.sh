#! /usr/bin/env bash
set -euf -o pipefail

function usage { # url
  >&2 echo "usage: $0 url"
  exit 1
}

(($#==0)) && usage
URL="$1"; shift

# return 0 if URL is found
curl --output /dev/null --silent --head --fail "$URL"
