#!/bin/bash

# ==============================================================================
# SCRIPT DE CREACIÓ D'ESTRUCTURA ADMINISTRATIVA I USUARI DE BACKUP
# Objectiu: Preparar el sistema de fitxers per a tasques d'administració i còpies.
# ==============================================================================

echo "Creant estructura de directoris administratius"

# Creació de directoris seguint l'estàndard FHS (Filesystem Hierarchy Standard)
# /etc/configs: Per emmagatzemar versions personalitzades de fitxers de configuració
echo "[INFO] Creant directori /etc/configs..."
sudo mkdir -p /etc/configs

# /opt/scripts: Directori per a aplicacions i scripts addicionals que no formen part del sistema base
echo "[INFO] Creant directori /opt/scripts..."
sudo mkdir -p /opt/scripts

# /var/backups/system_backups: Espai dedicat a les còpies de seguretat locals
echo "[INFO] Creant directori /var/backups/system_backups..."
sudo mkdir -p /var/backups/system_backups

# Creem un usuari de sistema dedicat exclusivament a la gestió de backups
# -r: Crea un usuari de sistema (sense UID d'usuari normal)
# -s /usr/sbin/nologin: Impedeix que ningú pugui iniciar sessió interactiva amb aquest usuari (Seguretat)
if ! id "backupuser" &>/dev/null; then
    echo "[INFO] Creant usuari especific per als backups (backupuser)..."
    sudo useradd -r -s /usr/sbin/nologin backupuser
fi

# Assignem la propietat del directori de backups a l'usuari corresponent
sudo chown backupuser:backupuser /var/backups/system_backups

# Ajustem permisos: 750 (L'amo pot tot, el grup pot llegir/executar, altres res)
# Això protegeix les còpies de seguretat d'usuaris no autoritzats
sudo chmod 750 /var/backups/system_backups