#!/bin/bash

echo "Creant estructura de directoris administratius"

echo "[INFO] Creant directori /etc/configs..."
sudo mkdir -p /etc/configs

echo "[INFO] Creant directori /opt/scripts..."
sudo mkdir -p /opt/scripts

echo "[INFO] Creant directori /var/backups/system_backups..."
sudo mkdir -p /var/backups/system_backups

if ! id "backupuser" &>/dev/null; then
    echo "[INFO] Creant usuari especific per als backups (backupuser)..."
    sudo useradd -r -s /usr/sbin/nologin backupuser
fi

sudo chown backupuser:backupuser /var/backups/system_backups
sudo chmod 750 /var/backups/system_backups