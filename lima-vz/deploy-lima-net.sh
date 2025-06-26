#!/bin/bash

set -e

mkdir -p lima_net
cd lima_net

# Create gateway instance config
cat > default-gw.yaml <<EOF
images:
  - location: "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
    arch: "x86_64"

vmType: "vz"
memory: "1GiB"
cpus: 1

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
