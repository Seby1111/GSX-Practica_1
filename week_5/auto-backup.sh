#!/bin/bash

# Comprovem si l'script s'executa com a root
if [[ $EUID -ne 0 ]]; then
   echo "[!] Aquest script s'ha d'executar com a root (fent servir sudo)."
   exit 1
fi

# Variables de data
# DATE: usat per anomenar backups
# DAY: determina si fem FULL (diumenge=7) o incremental
# DOM: Day Of Month per guardar el dia de mes en format numèric
DATE=$(date +%F)
DAY=$(date +%u)
DOM=$(date +%d)

# Directoris de backup
# BACKUP_DIR: arrel de backups
# LOG_FILE: fitxer de logs
BACKUP_DIR="/var/backups"
DAILY_DIR="$BACKUP_DIR/daily"
WEEKLY_DIR="$BACKUP_DIR/weekly"
MONTHLY_DIR="$BACKUP_DIR/monthly"
LOG_FILE="/var/log/backup.log"

chmod 1700 $BACKUP_DIR

# SOURCE - Dades crítiques a salvaguardar
#
# /etc -> Configuració del sistema (inclou nginx, usuaris, contrasenyes, sudoers, limits.conf, etc.)
#         (Excloem el que no ens interessa)
# 
# /home/greendevcorp -> Directori de treball de l’equip:
#     - scripts compartits (bin)
#     - treball col·laboratiu (shared)
#     - logs d’activitat (done.log)
#
# /opt -> Aplicacions personalitzades i scripts d’administració
#
# /var/www -> Fitxers web servits per nginx
#
# Inclou: dades + configuració + permisos
SOURCE=(
/etc
/home/greendevcorp
/opt
/var/www
)

# EXCLUDE: Excloure del backup
#   /var/log: logs
#   /tmp: fitxers temporals
#   /proc, /sys, /dev: dades del kernel
# Objectiu: estalviar espai i evitar errors en backup
EXCLUDE=(
--exclude=/var/log
--exclude=/tmp
--exclude=/proc
--exclude=/sys
--exclude=/dev
)

# Tot el que s’executa es guarda a LOG_FILE
exec >> $LOG_FILE 2>&1

echo "================================================================================"
echo "==========================    INICI DEL BACKUP   ==============================="
echo "================================================================================"

echo "Backup iniciat: $DATE"

# Crear directoris si no existeixen

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
# Diumenge -> Full backup (còpia completa amb tar)
# Resta de dies -> Incremental (rsync)
# Primer dia de cada mes -> Full backup de nou
# rsync:
#   copia només canvis
#   -aA preserva permisos

# DAILY BACKUP (es guarda sempre)
echo "DAILY BACKUP"
SNAPSHOT_DIR="$DAILY_DIR/$DATE"
PREV_DIR="$DAILY_DIR/latest"

mkdir -p "$SNAPSHOT_DIR"

# Si existeix backup previ, usar-lo com a referència
if [ -e "$PREV_DIR" ]; then
    LINK_DEST="--link-dest=$PREV_DIR"
else
    LINK_DEST=""
fi

# Executar rsync (amb o sense link-dest) i amb paths relatius (R)
if [ -n "$LINK_DEST" ]; then
    rsync -aA --delete -R "$LINK_DEST" "${EXCLUDE[@]}" "${SOURCE[@]}" "$SNAPSHOT_DIR/"
else
    rsync -aA --delete -R "${EXCLUDE[@]}" "${SOURCE[@]}" "$SNAPSHOT_DIR/"
fi

ln -sfn "$SNAPSHOT_DIR" "$PREV_DIR"

# WEEKLY BACKUP (diumenge)
if [ "$DAY" -eq 7 ]; then
    echo "WEEKLY BACKUP"
    tar --acls --xattrs -czf "$WEEKLY_DIR/backup-weekly-$DATE.tar.gz" "${SOURCE[@]}" 2>/dev/null
fi

# MONTHLY BACKUP (dia 1 del mes)
if [ "$DOM" -eq 01 ]; then
    echo "MONTHLY BACKUP"
    tar --acls --xattrs -czf "$MONTHLY_DIR/backup-monthly-$DATE.tar.gz" "${SOURCE[@]}" 2>/dev/null
fi

echo "Neteja de backups antics..."

# Política de retenció nova
# Daily -> 7 dies
# Weekly -> 4 setmanes (~28 dies)
# Monthly -> 12 mesos (~365 dies)

find "$DAILY_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} + # {} +: per agrupar el contingut i executar la
find "$WEEKLY_DIR" -type f -mtime +28 -delete                                 # instrucció sobre tots, aquí "*" no funciona perquè
find "$MONTHLY_DIR" -type f -mtime +365 -delete                               # no permetria filtrar per antiguitat

echo "Backup completat"

echo "================================================================================"
echo "==========================     FINAL DEL BACKUP     ============================"
echo "================================================================================"
echo ""
echo ""

sudo ./test-backup.sh