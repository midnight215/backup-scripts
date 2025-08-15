#!/bin/bash
set -euo pipefail

# Скачивание и установка OpenVPN Exporter
wget https://github.com/qdm12/openvpn_exporter/releases/download/v0.15.0/openvpn_exporter_0.15.0_linux_amd64.tar.gz
tar xvf openvpn_exporter_0.15.0_linux_amd64.tar.gz
cp openvpn_exporter /usr/local/bin/
rm -rf openvpn_exporter_0.15.0_linux_amd64.tar.gz

# Создание systemd unit-файла
cat <<EOF >/etc/systemd/system/openvpn_exporter.service
[Unit]
Description=OpenVPN Exporter
After=network.target

[Service]
ExecStart=/usr/local/bin/openvpn_exporter --openvpn.scrape_uri=file:///etc/openvpn/status.log

[Install]
WantedBy=multi-user.target
EOF

# Запуск и включение сервиса
systemctl daemon-reload
systemctl enable --now openvpn_exporter

echo "OpenVPN Exporter установлен успешно!"
