#!/bin/bash

# Comprovem si l'script s'executa com a root
if [[ $EUID -ne 0 ]]; then
   echo "[!] Aquest script s'ha d'executar com a root (fent servir sudo)."
   exit 1
fi

# Variables (ajusta segons el teu entorn)
BACKUP_DIR="/var/backups"
TEST_DIR="/tmp/restore-test"

LOG_FILE="/var/log/backup-test.log"

# Configuració d'alertes
ALERT_EMAIL="alexandru-ciprian.radu@estudiants.urv.cat"
HOSTNAME=$(hostname)

# Control d'errors
ERRORS=0

# Redirigir sortida al log
exec >> "$LOG_FILE" 2>&1

echo "================================================================================"
echo "========================  INICI DEL TEST DE BACKUP  ============================"
echo "================================================================================"

echo ""
echo "Inici a: $(date)"

# Netejar entorn
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

# Funció d'alerta
send_alert () {
    local MSG=$1
    echo "[ALERTA] $MSG"
    let ERRORS=$ERRORS+1
}

test_tar_backup () {
    local FILE=$1
    local NAME=$2

    echo "[TEST] $NAME -> $FILE"

    # Comprovar que el fitxer existeix
    if [ ! -f "$FILE" ]; then
        echo "[ERROR] Falta el backup $NAME"
        send_alert "Falta backup $NAME a $HOSTNAME"
    fi

    # Verificar integritat
    if tar --acls --xattrs -tzf "$FILE" > /dev/null 2>&1; then
        echo "[OK] Integritat de l'arxiu correcta"
    else
        echo "[ERROR] Arxiu corrupte"
        send_alert "Backup $NAME corrupte a $HOSTNAME"
    fi

    # Restaurar en subdirectori (carpeta temporal per test)
    local DEST="$TEST_DIR/$NAME"
    mkdir -p "$DEST"

    tar --acls --xattrs -xzf "$FILE" -C "$DEST"

    # Verificació bàsica
    if [ -d "$DEST/etc" ] && [ -d "$DEST/home" ]; then
        echo "[OK] Estructura correcta per $NAME"
    else
        echo "[ERROR] Falten directoris crítics a $NAME"
        send_alert "Error d'estructura en backup $NAME"
    fi

    # Verificació de contingut real (mínimament)
    if [ -f "$DEST/etc/passwd" ]; then
        echo "[OK] Fitxer crític existent (/etc/passwd)"
    else
        echo "[ERROR] Falta /etc/passwd"
        send_alert "Falta passwd en backup $NAME"
    fi

    # Verificació estructura greendevcorp
    GDC_BASE="$DEST/home/greendevcorp"

    if [ -d "$GDC_BASE" ]; then
        echo "[OK] Directori greendevcorp existeix"
    else
        echo "[ERROR] Falta /home/greendevcorp"
        send_alert "Falta directori greendevcorp"
    fi

    # Verificar subdirectoris
    if [ -d "$GDC_BASE/bin" ] && [ -d "$GDC_BASE/shared" ]; then
        echo "[OK] Estructura de greendevcorp correcta"
    else
        echo "[ERROR] Falten bin o shared"
        send_alert "Error d'estructura en greendevcorp"
    fi

    # Verificar fitxer done.log
    if [ -f "$GDC_BASE/done.log" ]; then
        echo "[OK] done.log existeix"
    else
        echo "[ERROR] Falta done.log"
        send_alert "Falta done.log"
    fi

    # Verificació de permisos bin (750)
    PERM_BIN=$(permisos "$GDC_BASE/bin" 2>/dev/null || echo "000")
    if [ "$PERM_BIN" != "750" ]; then
        echo "[ERROR] Permisos incorrectes en bin ($PERM_BIN)"
        send_alert "Permisos incorrectes en bin"
    else
        echo "[OK] Permisos de bin correctes"
    fi

    # Verificació de permisos shared (3770)
    PERM_SHARED=$(stat -c %a "$GDC_BASE/shared" 2>/dev/null || echo "000")
    if [ "$PERM_SHARED" != "3770" ]; then
        echo "[ERROR] Permisos incorrectes en shared ($PERM_SHARED)"
        send_alert "Permisos incorrectes en shared"
    else
        echo "[OK] Permisos de shared correctes"
    fi

    # Verificació done.log (644)
    PERM_LOG=$(permisos "$GDC_BASE/done.log" 2>/dev/null || echo "000")
    if [ "$PERM_LOG" != "644" ]; then
        echo "[ERROR] Permisos incorrectes en done.log ($PERM_LOG)"
        send_alert "Permisos incorrectes en done.log"
    else
        echo "[OK] Permisos de done.log correctes"
    fi
}

