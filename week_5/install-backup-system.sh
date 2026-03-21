#!/bin/bash

# Aquest script activara auto-backup.sh com a backup periodic del servei backup.service

arxiu="/usr/local/sbin/auto-backup.sh"

if [ ! -f "$arxiu" ]; then
    echo "Creant auto-backup.sh..."

    sudo tee "$arxiu" > /dev/null << 'EOF'
#!/bin/bash

# Comprovem si l'script s'executa com a root
if [[ $EUID -ne 0 ]]; then
   echo "[!] Aquest script s'ha d'executar com a root (fent servir sudo)."
   exit 1
fi

# Variables de fecha
# DATE: usado para nombrar backups
# DAY: determina si hacemos FULL (domingo=7) o incremental
# DOM: Day Of Month para guardar el dia de mes en formato numérico
DATE=$(date +%F)
DAY=$(date +%u)
DOM=$(date +%d)

# Directorios de backup
# BACKUP_DIR: raíz de backups
# FULL_DIR: backups completos (semanales)
# INC_DIR: backups incrementales (diarios)
# LOG_FILE: archivo de logs
BACKUP_DIR="/var/backups"
FULL_DIR="$BACKUP_DIR/full"
INC_DIR="$BACKUP_DIR/incremental/$DATE"
DAILY_DIR="$BACKUP_DIR/daily"
WEEKLY_DIR="$BACKUP_DIR/weekly"
MONTHLY_DIR="$BACKUP_DIR/monthly"
LOG_FILE="/var/log/backup.log"

chmod 1700 $BACKUP_DIR

# SOURCE - Datos críticos a respaldar
#
# /etc -> Configuración del sistema (incluye nginx, usuarios, contraseñas, sudoers, limits.conf, etc.)
#         (Excluimos lo que no nos interesa)
# 
# /home/greendevcorp -> Directorio de trabajo del equipo:
#     - scripts compartidos (bin)
#     - trabajo colaborativo (shared)
#     - logs de actividad (done.log)
#
# /opt -> Aplicaciones personalizadas y scripts de administración
#
# /var/www -> Archivos web servidos por nginx
#
# /etc/letsencrypt -> Certificados SSL (HTTPS) para restaurar servicio web
#
# Incluye: datos + configuración + permisos
SOURCE=(
/etc
/home/greendevcorp
/opt
/var/www
/etc/letsencrypt
)

# EXCLUDE: Excluir del backup
#   /var/log: logs
#   /tmp: ficheros temporales
#   /proc, /sys, /dev: datos del kernel
# Objetivo: ahorrar espacio y evitar errores en backup
EXCLUDE=(
--exclude=/var/log
--exclude=/tmp
--exclude=/proc
--exclude=/sys
--exclude=/dev
)

# Todo lo que se ejecute se guarda en LOG_FILE
exec >> $LOG_FILE 2>&1

echo "================================================================================"
echo "==========================    START OF BACKUP   ================================"
echo "================================================================================"

echo "Backup iniciado: $DATE"

# Crear directorios si no existen
if [ ! -d "$FULL_DIR" ]; then
    echo "Creando directorio full: $FULL_DIR"
    mkdir -p "$FULL_DIR"
fi

if [ ! -d "$INC_DIR" ]; then
    echo "Creando directorio incremental: $INC_DIR"
    mkdir -p "$INC_DIR"
fi

if [ ! -d "$DAILY_DIR" ]; then
    mkdir -p "$DAILY_DIR"
fi

if [ ! -d "$WEEKLY_DIR" ]; then
    mkdir -p "$WEEKLY_DIR"
fi

if [ ! -d "$MONTHLY_DIR" ]; then
    mkdir -p "$MONTHLY_DIR"
fi

# BACKUP PRINCIPAL:
# Domingo -> Full backup (copia completa con tar)
# Resto de días -> Incremental (rsync)
# rsync:
#   copia solo cambios
#   -aA preserva permisos
if [ "$DAY" -eq 7 ]; then
    echo "FULL BACKUP"
    tar --acls --xattrs -czf "$FULL_DIR/backup-$DATE.tar.gz" "${SOURCE[@]}"
else
    echo "INCREMENTAL BACKUP"
    rsync -aA --delete "${EXCLUDE[@]}" "${SOURCE[@]}" "$INC_DIR"
fi

# DAILY BACKUP (se guarda siempre)
tar --acls --xattrs -czf "$DAILY_DIR/backup-$DATE.tar.gz" "${SOURCE[@]}"

# WEEKLY BACKUP (domingo)
if [ "$DAY" -eq 7 ]; then
    echo "WEEKLY BACKUP"
    tar --acls --xattrs -czf "$WEEKLY_DIR/backup-weekly-$DATE.tar.gz" "${SOURCE[@]}"
fi

# MONTHLY BACKUP (día 1 del mes)
if [ "$DOM" -eq 01 ]; then
    echo "MONTHLY BACKUP"
    tar --acls --xattrs -czf "$MONTHLY_DIR/backup-monthly-$DATE.tar.gz" "${SOURCE[@]}"
fi

# Full backups -> borrar > 30 días
# Incrementales -> borrar > 7 días
echo "Limpieza de backups antiguos..."
find "$BACKUP_DIR/full" -type f -mtime +30 -delete
find "$BACKUP_DIR/incremental" -type d -mtime +7 -exec rm -rf {} \;

# Retention policy nueva
# Daily -> 7 días
# Weekly -> 4 semanas (~28 días)
# Monthly -> 12 meses (~365 días)

