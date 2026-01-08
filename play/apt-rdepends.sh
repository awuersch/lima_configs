#! /usr/bin/env bash
set -euf -o pipefail

function usage { # package
  >&2 echo "usage: $0 package"
  exit 1
}

(($#==0)) && usage

PACKAGE=$1
apt-rdepends --show=depends $PACKAGE | grep -v '^ ' | grep -v $PACKAGE | sort -u
