#!/bin/bash
set -euo pipefail

# Переменные
VERSION="1.7.0"
URL="https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.linux-amd64.tar.gz"
TMP_DIR="/tmp"
INSTALL_DIR="/usr/local/bin"

echo "Скачиваем node_exporter v${VERSION}..."
wget -O "${TMP_DIR}/node_exporter.tar.gz" "$URL"

echo "Распаковываем архив..."
tar -xzf "${TMP_DIR}/node_exporter.tar.gz" -C "$TMP_DIR"

echo "Устанавливаем бинарник..."
cp "${TMP_DIR}/node_exporter-${VERSION}.linux-amd64/node_exporter" "$INSTALL_DIR/"

echo "Создаем пользователя для node_exporter..."
useradd --no-create-home --shell /bin/false node_exporter || true

echo "Создаем systemd-сервис..."
cat <<EOF >/etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=$INSTALL_DIR/node_exporter

[Install]
WantedBy=default.target
EOF

echo "Перезагружаем systemd и запускаем сервис..."
systemctl daemon-reload
systemctl enable --now node_exporter

echo "Проверяем статус сервиса..."
systemctl status node_exporter --no-pager
