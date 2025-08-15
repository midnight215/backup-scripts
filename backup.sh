#!/bin/bash
# ==========================================
# backup.sh - Бэкап CA, Prometheus, OpenVPN на локальной бэкап-VM
# ==========================================

set -euo pipefail

# === Настройки ===
DATE=$(date '+%Y%m%d_%H%M%S')
TMP_DIR="/tmp/backup_$DATE"
FINAL_DIR="/data/backups"
LOG_FILE="/var/log/backup.log"
PUSHGATEWAY="http://localhost:9091/metrics/job/backup"
SSH_KEY="/home/badmin/.ssh/id_rsa_backup"

# Сервера и пользователи
CA_SERVER="dauren@94.131.88.146"
PROM_SERVER="pradmin@94.131.86.155"
OPENVPN_SERVER="openvpn@94.131.87.100"

# === Функция логирования ===
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

# === Функция резервного копирования ===
backup_remote() {
    local SERVER=$1
    local SRC_PATH=$2
    local DEST_PATH=$3
    local USE_SUDO=$4

    log "Бэкап $SRC_PATH с $SERVER → $DEST_PATH"

    if [ "$USE_SUDO" == "yes" ]; then
        RSYNC_PATH="sudo rsync"
    else
        RSYNC_PATH="rsync"
    fi

    ssh -i "$SSH_KEY" "$SERVER" "test -d '$SRC_PATH'" || {
        log "Папка $SRC_PATH не найдена на $SERVER, пропускаем"
        return 0
    }

    rsync -a -e "ssh -i $SSH_KEY" --rsync-path="$RSYNC_PATH" "$SERVER:$SRC_PATH" "$DEST_PATH" || return 1
}

# === Создание структуры во временной папке ===
mkdir -p "$TMP_DIR/ca/pki" "$TMP_DIR/prometheus/conf" "$TMP_DIR/prometheus/data" "$TMP_DIR/openvpn/conf"

# Создаём лог, если нет
[ ! -f "$LOG_FILE" ] && touch "$LOG_FILE"

# === Основной блок ===
main() {
    log "=== Начало резервного копирования ==="
    set +e
    ALL_BACKUPS_OK=1

    # --- CA ---
    backup_remote "$CA_SERVER" "/home/dauren/my-ca/" "$TMP_DIR/ca/pki/" "yes" || ALL_BACKUPS_OK=0

    # --- Prometheus ---
    backup_remote "$PROM_SERVER" "/etc/prometheus/" "$TMP_DIR/prometheus/conf/" "no" || ALL_BACKUPS_OK=0
    backup_remote "$PROM_SERVER" "/var/lib/prometheus/" "$TMP_DIR/prometheus/data/" "no" || ALL_BACKUPS_OK=0

    # --- OpenVPN ---
    backup_remote "$OPENVPN_SERVER" "/etc/openvpn/server/" "$TMP_DIR/openvpn/conf/" "yes" || ALL_BACKUPS_OK=0

    set -e

    # === Архивация ===
    ARCHIVE_NAME="backup_$DATE.tar.gz"
    mkdir -p "$FINAL_DIR"
    tar -czf "$FINAL_DIR/$ARCHIVE_NAME" -C "/tmp" "backup_$DATE"
    log "Архив создан: $FINAL_DIR/$ARCHIVE_NAME"

    # === Отправка статуса в Pushgateway ===
    if [[ $ALL_BACKUPS_OK -eq 1 ]]; then
        log "=== Все бэкапы успешно завершены ==="
        echo "backup_success 1" | curl --silent --data-binary @- "$PUSHGATEWAY"
        exit 0
    else
        log "=== Обнаружены ошибки в бэкапах ==="
        echo "backup_success 0" | curl --silent --data-binary @- "$PUSHGATEWAY"
        exit 1
    fi
}

main
