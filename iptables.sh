#!/bin/bash
set -euo pipefail

ETH=${1:-eth0}   # внешний интерфейс по умолчанию
PROTO=${2:-udp}  # протокол по умолчанию
PORT=${3:-1194}  # порт OpenVPN по умолчанию

# Очистка всех правил
iptables -F
iptables -t nat -F
iptables -X

# Разрешаем loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Разрешаем SSH (чтобы не потерять доступ)
iptables -A INPUT -i "$ETH" -p tcp --dport 22 -j ACCEPT

# Разрешаем входящий трафик на OpenVPN
iptables -A INPUT -i "$ETH" -p "$PROTO" --dport "$PORT" -j ACCEPT

# Разрешаем весь трафик VPN
iptables -A INPUT -i tun+ -j ACCEPT
iptables -A FORWARD -i tun+ -o "$ETH" -j ACCEPT
iptables -A FORWARD -i "$ETH" -o tun+ -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i tun+ -j ACCEPT

# NAT для VPN клиентов
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o "$ETH" -j MASQUERADE

echo "iptables применены успешно!"
