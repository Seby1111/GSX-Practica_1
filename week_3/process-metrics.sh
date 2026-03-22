#!/bin/bash

# ==============================================================================
# SCRIPT D'EXTRACCIÓ DE MÈTRIQUES AVANÇADES
# Objectiu: Analitzar l'estat intern d'un procés (RAM, I/O, CPU i fitxers oberts).
# ==============================================================================

TARGET=$1

# Validació d'entrada
if [ -z "$TARGET" ]; then
    echo "Ús: $0 <PID|nom_proces>"
    exit 1
fi

# Comprovem si l'entrada és un número (PID) o un text (Nom)
if [[ "$TARGET" =~ ^[0-9]+$ ]]; then
    PID=$TARGET
    # Verifiquem si el PID existeix realment al sistema
    NAME=$(ps -p "$PID" -o comm= 2>/dev/null)
else
    # Si és un nom, busquem el PID del procés que més CPU/MEM estigui consumint amb aquest nom
    PID=$(ps -eo pid,%cpu,%mem,comm --sort=-%cpu,-%mem | grep -w "$TARGET" | head -n 1 | awk '{print $1}')
    NAME=$TARGET
fi

# Comprovació de l'existència del directori en el sistema /proc
if [ -z "$PID" ] || [ ! -d "/proc/$PID" ]; then
    echo "Error: El procés '$TARGET' no existeix o no és accessible."
    exit 1
fi

echo "=========================================================="
echo "   MÈTRIQUES DEL PROCÉS: $TARGET (PID: $PID)"
echo "=========================================================="
echo ""

# Extracció de dades del fitxer 'status'
# VmRSS indica la memòria RAM real que el procés està ocupant ara mateix
echo "[1] ESTAT I MEMÒRIA REAL (RAM):"
if [ -r "/proc/$PID/status" ]; then
    grep -E "State|PPid|VmRSS|Threads|voluntary_ctxt_switches" "/proc/$PID/status" | sed 's/\t/ /g' | sed 's/^/  /'
else
    echo "  [!] Error: No es pot llegir 'status'. Prova amb 'sudo'."
fi

# Temps que fa que el procés corre
echo -e "\n[2] TEMPS D'ACTIVITAT (CPU Uptime):"
UPTIME=$(ps -p "$PID" -o etime= 2>/dev/null)
if [ -n "$UPTIME" ]; then
    echo "  Temps actiu: $UPTIME (Format: [[DD-]hh:]mm:ss)"
else
    echo "  [!] No s'ha pogut obtenir el temps d'activitat."
fi

# Quina càrrega de lectura/escriptura genera al disc
echo -e "\n[3] IMPACTE EN DISC (I/O):"
if [ -r "/proc/$PID/io" ]; then
    awk '{printf "  %-20s %s KB\n", $1, $2/1024}' "/proc/$PID/io" | head -n 4
else
    echo "  [!] Permís denegat per llegir I/O. Executa amb 'sudo' per veure dades de disc."
fi

# Comprovar si el procés està a punt de col·lapsar per massa fitxers oberts
echo -e "\n[4] LÍMITS DEL SISTEMA:"
if [ -d "/proc/$PID/fd" ]; then
    ACTUAL=$(ls /proc/$PID/fd | wc -l) # Fitxers (file descriptors) oberts actualment
    LIMIT=$(grep "Max open files" "/proc/$PID/limits" | awk '{print $4}') # Límit permes pel kernel
    
    echo "  Fitxers oberts actualment: $ACTUAL"
    echo "  Límit màxim permès (Soft): $LIMIT"
    
    # Una miqueta de lògica per avisar si estem a prop del límit
    PERCENTAGE=$((ACTUAL * 100 / LIMIT))
    echo "  Ús del límit: $PERCENTAGE%"
else
    echo "  [!] Permís denegat per comptar fitxers oberts. Prova amb 'sudo'."
fi

# Línia de comandes exacta que va llançar el procés
echo -e "\n[5] COMANDA COMPLETA D'EXECUCIÓ:"
if [ -r "/proc/$PID/cmdline" ]; then
    # El fitxer cmdline usa caràcters nuls \0 per separar arguments; els canviem per espais
    CMD=$(tr '\0' ' ' < "/proc/$PID/cmdline")
    if [ -z "$CMD" ]; then echo "  (No disponible)"; else echo "  $CMD"; fi
else
    echo "  [!] Permís denegat. Prova amb 'sudo'."
fi

echo ""
echo "=========================================================="