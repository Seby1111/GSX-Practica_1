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
EOF

    sudo chmod 700 "$arxiu"
fi

arxiu="/usr/local/sbin/test-backup.sh"

if [ ! -f "$arxiu" ]; then
    echo "Creant test-backup.sh..."

    sudo tee "$arxiu" > /dev/null << 'EOF'
#!/bin/bash

# Comprovem si l'script s'executa com a root
if [[ $EUID -ne 0 ]]; then
   echo "[!] Aquest script s'ha d'executar com a root (fent servir sudo)."
   exit 1
fi

# Variables (ajusta según tu entorno)
BACKUP_DIR="/var/backups"
TEST_DIR="/tmp/restore-test"

LOG_FILE="/var/log/backup-test.log"

# Configuración de alertas
ALERT_EMAIL="alexandru-ciprian.radu@estudiants.urv.cat"
HOSTNAME=$(hostname)

# Control de errores
ERRORS=0

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

# Función de alerta
send_alert () {
    local MSG=$1
    echo "[ALERT] $MSG"
    let ERRORS=$ERRORS+1
}

test_tar_backup () {
    local FILE=$1
    local NAME=$2

    echo "[TEST] $NAME -> $FILE"

    # Comprobar que archivo existe
    if [ ! -f "$FILE" ]; then
        echo "[ERROR] Missing $NAME backup"
        send_alert "Missing $NAME backup on $HOSTNAME"
    fi

    # Verificar integridad
    if tar --acls --xattrs -tzf "$FILE" > /dev/null 2>&1; then
        echo "[OK] Archive integrity in order"
    else
        echo "[ERROR] Corrupted archive"
        send_alert "Corrupted $NAME backup on $HOSTNAME"
    fi

    # Restaurar en subdir (carpeta temporal para test)
    local DEST="$TEST_DIR/$NAME"
    mkdir -p "$DEST"

    tar --acls --xattrs -xzf "$FILE" -C "$DEST"

    # Verificación básica
    if [ -d "$DEST/etc" ] && [ -d "$DEST/home" ]; then
        echo "[OK] Structure in order for $NAME"
    else
        echo "[ERROR] Missing critical dirs in $NAME"
        send_alert "Structure failure in $NAME backup"
    fi

    # Verificación de contenido real (mínimamente)
    if [ -f "$DEST/etc/passwd" ]; then
        echo "[OK] Critical file exists (/etc/passwd)"
    else
        echo "[ERROR] Missing /etc/passwd"
        send_alert "Missing passwd file in $NAME backup"
    fi

    # Verificación estructura greendevcorp
    GDC_BASE="$DEST/home/greendevcorp"

    if [ -d "$GDC_BASE" ]; then
        echo "[OK] greendevcorp directory exists"
    else
        echo "[ERROR] Missing /home/greendevcorp"
        send_alert "Missing greendevcorp directory"
    fi

    # Verificar subdirectorios
    if [ -d "$GDC_BASE/bin" ] && [ -d "$GDC_BASE/shared" ]; then
        echo "[OK] greendevcorp structure correct"
    else
        echo "[ERROR] Missing bin or shared directory"
        send_alert "Structure error in greendevcorp"
    fi

    # Verificar archivo done.log
    if [ -f "$GDC_BASE/done.log" ]; then
        echo "[OK] done.log exists"
    else
        echo "[ERROR] Missing done.log"
        send_alert "Missing done.log"
    fi

    # Verificación de permisos bin (750)
    PERM_BIN=$(permisos "$GDC_BASE/bin" 2>/dev/null || echo "000")
    if [ "$PERM_BIN" != "750" ]; then
        echo "[ERROR] Wrong permissions on bin ($PERM_BIN)"
        send_alert "Bad permissions on bin"
    else
        echo "[OK] bin permissions correct"
    fi

    # Verificación de permisos shared (3770)
    PERM_SHARED=$(stat -c %a "$GDC_BASE/shared" 2>/dev/null || echo "000")
    if [ "$PERM_SHARED" != "3770" ]; then
        echo "[ERROR] Wrong permissions on shared ($PERM_SHARED)"
        send_alert "Bad permissions on shared"
    else
        echo "[OK] shared permissions correct"
    fi

    # Verificación done.log (644)
    PERM_LOG=$(permisos "$GDC_BASE/done.log" 2>/dev/null || echo "000")
    if [ "$PERM_LOG" != "644" ]; then
        echo "[ERROR] Wrong permissions on done.log ($PERM_LOG)"
        send_alert "Bad permissions on done.log"
    else
        echo "[OK] done.log permissions correct"
    fi
}

