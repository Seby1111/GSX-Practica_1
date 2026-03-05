#!/bin/bash

echo "Creant estructura de directoris administratius"

echo "[INFO] Creant directori /etc/configs..."
sudo mkdir -p /etc/configs

echo "[INFO] Creant directori /etc/scripts..."
sudo mkdir -p /opt/scripts

echo "[INFO] Creant directori /etc/backups..."
sudo mkdir -p /var/backups

if ! id "backupuser" &>/dev/null; then
    echo "[INFO] Creant usuari especific per als backups (backupuser)..."
    sudo useradd -r -s /usr/sbin/nologin backupuser
fi

sudo chown backupuser:backupuser /var/backups 
