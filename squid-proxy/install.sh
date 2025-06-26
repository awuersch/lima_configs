#!/usr/bin/env bash

set -xv
set -euo pipefail

# Proxy Variables.

export PROXY_PORT=${PROXY_PORT:-3128}
export PROXY_IMAGE=${PROXY_IMAGE:-"localhost:5000/squid-proxy:latest"}
export PROXY_NAME=${PROXY_NAME:-"squid-proxy"}
export PROXY_TLS_MODE=${PROXY_TLS_MODE:-"tls"}

# Knowing Current Path to create required directories.
BASE_DIR=$(realpath $(dirname "$0"))

# Initializing required directories.

CERTS_DIR="$BASE_DIR/certs"
PROXY_DATA_DIR="$BASE_DIR/data-proxy"
LOG_DIR="$BASE_DIR/logs"

# Creating required directories.

mkdir -p "$CERTS_DIR"
mkdir -p "$PROXY_DATA_DIR"
mkdir -p "$LOG_DIR"

########
# Create certs.

cd "$CERTS_DIR"

# Create server cert.
openssl genrsa -out server.key 2048
openssl req -x509 -new \
    -subj "/C=US/CN=squid-proxy" \
    -addext "subjectAltName = DNS:squid-proxy,DNS:host.docker.internal" \
    -key server.key -out server.crt

# Create client cert - It requires only when TLS mode is MTLS(mutual TLS).
if [[ $PROXY_TLS_MODE == "mtls" ]]; then
    openssl genrsa -out client.key 2048
    openssl req -x509 -new \
        -subj '/C=US/CN=client' \
        -key client.key -out client.crt
fi

cd -

########
# Create container image.

sudo docker build -t "$PROXY_IMAGE" "$BASE_DIR"

cd "$PROXY_DATA_DIR"
# Copy Squid Conf based on TLS mode.
if [[ $PROXY_TLS_MODE == "mtls" ]]; then
    cp "$BASE_DIR/squid.mtls.conf" squid.conf
else
    cp "$BASE_DIR/squid.tls.conf" squid.conf
fi

install -m 644 "$CERTS_DIR/client.crt" client.crt
install -m 644 "$CERTS_DIR/server.crt" server.crt
install -m 600 "$CERTS_DIR/server.key" server.key

cd -

########
echo "Starting proxy container"
sudo docker run --rm \
    -v "$PROXY_DATA_DIR:/data:rw" \
    -p "$PROXY_PORT:3128" \
    --name "$PROXY_NAME" \
    "$PROXY_IMAGE" \
    bash -c "chown -R proxy:proxy /data && /usr/sbin/squid -N -f /data/squid.conf" \
    > "$LOG_DIR/proxy-log.txt" 2>&1 &

echo "Proxy at https://squid-proxy:$PROXY_PORT"