# Lo mismo que la función anterior pero adaptado para los snapshots incrementales de DAILY
test_snapshot_backup () {
    local DIR=$1
    local NAME=$2

    echo "[TEST] $NAME -> $DIR"

    # Comprobar que el directorio existe
    if [ ! -d "$DIR" ]; then
        echo "[ERROR] Missing $NAME snapshot"
        send_alert "Missing $NAME snapshot on $HOSTNAME"
        return
    fi

    # Verificación básica de estructura
    if [ -d "$DIR/etc" ] && [ -d "$DIR/home" ]; then
        echo "[OK] Structure in order for $NAME"
    else
        echo "[ERROR] Missing critical dirs in $NAME"
        send_alert "Structure failure in $NAME snapshot"
    fi

    # Verificación de contenido real
    if [ -f "$DIR/etc/passwd" ]; then
        echo "[OK] Critical file exists (/etc/passwd)"
    else
        echo "[ERROR] Missing /etc/passwd"
        send_alert "Missing passwd file in $NAME snapshot"
    fi

    # Verificación estructura greendevcorp
    GDC_BASE="$DIR/home/greendevcorp"

    if [ -d "$GDC_BASE" ]; then
        echo "[OK] greendevcorp directory exists"
    else
        echo "[ERROR] Missing /home/greendevcorp"
        send_alert "Missing greendevcorp directory"
        return
    fi

    # Verificar subdirectorios
    if [ -d "$GDC_BASE/bin" ] && [ -d "$GDC_BASE/shared" ]; then
        echo "[OK] greendevcorp structure correct"
    else
        echo "[ERROR] Missing bin or shared directory"
        send_alert "Structure error in greendevcorp"
    fi

    # Verificar archivo done.log
    if [ -f "$GDC_BASE/done.log" ]; then
        echo "[OK] done.log exists"
    else
        echo "[ERROR] Missing done.log"
        send_alert "Missing done.log"
    fi

    # Verificación de permisos bin (750) en formato octal (%a)
    PERM_BIN=$(permisos "$GDC_BASE/bin" 2>/dev/null || echo "000")
    if [ "$PERM_BIN" != "750" ]; then
        echo "[ERROR] Wrong permissions on bin ($PERM_BIN)"
        send_alert "Bad permissions on bin"
    else
        echo "[OK] bin permissions correct"
    fi

    # Verificación de permisos shared (3770)
    PERM_SHARED=$(stat -c %a "$GDC_BASE/shared" 2>/dev/null || echo "000")
    if [ "$PERM_SHARED" != "3770" ]; then
        echo "[ERROR] Wrong permissions on shared ($PERM_SHARED)"
        send_alert "Bad permissions on shared"
    else
        echo "[OK] shared permissions correct"
    fi

    # Verificación done.log (644)
    PERM_LOG=$(permisos "$GDC_BASE/done.log" 2>/dev/null || echo "000")
    if [ "$PERM_LOG" != "644" ]; then
        echo "[ERROR] Wrong permissions on done.log ($PERM_LOG)"
        send_alert "Bad permissions on done.log"
    else
        echo "[OK] done.log permissions correct"
    fi

    # Verificación avanzada: comparación real contra sistema original (checksum)
    echo "[CHECK] Verifying snapshot consistency with source (checksum diff)..."

    if rsync -avnc --delete /etc/ "$DIR/etc/" > /dev/null 2>&1; then
        echo "[OK] /etc matches source (checksum)"
    else
        echo "[ERROR] Differences found in /etc"
        send_alert "Checksum mismatch in /etc for $NAME snapshot"
    fi

    if rsync -avnc --delete /home/greendevcorp/ "$DIR/home/greendevcorp/" > /dev/null 2>&1; then
        echo "[OK] /home/greendevcorp matches source (checksum)"
    else
        echo "[ERROR] Differences found in /home/greendevcorp"
        send_alert "Checksum mismatch in greendevcorp for $NAME snapshot"
    fi
}

