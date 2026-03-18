#!/bin/bash
# Script principal per validar la configuració de PAM

echo "====================================================="
echo "[*] VALIDACIÓ DE CONFIGURACIÓ PAM (Usuari: $USER)"
echo "====================================================="

# Mostrem els límits que PAM ha carregat al login
echo -e "\n[INFO] Límits detectats segons PAM:"
ulimit -Sa | grep -E "open files|max user processes|virtual memory|cpu time"

# Execució dels mòduls
chmod +x test-*.sh

./test-fitxers.sh
./test-memoria.sh
./test-processos.sh

echo -e "\n====================================================="
echo "[*] VERIFICACIÓ FINALITZADA"
echo "====================================================="

