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