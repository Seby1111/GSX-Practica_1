#!/bin/bash

# Comprova si Nginx està configurat per a enviar les seves sortides estàndard al journal de systemd. Si no ho està, afegeix la clausula "StandardOutput=journal" a l'apartat de [Service].
if ! [ cat /lib/systemd/system/nginx.service | grep -q "StandardOutput=journal" ]; then
    echo "[!] Nginx no té StandardOutput=journal. Afegint..."
    sudo sed -i '/\[Service\]/a StandardOutput=journal' /lib/systemd/system/nginx.service
    sudo systemctl daemon-reload
    sudo systemctl restart nginx.service
fi

# Comprova si Nginx està configurat per a enviar les seves sortides d'error al journal de systemd. Si no ho està, afegeix la línia "StandardError=journal" a l'apartat de [Service].
if ! [ cat /lib/systemd/system/nginx.service | grep -q "StandardError=journal" ]; then
    echo "[!] Nginx no té StandardError=journal. Afegint..."
    sudo sed -i '/\[Service\]/a StandardError=journal' /lib/systemd/system/nginx.service
    sudo systemctl daemon-reload
    sudo systemctl restart nginx.service
fi