# El mateix que la funció anterior però adaptat per als snapshots incrementals de DAILY
test_snapshot_backup () {
    local DIR=$1
    local NAME=$2

    echo "[TEST] $NAME -> $DIR"

    # Comprovar que el directori existeix
    if [ ! -d "$DIR" ]; then
        echo "[ERROR] Falta snapshot $NAME"
        send_alert "Falta snapshot $NAME a $HOSTNAME"
        return
    fi

    # Verificació bàsica d'estructura
    if [ -d "$DIR/etc" ] && [ -d "$DIR/home" ]; then
        echo "[OK] Estructura correcta per $NAME"
    else
        echo "[ERROR] Falten directoris crítics a $NAME"
        send_alert "Error d'estructura en snapshot $NAME"
    fi

    # Verificació de contingut real
    if [ -f "$DIR/etc/passwd" ]; then
        echo "[OK] Fitxer crític existent (/etc/passwd)"
    else
        echo "[ERROR] Falta /etc/passwd"
        send_alert "Falta passwd en snapshot $NAME"
    fi

    # Verificació estructura greendevcorp
    GDC_BASE="$DIR/home/greendevcorp"

    if [ -d "$GDC_BASE" ]; then
        echo "[OK] Directori greendevcorp existeix"
    else
        echo "[ERROR] Falta /home/greendevcorp"
        send_alert "Falta directori greendevcorp"
        return
    fi

    # Verificar subdirectoris
    if [ -d "$GDC_BASE/bin" ] && [ -d "$GDC_BASE/shared" ]; then
        echo "[OK] Estructura de greendevcorp correcta"
    else
        echo "[ERROR] Falten bin o shared"
        send_alert "Error d'estructura en greendevcorp"
    fi

    # Verificar fitxer done.log
    if [ -f "$GDC_BASE/done.log" ]; then
        echo "[OK] done.log existeix"
    else
        echo "[ERROR] Falta done.log"
        send_alert "Falta done.log"
    fi

    # Verificació de permisos bin (750) en format octal (%a)
    PERM_BIN=$(permisos "$GDC_BASE/bin" 2>/dev/null || echo "000")
    if [ "$PERM_BIN" != "750" ]; then
        echo "[ERROR] Permisos incorrectes en bin ($PERM_BIN)"
        send_alert "Permisos incorrectes en bin"
    else
        echo "[OK] Permisos de bin correctes"
    fi

    # Verificació de permisos shared (3770)
    PERM_SHARED=$(stat -c %a "$GDC_BASE/shared" 2>/dev/null || echo "000")
    if [ "$PERM_SHARED" != "3770" ]; then
        echo "[ERROR] Permisos incorrectes en shared ($PERM_SHARED)"
        send_alert "Permisos incorrectes en shared"
    else
        echo "[OK] Permisos de shared correctes"
    fi

    # Verificació done.log (644)
    PERM_LOG=$(permisos "$GDC_BASE/done.log" 2>/dev/null || echo "000")
    if [ "$PERM_LOG" != "644" ]; then
        echo "[ERROR] Permisos incorrectes en done.log ($PERM_LOG)"
        send_alert "Permisos incorrectes en done.log"
    else
        echo "[OK] Permisos de done.log correctes"
    fi

    # Verificació avançada: comparació real contra sistema original (checksum)
    echo "[CHECK] Verificant consistència del snapshot amb la font (checksum diff)..."

    if rsync -avnc --delete /etc/ "$DIR/etc/" > /dev/null 2>&1; then
        echo "[OK] /etc coincideix amb la font (checksum)"
    else
        echo "[ERROR] Diferències trobades a /etc"
        send_alert "Desajust de checksum a /etc per $NAME"
    fi

    if rsync -avnc --delete /home/greendevcorp/ "$DIR/home/greendevcorp/" > /dev/null 2>&1; then
        echo "[OK] /home/greendevcorp coincideix amb la font (checksum)"
    else
        echo "[ERROR] Diferències trobades a /home/greendevcorp"
        send_alert "Desajust de checksum a greendevcorp per $NAME"
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

echo "[1] Provant backups DAILY..."

DAILY_BACKUP=$(find "$BACKUP_DIR/daily" -mindepth 1 -maxdepth 1 -type d -printf "%T@ %p\n" 2>/dev/null | sort -nr | head -n 1 | cut -d' ' -f2-)

if [ -n "$DAILY_BACKUP" ]; then
    test_snapshot_backup "$DAILY_BACKUP" "daily"
else
    echo "[ERROR] No s'han trobat backups daily"
    send_alert "No s'han trobat backups daily"
fi

echo "[2] Provant backups WEEKLY..."

WEEKLY_BACKUPS=$(find "$BACKUP_DIR/weekly" -type f -name "backup-weekly-*.tar.gz" -printf "%T@ %p\n" 2>/dev/null | sort -nr | head -n 1 | cut -d' ' -f2-)

if [ -n "$WEEKLY_BACKUPS" ]; then
    test_tar_backup "$WEEKLY_BACKUPS" "weekly"
else
    echo "[ERROR] No s'han trobat backups weekly"
    send_alert "No s'han trobat backups weekly"
fi

echo "[3] Provant backups MONTHLY..."

MONTHLY_BACKUPS=$(find "$BACKUP_DIR/monthly" -type f -name "backup-monthly-*.tar.gz" -printf "%T@ %p\n" 2>/dev/null | sort -nr | head -n 1 | cut -d' ' -f2-)

if [ -n "$MONTHLY_BACKUPS" ]; then
    test_tar_backup "$MONTHLY_BACKUPS" "monthly"
else
    echo "[ERROR] No s'han trobat backups monthly"
    send_alert "No s'han trobat backups monthly"
fi

echo "[4] Test RTO..."

if [ -n "$DAILY_BACKUP" ]; then
    echo "Simulant restauració DAILY..."
    START_TIME=$(date +%s)

    # Restauració del snapshot (còpia completa)
    rsync -a "$DAILY_BACKUP/" "$TEST_DIR/daily_restore/"

    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    echo "[OK] Restauració DAILY completada en ${DURATION}s"
fi

if [ -n "$WEEKLY_BACKUPS" ]; then
    echo "Simulant restauració WEEKLY..."
    START_TIME=$(date +%s)

    time tar --acls --xattrs -xzf "$WEEKLY_BACKUPS" -C "$TEST_DIR"

    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    echo "[OK] Restauració WEEKLY completada en ${DURATION}s"
fi

echo "[5] Netejant entorn de test..."
rm -rf "$TEST_DIR"

echo "Errors totals detectats: $ERRORS"

if [ "$ERRORS" -gt 0 ]; then
    echo "[ESTAT FINAL] FALLADA"

    # Enviament per correu d'alerta
    if command -v mail >/dev/null 2>&1; then
        echo "El test de backup HA FALLAT a $HOSTNAME amb $ERRORS errors" | mail -s "Alerta Backup" "$ALERT_EMAIL"
    fi
else
    echo "[ESTAT FINAL] ÈXIT"
fi

echo "================================================================================"
echo "========================   FINAL DEL TEST DE BACKUP   =========================="
echo "================================================================================"
echo ""
echo ""