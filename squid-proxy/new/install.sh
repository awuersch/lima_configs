mkdir -p /etc/squid/ssl
cd /etc/squid/ssl
openssl genrsa -out squid.key 4096
openssl req -new -key squid.key -out squid.csr -subj "/C=XX/ST=XX/L=squid/O=squid/CN=squid-proxy" -addext "subjectAltName = DNS:squid-proxy,DNS:host.lima.internal"
openssl x509 -req -days 3650 -in squid.csr -signkey squid.key -out squid.crt
openssl genrsa -out client.key 4096
openssl req -x509 -new -subj "/C=XX/ST=XX/L=squid/O=squid/CN=client" -key client.key -out client.crt

iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 3129
iptables -t nat -A POSTROUTING -j MASQUERADE
iptables -t mangle -A PREROUTING -p tcp --dport 3129 -j DROP

iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 3130
iptables -t nat -A PREROUTING -p tcp --dport 993 -j REDIRECT --to-port 3130
iptables -t nat -A POSTROUTING -j MASQUERADE
iptables -t mangle -A PREROUTING -p tcp --dport 3130 -j DROP

mkdir -p /var/lib/squid
rm -rf /var/lib/squid/ssl_db
/usr/lib/squid/security_file_certgen -c -s /var/lib/squid/ssl_db -M 20MB
