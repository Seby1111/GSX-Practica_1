#!/bin/bash

BACKUP_DIR="/opt/backup"
SOURCE_FILES=("/etc/configs" "/opt/scripts" "/home/eusebiu/GSX-Practica_1")
DATE=$(date +%Y%m%d)
OUTPUT_FILE="$BACKUP_DIR/backup_$DATE.tar.gz"

if ! id "backupuser" &>/dev/null; then
    echo "[INFO] Creant usuari especific per als backups (backupuser)..."
    sudo useradd -r -s /usr/sbin/nologin backupuser
fi

echo "[INFO] Verificant directori de backup..."
sudo mkdir -p "$BACKUP_DIR"
sudo chown backupuser:backupuser "$BACKUP_DIR"

echo "[INFO] Iniciant el backup de dades sensibles..."

read -sp "[*] Introdueix la contrasenya per encriptar el backup: " PASSPHRASE

tar -cpzvf "$OUTPUT_FILE" "${SOURCE_FILES[@]}" 2>/dev/null

echo "[INFO] Encriptant el fitxer de backup..."
gpg --batch --yes --passphrase "$PASSPHRASE" -c "$OUTPUT_FILE"

# 3. Neteja: Esborrem el tar sense encriptar per seguretat
rm -f "$OUTPUT_FILE"

echo "[OK] Backup completat i encriptat: ${OUTPUT_FILE}.gpg"