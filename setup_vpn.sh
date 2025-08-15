#!/bin/bash
set -euo pipefail

# Проверка прав
if [[ $EUID -ne 0 ]]; then
  echo "Запустите скрипт от root"
  exit 1
fi

# Проверяем, установлен ли openvpn
if ! dpkg -s openvpn &> /dev/null; then
    echo "Устанавливаем OpenVPN..."
    apt update
    apt install -y openvpn
else
    echo "OpenVPN уже установлен"
fi

# Проверяем, установлен ли easy-rsa
if ! dpkg -s easy-rsa &> /dev/null; then
    echo "Устанавливаем Easy-RSA..."
    apt install -y easy-rsa
else
    echo "Easy-RSA уже установлен"
fi

# Включаем IP Forward
if ! grep -q '^net.ipv4.ip_forward=1' /etc/sysctl.conf; then
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
fi
sysctl -p

# Копируем пример конфигурации сервера
gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz > /etc/openvpn/server/vpnoffice.conf

# Разрешаем маршрутизацию через VPN
sed -i 's/;push "redirect-gateway def1 bypass-dhcp"/push "redirect-gateway def1 bypass-dhcp"/' /etc/openvpn/server/vpnoffice.conf
sed -i 's/;push "dhcp-option DNS 208.67.222.222"/push "dhcp-option DNS 8.8.8.8"/' /etc/openvpn/server/vpnoffice.conf

# --- ДОБАВЛЕНИЕ: копируем кастомный конфиг перед запуском OpenVPN ---
if [ -f /usr/local/sbin/vpnoffice.conf ]; then
    echo "Копируем кастомный конфиг OpenVPN перед запуском..."

    # Создаём директорию, если она не существует
    [ -d /etc/openvpn/server ] || mkdir -p /etc/openvpn/server

    # Копируем кастомный конфиг
    cp -f /usr/local/sbin/vpnoffice.conf /etc/openvpn/server/vpnoffice.conf
    echo "Конфиг заменён на кастомный"
else
    echo "Кастомный конфиг не найден, стандартный оставляем"
fi

# Включаем и перезапускаем OpenVPN
systemctl enable openvpn-server@vpnoffice.service
systemctl restart openvpn-server@vpnoffice.service

echo "VPN-сервер настроен успешно!"
