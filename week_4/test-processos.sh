#!/bin/bash
trap 'builtin kill $(jobs -p) 2>/dev/null' EXIT

echo -e "\n[TEST] Comprovant límit de processos de PAM..."
count=0
# Fem un bucle prou gran per superar qualsevol límit normal
for i in {1..2000}; do
    sleep 100 & 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "    -> [OK] PAM ha bloquejat la creació al procés nº: $i"
        break
    fi
    count=$i
    echo -ne "    ... creats: $count\r"
    sleep 0.02
done