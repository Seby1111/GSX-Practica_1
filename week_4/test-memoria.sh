#!/bin/bash
echo -e "\n[TEST] Comprovant límit de memòria de PAM..."
mem_data=""
for i in {1..20}; do
    # Intentem afegir blocs de 100MB
    if chunk=$(printf '%104857600s' ' ' 2>/dev/null); then
        mem_data="${mem_data}${chunk}"
        echo "    ... Memòria en ús: $((i * 100)) MB"
    else
        echo "    -> [OK] PAM ha restringit la memòria correctament."
        break
    fi
done