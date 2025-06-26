#!/bin/bash

set -e

mkdir -p lima_net
cd lima_net

# Create gateway instance config
cat > default-gw.yaml <<EOF
images:
  - location: "https://cloud-images.ubuntu.com/releases/25.04/release/ubuntu-25.04-server-cloudimg-amd64.img"
    arch: "x86_64"

vmType: "vz"
# memory: "1GiB"
# cpus: 1

networks:
  - vzMode: "vmnet-shared"
    macAddress: "02:00:00:00:00:01"

provision:
  - mode: system
    script: |
      sudo apt update
      sudo apt install -y iptables dnsmasq net-tools
      sudo sysctl -w net.ipv4.ip_forward=1
      sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
      echo 'nameserver 8.8.8.8' | sudo tee /etc/resolv.conf

mounts: []
EOF

# Create routed client config
cat > routed-client.yaml <<EOF
images:
  - location: "https://cloud-images.ubuntu.com/releases/25.04/release/ubuntu-25.04-server-cloudimg-amd64.img"
    arch: "x86_64"

vmType: "vz"
# memory: "1GiB"
# cpus: 1

networks:
  - vzMode: "vmnet-shared"
    macAddress: "02:00:00:00:00:02"

provision:
  - mode: system
    script: |
      sudo ip route replace default via 192.168.64.2
      echo 'nameserver 192.168.64.2' | sudo tee /etc/resolv.conf

mounts: []
EOF

# Start instances
# limactl start ./default-gw.yaml --name=default-gw
# limactl start ./routed-client.yaml --name=routed-client

# echo "✅ Lima instances launched and network routing configured."

