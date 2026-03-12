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

# Comprova si Nginx se reinicia automàticament en cas de fallada i, si no ho fa, afegeix la clausula "Restart=always" en l'apartat de [Service] del fitxer de servei de Nginx.
if ! [ cat /lib/systemd/system/nginx.service | grep -q "Restart=always" ]; then
    echo "[!] Nginx no té Restart=always. Afegint..."
    sudo sed -i '/\[Service\]/a Restart=always' /lib/systemd/system/nginx.service
    sudo systemctl daemon-reload
    sudo systemctl restart nginx.service
fi