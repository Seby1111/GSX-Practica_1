#!/bin/bash

# ==============================================================================
# SCRIPT D'ANÀLISI DE JERARQUIA
# Objectiu: Visualitzar l'arbre genealògic d'un procés per PID o nom.
# ==============================================================================

TARGET=$1

# Validació d'entrada: L'usuari ha de proporcionar un argument
if [ -z "$TARGET" ]; then
    echo "Ús: $0 <PID|nom_proces>"
    exit 1
fi

# Comprovem si l'entrada és un número (PID) o un text (Nom)
if [[ "$TARGET" =~ ^[0-9]+$ ]]; then
    PID=$TARGET
    # Verifiquem si el PID existeix realment al sistema
    NAME=$(ps -p "$PID" -o comm= 2>/dev/null)

    if [ -z "$NAME" ]; then
        echo "Error: El PID $PID no existeix al sistema."
        exit 1
    fi
else
    # Si és un nom, busquem el PID del procés que més CPU/MEM estigui consumint amb aquest nom
    PID=$(ps -eo pid,%cpu,%mem,comm --sort=-%cpu,-%mem | grep -w "$TARGET" | head -n 1 | awk '{print $1}') 
    NAME=$TARGET   
fi

# Comprovem que el PID obtingut és vàlid
if [ -z "$PID" ] || [ -z "$(ps -p "$PID" -o comm= 2>/dev/null)" ]; then
    echo "Error: No s'ha trobat cap procés actiu per '$TARGET'."
    exit 1
fi

echo "=========================================================="
echo "   JERARQUIA DEL PROCÉS: $NAME (PID: $PID)"
echo "=========================================================="

# -p: Mostra els PIDs de cada branca
# -a: Mostra els arguments de la línia de comandes
# -s: Mostra els ancestres (els "pares" fins arribar a systemd/init)
if ! pstree -pas "$PID"; then
    echo "Error: No s'ha pogut generar l'arbre per al PID $PID."
    exit 1
fi

echo "=========================================================="
