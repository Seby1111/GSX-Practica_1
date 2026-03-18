#!/bin/bash

echo "====================================================="
echo "[*] VERIFICACIÓ DE LÍMITS (Usuari: $(whoami))"
echo "====================================================="

# 1. MOSTRAR LÍMITS ACTUALS
echo -e "\n[INFO] Límits actius (Soft):"
ulimit -Sa | grep -E "processes|open files|cpu time|virtual memory"

# 2. TEST DE PROCESSOS (NPROC)
echo -e "\n[INFO] Provant límit de processos (nproc)..."
(
    count=0
    while [ $count -lt 500 ]; do
        sleep 100 & 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "    -> [OK] Límit assolit a la xifra: $count"
            break
        fi
        count=$((count + 1))
    done
    kill $(jobs -p) 2>/dev/null
)

# 3. TEST DE FITXERS OBERTS (NOFILE)
echo -e "\n[INFO] Provant límit de fitxers oberts (nofile)..."
(
    count=0
    for i in {1..2048}; do
        exec {fd}> /dev/null 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "    -> [OK] El sistema ha bloquejat l'obertura al fitxer nº: $i"
            break
        fi
        count=$i
    done
)

# 4. TEST DE MEMÒRIA (AS)
echo -e "\n[INFO] Provant límit de memòria (Address Space)..."
(
    # Intentem reservar 2.1GB
    var=$(head -c 2100M /dev/zero 2>/dev/null) 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "    -> [OK] Memòria restringida correctament."
    fi
)

echo -e "\n====================================================="
echo "[*] VERIFICACIÓ FINALITZADA"
echo "====================================================="