find "$DAILY_DIR" -type f -mtime +7 -delete
find "$WEEKLY_DIR" -type f -mtime +28 -delete
find "$MONTHLY_DIR" -type f -mtime +365 -delete

if [ $? -eq 0 ]; then
    echo "Backup completado correctamente"
else
    echo "Error en el backup"
fi

echo "Backup completado"

echo "================================================================================"
echo "==========================     END OF BACKUP     ==============================="
echo "================================================================================"

sudo ./test-backup.sh
EOF

    sudo chmod 700 "$arxiu"
fi

arxiu="/usr/local/sbin/test-backup.sh"

if [ ! -f "$arxiu" ]; then
    echo "Creant test-backup.sh..."

    sudo tee "$arxiu" > /dev/null << 'EOF'
#!/bin/bash

set -e

# Variables (ajusta según tu entorno)
BACKUP_DIR="/var/backups"
TEST_DIR="/tmp/restore-test"

LOG_FILE="/var/log/backup-test.log"

# Redirigir salida a log
exec >> "$LOG_FILE" 2>&1

echo "================================================================================"
echo "========================  START OF BACKUP TEST  ================================"
echo "================================================================================"

echo ""
echo "Start at: $(date)"

# Limpiar entorno
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

test_tar_backup () {
    local FILE=$1
    local NAME=$2

    echo "[TEST] $NAME -> $FILE"

    if [ ! -f "$FILE" ]; then
        echo "[ERROR] Missing $NAME backup"
        return 1
    fi

    # Verificar integridad
    if tar -tzf "$FILE" > /dev/null 2>&1; then
        echo "[OK] Archive integrity in order"
    else
        echo "[ERROR] Corrupted archive"
        return 1
    fi

    # Restaurar en subdir
    local DEST="$TEST_DIR/$NAME"
    mkdir -p "$DEST"

    tar -xzf "$FILE" -C "$DEST"

    # Verificación básica
    if [ -d "$DEST/etc" ] && [ -d "$DEST/home" ]; then
        echo "[OK] Structure in order for $NAME"
    else
        echo "[ERROR] Missing critical dirs in $NAME"
        return 1
    fi

    return 0
}


echo "[1] Testing DAILY backups..."

DAILY_BACKUPS=$(ls -t "$BACKUP_DIR/daily"/backup-*.tar.gz 2>/dev/null | head -n 1)

if [ -n "$DAILY_BACKUPS" ]; then
    test_tar_backup "$DAILY_BACKUPS" "daily"
else
    echo "[ERROR] No daily backups found"
fi

echo "[2] Testing WEEKLY backups..."

WEEKLY_BACKUPS=$(ls -t "$BACKUP_DIR/weekly"/backup-weekly-*.tar.gz 2>/dev/null | head -n 1)

if [ -n "$WEEKLY_BACKUPS" ]; then
    test_tar_backup "$WEEKLY_BACKUPS" "weekly"
else
    echo "[ERROR] No weekly backups found"
fi

echo "[3] Testing MONTHLY backups..."

MONTHLY_BACKUPS=$(ls -t "$BACKUP_DIR/monthly"/backup-monthly-*.tar.gz 2>/dev/null | head -n 1)

if [ -n "$MONTHLY_BACKUPS" ]; then
    test_tar_backup "$MONTHLY_BACKUPS" "monthly"
else
    echo "[ERROR] No monthly backups found"
fi

echo "[4] Testing FULL backups..."

FULL_BACKUP=$(ls -t "$BACKUP_DIR/full"/backup-*.tar.gz 2>/dev/null | head -n 1)

if [ -n "$FULL_BACKUP" ]; then
    test_tar_backup "$FULL_BACKUP" "full"
else
    echo "[ERROR] No full backups found"
fi

echo "[5] Testing INCREMENTAL backups..."

INC_DIR="$BACKUP_DIR/incremental"

if [ -d "$INC_DIR" ]; then
    COUNT=$(find "$INC_DIR" -type d | wc -l)
    echo "Incremental directories found: $COUNT"

    if [ "$COUNT" -gt 0 ]; then
        echo "[OK] Incremental backups exist"
    else
        echo "[ERROR] No incremental backups"
    fi
else
    echo "[ERROR] Incremental directory missing"
fi

echo "[6] RTO simulation test..."

if [ -n "$FULL_BACKUP" ]; then
    echo "Simulating restore timing..."
    time tar -xzf "$FULL_BACKUP" -C "$TEST_DIR"
    echo "[OK] Restore simulation completed"
fi

echo "[7] Cleaning test environment..."
rm -rf "$TEST_DIR"


echo "================================================================================"
echo "========================   END OF BACKUP TEST   ================================"
echo "================================================================================"

exit 0
EOF

    sudo chmod 700 "$arxiu"
fi

arxiu="/etc/systemd/system/backup.service"

if [ ! -f "$arxiu" ]; then
    echo "Creant backup.service..."

    sudo tee "$arxiu" > /dev/null << 'EOF'
[Unit]
Description=Backup Script

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/auto-backup.sh
EOF
fi

arxiu="/etc/systemd/system/backup.timer"

if [ ! -f "$arxiu" ]; then
    echo "Creant backup.timer..."

    sudo tee "$arxiu" > /dev/null << 'EOF'
[Unit]
Description=Run backup daily at 2 AM

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable backup.timer
sudo systemctl start backup.timer
fi

# Comprova si backup existeix com a servici en systemd
if systemctl list-unit-files | grep -q "backup.service"; then
    echo "[OK] Timer inicialitzat correctament."
else
    echo "[!] Timer no inicialitzat correctament."
fi