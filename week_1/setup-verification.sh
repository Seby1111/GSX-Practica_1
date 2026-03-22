#!/bin/bash

# ==============================================================================
# SCRIPT ORQUESTRADOR DE CONFIGURACIÓ
# Objectiu: Executar seqüencialment els scripts de configuració i verificar-ne l'èxit.
# ==============================================================================

# Definim l'ordre d'execució dels scripts en un array
# L'ordre és important: primer la base de root, després l'usuari i finalment l'estructura
SCRIPTS=("basic-config-root.sh" "basic-config-user.sh" "directory-structure.sh")

echo "[INFO] Iniciant verificació i re-aplicació de la configuració..."

for script in "${SCRIPTS[@]}"; do
    # Verificació d'existència: Evitem que l'orquestrador falli si falta un fitxer
    if [ ! -f "$script" ]; then
        echo "[ERROR] No s'ha trobat el fitxer: $script"
        continue
    fi

    # Assegurem que el script sigui executable abans de cridar-lo
    chmod +x "$script"

    echo "[INFO] Executant: $script"

    # Si el nom del script conté "root", l'executem amb sudo. Si no, com a usuari normal
    if [[ "$script" == *"root"* ]]; then
        echo "[*] Aquest script requereix privilegis d'administrador."
        sudo ./"$script"
    else
        ./"$script"
    fi

    # Comprovació del codi de sortida ($?):
    # 0 indica èxit, qualsevol altre número indica que alguna cosa ha fallat
    if [ $? -eq 0 ]; then
        echo "[OK] $script finalitzat correctament."
    else
        echo "[ALERTA] $script ha tornat un error."
    fi
done

echo "[FINAL] Verificació completada."