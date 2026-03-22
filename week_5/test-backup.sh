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
    if tar -tzf "$FILE" > /dev/null 2>&1; then
        echo "[OK] Archive integrity in order"
    else
        echo "[ERROR] Corrupted archive"
        send_alert "Corrupted $NAME backup on $HOSTNAME"
    fi

    # Restaurar en subdir (carpeta temporal para test)
    local DEST="$TEST_DIR/$NAME"
    mkdir -p "$DEST"

    tar -xzf "$FILE" -C "$DEST"

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
    PERM_BIN=$(stat -c "%a" "$GDC_BASE/bin" 2>/dev/null || echo "000")
    if [ "$PERM_BIN" != "750" ]; then
        echo "[ERROR] Wrong permissions on bin ($PERM_BIN)"
        send_alert "Bad permissions on bin"
    else
        echo "[OK] bin permissions correct"
    fi

    # Verificación de permisos shared (3770)
    PERM_SHARED=$(stat -c "%a" "$GDC_BASE/shared" 2>/dev/null || echo "000")
    if [ "$PERM_SHARED" != "3770" ]; then
        echo "[ERROR] Wrong permissions on shared ($PERM_SHARED)"
        send_alert "Bad permissions on shared"
    else
        echo "[OK] shared permissions correct"
    fi

    # Verificación done.log (644)
    PERM_LOG=$(stat -c "%a" "$GDC_BASE/done.log" 2>/dev/null || echo "000")
    if [ "$PERM_LOG" != "644" ]; then
        echo "[ERROR] Wrong permissions on done.log ($PERM_LOG)"
        send_alert "Bad permissions on done.log"
    else
        echo "[OK] done.log permissions correct"
    fi
}

#Busca el más reciente de cada tipo y los testea (ls -t | head -n 1)

echo "[1] Testing DAILY backups..."

# Alternativa más segura a ls
DAILY_BACKUPS=$(find "$BACKUP_DIR/daily" -type f -name "backup-*.tar.gz" -printf "%T@ %p\n" 2>/dev/null | sort -nr | head -n 1 | cut -d' ' -f2-)

if [ -n "$DAILY_BACKUPS" ]; then
    test_tar_backup "$DAILY_BACKUPS" "daily"
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

echo "[4] Testing FULL backups..."

FULL_BACKUP=$(find "$BACKUP_DIR/full" -type f -name "backup-*.tar.gz" -printf "%T@ %p\n" 2>/dev/null | sort -nr | head -n 1 | cut -d' ' -f2-)

if [ -n "$FULL_BACKUP" ]; then
    test_tar_backup "$FULL_BACKUP" "full"
else
    echo "[ERROR] No full backups found"
    send_alert "No full backups found"
fi

# No los restaura, solo comprueba que existan, si hay directios -> OK, de lo contrario -> ERROR

echo "[5] Testing INCREMENTAL backups..."

INC_DIR="$BACKUP_DIR/incremental"

if [ -d "$INC_DIR" ]; then
    COUNT=$(find "$INC_DIR" -type d | wc -l)
    echo "Incremental directories found: $COUNT"

    if [ "$COUNT" -gt 1 ]; then
        echo "[OK] Incremental backups exist"

        # Test básico encadenado
        echo "Testing incremental chain..."
        find "$INC_DIR" -type f -name "*.tar.gz" | while read f; do
            if tar -tzf "$f" > /dev/null 2>&1; then
                echo "[OK] Incremental archive OK -> $f"
            else
                echo "[ERROR] Corrupted incremental -> $f"
                send_alert "Corrupted incremental backup: $f"
            fi
        done

    else
        echo "[ERROR] No incremental backups"
        send_alert "No incremental backups"
    fi
else
    echo "[ERROR] Incremental directory missing"
    send_alert "Incremental directory missing"
fi

# RTO del caso más lento (Full Backup Restoration) para dar una idea del tiempo que se puede esperar

echo "[6] RTO simulation test..."

if [ -n "$FULL_BACKUP" ]; then
    echo "Simulating restore timing..."
    START_TIME=$(date +%s)

    time tar -xzf "$FULL_BACKUP" -C "$TEST_DIR"

    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    echo "[OK] Restore simulation completed in ${DURATION}s"
fi

# Limpieza del directorio de testing (se comprueba de todos modos al principio de cada test)

echo "[7] Cleaning test environment..."
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