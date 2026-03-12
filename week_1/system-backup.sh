#!/bin/bash

BACKUP_DIR="/var/backups/system_backups"
SOURCES=("/etc/configs" "/opt/scripts")
DATE=$(date +%Y%m%d)
OUTPUT_FILE="$BACKUP_DIR/backup_$DATE.tar.gz"
PASSPHRASE="milax"

EXISTING_SOURCES=()
for src in "${SOURCES[@]}"; do
    if [ -d "$src" ] || [ -f "$src" ]; then
        EXISTING_SOURCES+=("$src")
    else
        echo "[!] La ruta $src no existeix, s'ignorarà."
    fi
done

if [ ${#EXISTING_SOURCES[@]} -eq 0 ]; then
    echo "[ERROR] No s'ha trobat cap de les rutes especificades. Avortant backup..."
    exit 1
fi

echo "[INFO] Iniciant el backup de: ${EXISTING_SOURCES[*]}"

if ! id "backupuser" &>/dev/null; then
    echo "[ERROR] L'usuari 'backupuser' no existeix. Executa primer l'script directory-structre.sh"
    exit 1
fi

if [ ! -w "$BACKUP_DIR" ]; then
    echo "[ERROR] No es pot escriure a $BACKUP_DIR o el directori no existeix."
    exit 1
fi

if tar -cpzPf "$OUTPUT_FILE" "${EXISTING_SOURCES[@]}"; then
    echo "[OK] Fitxer comprimit creat correctament."

    echo "[INFO] Encriptant el fitxer de backup..."
    if GNUPGHOME=/tmp/.gnupg gpg --batch --yes --pinentry-mode loopback --passphrase "$PASSPHRASE" -c "$OUTPUT_FILE"; then
        echo "[OK] Backup encriptat correctament."
        rm -f "$OUTPUT_FILE"
    else
        echo "[ERROR] L'encriptació ha fallat."
        exit 1
    fi
else
    echo "[ERROR] El tar ha fallat."
    exit 1
fi

echo "[OK] Backup completat i encriptat: ${OUTPUT_FILE}.gpg"