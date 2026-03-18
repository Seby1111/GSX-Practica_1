#!/bin/bash
echo -e "\n[TEST] Comprovant límit de fitxers de PAM..."
fds=()
for i in {1..4000}; do
    if exec {fd}> /dev/null 2>/dev/null; then
        fds+=($fd)
    else
        echo "    -> [OK] PAM ha bloquejat l'obertura al fitxer nº: $i"
        break
    fi
done

# Tanquem els fitxers
for f in "${fds[@]}"; do exec {f}>&- 2>/dev/null; done