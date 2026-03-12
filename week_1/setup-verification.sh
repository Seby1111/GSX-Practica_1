#!/bin/bash

SCRIPTS=("basic-config-root.sh" "basic-config-user.sh" "directory-structure.sh")

echo "[INFO] Iniciant verificació i re-aplicació de la configuració..."

for script in "${SCRIPTS[@]}"; do
    if [ ! -f "$script" ]; then
        echo "[ERROR] No s'ha trobat el fitxer: $script"
        continue
    fi

    chmod +x "$script"

    echo "[INFO] Executant: $script"

    if [[ "$script" == *"root"* ]]; then
        echo "[*] Aquest script requereix privilegis d'administrador."
        sudo ./"$script"
    else
        ./"$script"
    fi

    if [ $? -eq 0 ]; then
        echo "[OK] $script finalitzat correctament."
    else
        echo "[ALERTA] $script ha tornat un error."
    fi
done

echo "[FINAL] Verificació completada."