#!/bin/bash

# Aquest script comprova si Nginx està actiu i habilitat, i si no ho està, el posa en marxa i l'habilita. També comprova si Nginx està instal·lat i, si no ho està, mostra un missatge d'error.
if [ sudo systemctl is-active nginx.service -eq 0 ]; then
    echo "[!] Nginx no està actiu. Activant..."
    sudo systemctl start nginx.service
else
    echo "[OK] Nginx està actiu."
fi

# Comprova si Nginx està habilitat i, si no ho està, l'habilita.
if [ sudo systemctl is-enabled nginx.service -eq 0 ]; then
    echo "[!] Nginx no està habilitat. Habilitant..."
    sudo systemctl enable nginx.service
else
    echo "[OK] Nginx està habilitat."
fi

if ! [ -x "$(command -v nginx)" ]; then
    echo "[!] Nginx no està instal·lat. Executa el script de configuració bàsica abans d'executar aquest script."
    exit 1
else
    echo "[OK] Nginx està instal·lat i actiu."
fi