#!/bin/bash

TARGET=$1

if [ -z "$TARGET" ]; then
    echo "Ús: $0 <PID|nom_proces>"
    exit 1
fi
if [[ "$TARGET" =~ ^[0-9]+$ ]]; then
    PID=$TARGET
    NAME=$(ps -p "$PID" -o comm= 2>/dev/null)
else
    PID=$(ps -eo pid,%cpu,%mem,comm --sort=-%cpu,-%mem | grep -w "$TARGET" | head -n 1 | awk '{print $1}')
    NAME=$TARGET
fi

if [ -z "$PID" ] || [ ! -d "/proc/$PID" ]; then
    echo "Error: El procés '$TARGET' no existeix o no és accessible."
    exit 1
fi

echo "=========================================================="
echo "   MÈTRIQUES DEL PROCÉS: $TARGET (PID: $PID)"
echo "=========================================================="
echo ""

echo "[1] ESTAT I MEMÒRIA REAL (RAM):"
if [ -r "/proc/$PID/status" ]; then
    grep -E "State|PPid|VmRSS|Threads|voluntary_ctxt_switches" "/proc/$PID/status" | sed 's/\t/ /g' | sed 's/^/  /'
else
    echo "  [!] Error: No es pot llegir 'status'. Prova amb 'sudo'."
fi

echo -e "\n[2] TEMPS D'ACTIVITAT (CPU Uptime):"
UPTIME=$(ps -p "$PID" -o etime= 2>/dev/null)
if [ -n "$UPTIME" ]; then
    echo "  Temps actiu: $UPTIME (Format: [[DD-]hh:]mm:ss)"
else
    echo "  [!] No s'ha pogut obtenir el temps d'activitat."
fi

echo -e "\n[3] IMPACTE EN DISC (I/O):"
if [ -r "/proc/$PID/io" ]; then
    awk '{printf "  %-20s %s KB\n", $1, $2/1024}' "/proc/$PID/io" | head -n 4
else
    echo "  [!] Permís denegat per llegir I/O. Executa amb 'sudo' per veure dades de disc."
fi

echo -e "\n[4] LÍMITS DEL SISTEMA:"
if [ -d "/proc/$PID/fd" ]; then
    # Comptem quants fitxers hi ha a la carpeta fd
    ACTUAL=$(ls /proc/$PID/fd | wc -l)
    
    # Busquem el límit màxim (Soft Limit)
    LIMIT=$(grep "Max open files" "/proc/$PID/limits" | awk '{print $4}')
    
    echo "  Fitxers oberts actualment: $ACTUAL"
    echo "  Límit màxim permès (Soft): $LIMIT"
    
    # Una miqueta de lògica per avisar si estem a prop del límit
    PERCENTAGE=$((ACTUAL * 100 / LIMIT))
    echo "  Ús del límit: $PERCENTAGE%"
else
    echo "  [!] Permís denegat per comptar fitxers oberts. Prova amb 'sudo'."
fi

echo -e "\n[5] COMANDA COMPLETA D'EXECUCIÓ:"
if [ -r "/proc/$PID/cmdline" ]; then
    CMD=$(tr '\0' ' ' < "/proc/$PID/cmdline")
    if [ -z "$CMD" ]; then echo "  (No disponible)"; else echo "  $CMD"; fi
else
    echo "  [!] Permís denegat. Prova amb 'sudo'."
fi

echo ""
echo "=========================================================="