#!/usr/bin/env bash

update-alternatives --set iptables /usr/sbin/iptables-legacy

iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 3129
iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 3130
iptables -t nat -A PREROUTING -p tcp --dport 993 -j REDIRECT --to-port 3130

# iptables -t nat -A POSTROUTING -j MASQUERADE
# iptables -t mangle -A PREROUTING -p tcp --dport 3129 -j DROP
# iptables -t mangle -A PREROUTING -p tcp --dport 3130 -j DROP
