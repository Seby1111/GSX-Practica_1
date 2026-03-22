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
# LOG_FILE: archivo de logs
BACKUP_DIR="/var/backups"
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
# Incluye: datos + configuración + permisos
SOURCE=(
/etc
/home/greendevcorp
/opt
/var/www
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
# Primer dia de cada mes -> Full backup de nuevo
# rsync:
#   copia solo cambios
#   -aA preserva permisos

# DAILY BACKUP (se guarda siempre)
echo "DAILY BACKUP"
SNAPSHOT_DIR="$DAILY_DIR/$DATE"
PREV_DIR="$DAILY_DIR/latest"

mkdir -p "$SNAPSHOT_DIR"

# Si existe backup previo, usarlo como referencia
if [ -e "$PREV_DIR" ]; then
    LINK_DEST="--link-dest=$PREV_DIR"
else
    LINK_DEST=""
fi

# Ejecutar rsync (con o sin link-dest) y con paths relativo (R)
if [ -n "$LINK_DEST" ]; then
    rsync -aA --delete -R "$LINK_DEST" "${EXCLUDE[@]}" "${SOURCE[@]}" "$SNAPSHOT_DIR/"
else
    rsync -aA --delete -R "${EXCLUDE[@]}" "${SOURCE[@]}" "$SNAPSHOT_DIR/"
fi

ln -sfn "$SNAPSHOT_DIR" "$PREV_DIR"

# WEEKLY BACKUP (domingo)
if [ "$DAY" -eq 7 ]; then
    echo "WEEKLY BACKUP"
    tar --acls --xattrs -czf "$WEEKLY_DIR/backup-weekly-$DATE.tar.gz" "${SOURCE[@]}" 2>/dev/null
fi

# MONTHLY BACKUP (día 1 del mes)
if [ "$DOM" -eq 01 ]; then
    echo "MONTHLY BACKUP"
    tar --acls --xattrs -czf "$MONTHLY_DIR/backup-monthly-$DATE.tar.gz" "${SOURCE[@]}" 2>/dev/null
fi

echo "Limpieza de backups antiguos..."

# Retention policy nueva
# Daily -> 7 días
# Weekly -> 4 semanas (~28 días)
# Monthly -> 12 meses (~365 días)

find "$DAILY_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} + # {} + : para agrupar el contenido y ejecutar la
find "$WEEKLY_DIR" -type f -mtime +28 -delete                                 # instrucción sobre todos, aquí "*" no funciona porque
find "$MONTHLY_DIR" -type f -mtime +365 -delete                               # no permitiría filtrar por antigüedad

echo "Backup completado"

echo "================================================================================"
echo "==========================     END OF BACKUP     ==============================="
echo "================================================================================"
echo ""
echo ""

sudo ./test-backup.sh