permisos() {
    local f="$1"

    u=$(getfacl --absolute-names "$f" 2>/dev/null | grep '^user::' | cut -d: -f3)
    g=$(getfacl --absolute-names "$f" 2>/dev/null | grep '^group::' | cut -d: -f3)
    o=$(getfacl --absolute-names "$f" 2>/dev/null | grep '^other::' | cut -d: -f3)

    perm_to_oct() {
        local p="$1"
        local r=0 w=0 x=0
        echo "$p" | grep -q r && r=4
        echo "$p" | grep -q w && w=2
        echo "$p" | grep -q x && x=1
        echo $((r + w + x))
    }

    ur=$(perm_to_oct "$u")
    gr=$(perm_to_oct "$g")
    or=$(perm_to_oct "$o")

    echo "${ur}${gr}${or}"
}

echo "[1] Testing DAILY backups..."

# Alternativa más segura a ordena por timestamp, se queda con la más reciente y solo la ruta de esa última versión
DAILY_BACKUP=$(find "$BACKUP_DIR/daily" -mindepth 1 -maxdepth 1 -type d -printf "%T@ %p\n" 2>/dev/null | sort -nr | head -n 1 | cut -d' ' -f2-)

if [ -n "$DAILY_BACKUP" ]; then
    test_snapshot_backup "$DAILY_BACKUP" "daily"
else
    echo "[ERROR] No daily backups found"
    send_alert "No daily backups found"
fi

echo "[2] Testing WEEKLY backups..."

WEEKLY_BACKUPS=$(find "$BACKUP_DIR/weekly" -type f -name "backup-weekly-*.tar.gz" -printf "%T@ %p\n" 2>/dev/null | sort -nr | head -n 1 | cut -d' ' -f2-)

if [ -n "$WEEKLY_BACKUPS" ]; then
    test_tar_backup "$WEEKLY_BACKUPS" "weekly"
else
    echo "[ERROR] No weekly backups found"
    send_alert "No weekly backups found"
fi

echo "[3] Testing MONTHLY backups..."

MONTHLY_BACKUPS=$(find "$BACKUP_DIR/monthly" -type f -name "backup-monthly-*.tar.gz" -printf "%T@ %p\n" 2>/dev/null | sort -nr | head -n 1 | cut -d' ' -f2-)

if [ -n "$MONTHLY_BACKUPS" ]; then
    test_tar_backup "$MONTHLY_BACKUPS" "monthly"
else
    echo "[ERROR] No monthly backups found"
    send_alert "No monthly backups found"
fi

# RTOs de ambos casos para dar una idea del tiempo que se puede esperar

echo "[4] RTO simulation test..."

if [ -n "$DAILY_BACKUP" ]; then
    echo "Simulating DAILY restore timing..."
    START_TIME=$(date +%s)

    # Restauración del snapshot (copia completa)
    rsync -a "$DAILY_BACKUP/" "$TEST_DIR/daily_restore/"

    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    echo "[OK] DAILY restore simulation completed in ${DURATION}s"
fi

if [ -n "$WEEKLY_BACKUPS" ]; then
    echo "Simulating WEEKLY restore timing..."
    START_TIME=$(date +%s)

    time tar --acls --xattrs -xzf "$WEEKLY_BACKUPS" -C "$TEST_DIR"

    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    echo "[OK] WEEKLY restore simulation completed in ${DURATION}s"
fi

# Limpieza del directorio de testing (se comprueba de todos modos al principio de cada test)

echo "[5] Cleaning test environment..."
rm -rf "$TEST_DIR"

echo "Total errors detected: $ERRORS"

if [ "$ERRORS" -gt 0 ]; then
    echo "[FINAL STATUS] FAIL"

    # Envío por correo de alerta
    if command -v mail >/dev/null 2>&1; then
        echo "Backup test FAILED on $HOSTNAME with $ERRORS errors" | mail -s "Backup Alert" "$ALERT_EMAIL"
    fi
else
    echo "[FINAL STATUS] SUCCESS"
fi

echo "================================================================================"
echo "========================   END OF BACKUP TEST   ================================"
echo "================================================================================"
echo ""
echo ""
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