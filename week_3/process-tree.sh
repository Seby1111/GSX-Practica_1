#!/bin/bash

TARGET=$1

if [ -z "$TARGET" ]; then
    echo "Ús: $0 <PID|nom_proces>"
    exit 1
fi

if [[ "$TARGET" =~ ^[0-9]+$ ]]; then
    PID=$TARGET

    NAME=$(ps -p "$PID" -o comm= 2>/dev/null)

    if [ -z "$NAME" ]; then
        echo "Error: El PID $PID no existeix al sistema."
        exit 1
    fi
else
    PID=$(ps -eo pid,%cpu,%mem,comm --sort=-%cpu,-%mem | grep -w "$TARGET" | head -n 1 | awk '{print $1}') 
    NAME=$TARGET   
fi

if [ -z "$PID" ] || [ -z "$(ps -p "$PID" -o comm= 2>/dev/null)" ]; then
    echo "Error: No s'ha trobat cap procés actiu per '$TARGET'."
    exit 1
fi

echo "=========================================================="
echo "   JERARQUIA DEL PROCÉS: $NAME (PID: $PID)"
echo "=========================================================="

# -s: mostra els pares (ancestres), -p: PIDs, -a: arguments
if ! pstree -pas "$PID"; then
    echo "Error: No s'ha pogut generar l'arbre per al PID $PID."
    exit 1
fi

echo "=========================================================="
