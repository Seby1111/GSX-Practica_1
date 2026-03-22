#!/bin/bash

# ==============================================================================
# SCRIPT D'AUTOMATITZACIÓ AMB SYSTEMD (BACKUP AS A SERVICE)
# Objectiu: Configurar un Timer i un Service per executar el backup diàriament.
# ==============================================================================

# Comprovem si ja existeix l'usuari de backup abans de crear-lo
if ! id "backupuser" &>/dev/null; then
    echo "[INFO] Creant usuari especific per als backups (backupuser)..."
    # -r (system user), -s nologin (sense accés a shell per seguretat)
    sudo useradd -r -s /usr/sbin/nologin backupuser
fi

# Preparació de l'entorn d'execució
echo "Creant directori /opt/backup..."
sudo mkdir -p /opt/backup
echo "Assignant directori /opt/backup a backupuser"
sudo chown backupuser:backupuser /opt/backup

# Busquem l'script que hem creat anteriorment i el movem a la ruta definitiva
if [ -f "../week_1/system-backup.sh" ]; then
    echo "[INFO] Copiant l'script de backup a /opt/backup com a backup.sh..."
    sudo cp -f ../week_1/system-backup.sh /opt/backup/backup.sh
    echo "[INFO] Donant permisos d'execució a /opt/backup/backup.sh"
    sudo chmod +x /opt/backup/backup.sh
    echo "[INFO] Assignant /opt/backup/backup.sh a backupuser"
    sudo chown backupuser:backupuser /opt/backup/backup.sh
else
    echo "[ERROR] No s'ha trobat l'script system-backup.sh"
    exit 1
fi

# Aquest fitxer defineix COM s'executa el backup (com a backupuser, amb límits de CPU/RAM)
echo "[INFO] Configurant fitxer /etc/systemd/system/backup.service..."
sudo tee /etc/systemd/system/backup.service > /dev/null <<EOF 
[Unit]
Description=System Backup Service

[Service]
Type=simple
User=backupuser
Group=backupuser
WorkingDirectory=/opt/backup

ExecStart=/opt/backup/backup.sh

StandardOutput=journal
StandardError=journal
SyslogIdentifier=backup

TimeoutStartSec=7200

MemoryMax=2G
CPUQuota=50%

Restart=no

[Install]
WantedBy=multi-user.target
EOF

# Aquest fitxer defineix quan s'executa el servei anterior
echo "[INFO] Configurant fitxer /etc/systemd/system/backup.timer..."
sudo tee /etc/systemd/system/backup.timer > /dev/null <<EOF 
[Unit]
Description=Daily System Backup Timer

[Timer]
OnCalendar=*-*-* 00:00:00
Persistent=true
RandomizedDelaySec=300
Unit=backup.service

[Install]
WantedBy=timers.target
EOF

echo "[INFO] Recarregnat els serveis..."
sudo systemctl daemon-reload
echo "[INFO] Activant l'arrancada automatica del backup.timer..."
# Enable: per a que s'engegui sol al reiniciar. --now: per engegar-lo ja.
sudo systemctl enable --now backup.timer

echo "[OK] Servei de backup i timer configurats correctament."
