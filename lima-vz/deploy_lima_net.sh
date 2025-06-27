#!/bin/bash

set -e

mkdir -p lima_net
cd lima_net

# Create gateway instance config
cat > default-gw.yaml <<EOF
images:
  - location: "https://cloud-images.ubuntu.com/releases/plucky/release-20250424/ubuntu-25.04-server-cloudimg-amd64.img"
    arch: "x86_64"
    digest: "sha256:ee752a88573fc8347b4082657293da54a7ba301e3d83cc935fedb4ab6d7129e2"
  - location: "https://cloud-images.ubuntu.com/releases/plucky/release-20250424/ubuntu-25.04-server-cloudimg-arm64.img"
    arch: "aarch64"
    digest: "sha256:9594596f24b6b47aeda06328a79c4626cdb279c3490e05ac1a9113c19c8f161b"
  - location: "https://cloud-images.ubuntu.com/releases/plucky/release/ubuntu-25.04-server-cloudimg-amd64.img"
    arch: "x86_64"
  - location: "https://cloud-images.ubuntu.com/releases/plucky/release/ubuntu-25.04-server-cloudimg-arm64.img"
    arch: "aarch64"

vmType: "vz"
memory: "1GiB"
cpus: 1

networks:
  - lima: shared
    macAddress: ""
    interface: ""

provision:
  - mode: system
    script: |
      sudo sysctl -w net.ipv4.ip_forward=1

mounts: []
EOF

# Create routed client config
cat > routed-client.yaml <<EOF
images:
  - location: "https://cloud-images.ubuntu.com/releases/plucky/release-20250424/ubuntu-25.04-server-cloudimg-amd64.img"
    arch: "x86_64"
    digest: "sha256:ee752a88573fc8347b4082657293da54a7ba301e3d83cc935fedb4ab6d7129e2"
  - location: "https://cloud-images.ubuntu.com/releases/plucky/release-20250424/ubuntu-25.04-server-cloudimg-arm64.img"
    arch: "aarch64"
    digest: "sha256:9594596f24b6b47aeda06328a79c4626cdb279c3490e05ac1a9113c19c8f161b"
  - location: "https://cloud-images.ubuntu.com/releases/plucky/release/ubuntu-25.04-server-cloudimg-amd64.img"
    arch: "x86_64"
  - location: "https://cloud-images.ubuntu.com/releases/plucky/release/ubuntu-25.04-server-cloudimg-arm64.img"
    arch: "aarch64"

vmType: "vz"
memory: "1GiB"
cpus: 1

networks:
  - lima: shared
    macAddress: ""
    interface: ""

provision:
  - mode: system
    script: |
      sudo ip route replace default via 192.168.105.2

mounts: []
EOF

# Start instances
limactl start ./default-gw.yaml --name=default-gw
limactl start ./routed-client.yaml --name=routed-client

echo "✅ Lima instances launched and network routing configured."
