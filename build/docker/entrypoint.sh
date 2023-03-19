#!/usr/bin/env sh

set -e

if [ ! -f /etc/nsd/nsd_server.pem ]; then
  nsd-control-setup
fi

if [ ! -d /var/run/nsd ]; then
  mkdir -p /var/run/nsd
fi

# change owner and group
chown -R nsd:nsd /usr/local/etc/nsd /usr/local/etc/nsd/zones /usr/local/var/db/nsd /var/run/nsd

$@

tail -f /dev/null
