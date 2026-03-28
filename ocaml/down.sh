#! /usr/bin/env bash
set -euf -o pipefail

function usage { # containername
  >&2 echo "usage: $0 containername"
  exit 1
}

(($#==0)) && usage
NAME=$1; shift

nerdctl stop $NAME
nerdctl rm $NAME
