#!/usr/bin/env bash

set -euf -o pipefail

mkdir -p /etc/squid/ssl /var/lib/squid
#
cd /etc/squid/ssl
openssl genrsa \
  -out squid.key \
  4096
openssl req \
  -new \
  -key squid.key \
  -out squid.csr \
  -subj "/C=XX/ST=XX/L=squid/O=squid/CN=squid-proxy" \
  -addext "subjectAltName = DNS:default-gw"
openssl x509 \
  -req \
  -days 3650 \
  -in squid.csr \
  -signkey squid.key \
  -out squid.crt
#
rm -rf /var/lib/squid/ssl_db
/usr/lib/squid/security_file_certgen \
  -c \
  -s /var/lib/squid/ssl_db \
  -M 20MB
#
rm -f /var/lib/squid/access.log
touch /var/lib/squid/access.log
chown -R \
  proxy:proxy \
  /var/lib/squid
