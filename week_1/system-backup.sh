#!/bin/bash

# ==============================================================================
# SCRIPT DE BACKUP CRIPTOGRÀFIC (GPG)
# Objectiu: Automatitzar la còpia de seguretat, compressió i xifrat de dades.
# ==============================================================================

# Configuració de rutes i paràmetres
BACKUP_DIR="/var/backups/system_backups"
SOURCES=("/etc/configs" "/opt/scripts") # Directoris crítics definits anteriorment
DATE=$(date +%Y%m%d)
OUTPUT_FILE="$BACKUP_DIR/backup_$DATE.tar.gz"
PASSPHRASE="milax" # Contrasenya per al xifrat simètric

EXISTING_SOURCES=()
for src in "${SOURCES[@]}"; do
    # Comprovem si la carpeta o el fitxer existeixen abans d'intentar copiar-los
    if [ -d "$src" ] || [ -f "$src" ]; then
        EXISTING_SOURCES+=("$src")
    else
        echo "[!] La ruta $src no existeix, s'ignorarà."
    fi
done

# Si no hi ha res per copiar, aturem el procés per evitar un fitxer buit
if [ ${#EXISTING_SOURCES[@]} -eq 0 ]; then
    echo "[ERROR] No s'ha trobat cap de les rutes especificades. Avortant backup..."
    exit 1
fi

echo "[INFO] Iniciant el backup de: ${EXISTING_SOURCES[*]}"

# L'usuari 'backupuser' ha de ser el propietari del directori segons l'script de directory-structure
if ! id "backupuser" &>/dev/null; then
    echo "[ERROR] L'usuari 'backupuser' no existeix. Executa primer l'script directory-structre.sh"
    exit 1
fi

# Verifiquem permisos d'escriptura al directori de destinació
if [ ! -w "$BACKUP_DIR" ]; then
    echo "[ERROR] No es pot escriure a $BACKUP_DIR o el directori no existeix."
    exit 1
fi

# -p: Preserva permisos, -z: Comprimeix (gzip), -P: Rutes absolutes
if tar -cpzPf "$OUTPUT_FILE" "${EXISTING_SOURCES[@]}"; then
    echo "[OK] Fitxer comprimit creat correctament."

    echo "[INFO] Encriptant el fitxer de backup..."
    # Utilitzem gpg en mode batch (no interactiu) amb xifrat simètric (-c)
    if GNUPGHOME=/tmp/.gnupg gpg --batch --yes --pinentry-mode loopback --passphrase "$PASSPHRASE" -c "$OUTPUT_FILE"; then
        echo "[OK] Backup encriptat correctament."
        # Eliminem el fitxer .tar.gz original per seguretat (només queda el .gpg)
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