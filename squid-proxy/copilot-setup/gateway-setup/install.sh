#!/bin/bash
set -e

echo "[*] Installing Squid and tools..."
sudo apt update
sudo apt install -y squid openssl iptables dnsmasq

echo "[*] Setting up SSL certs..."
CERT_DIR="/etc/squid/ssl_cert"
sudo mkdir -p "$CERT_DIR"
sudo openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
  -keyout "$CERT_DIR/myCA.key" -out "$CERT_DIR/myCA.crt" \
  -subj "/CN=Squid Proxy CA"
sudo chown -R proxy:proxy "$CERT_DIR"

echo "[*] Initializing cert DB..."
sudo /usr/lib/squid/security_file_certgen -c -s /var/lib/ssl_db -M 4MB
sudo chown -R proxy:proxy /var/lib/ssl_db

echo "[*] Enabling IP forwarding..."
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "[*] Applying configuration..."
sudo cp squid.conf /etc/squid/squid.conf
sudo systemctl restart squid
sudo systemctl enable squid

echo "[*] Done! You may want to import myCA.crt into client trust stores."
