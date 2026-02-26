#!/bin/bash

read -p "Introdueix la IP del servidor: " host_ip

if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    echo "[INFO] No s'ha trobat cap clau SSH. Creant una nova clau SSH..."
    read -sp "[*] Introdueix una contrasenya per protegir la clau SSH (deixa-ho en blanc per no utilitzar contrasenya): " ssh_passphrase
    ssh-keygen -t ed25519 -C "$USER@$host_ip" -f "$HOME/.ssh/id_ed25519" -N "$ssh_passphrase"
else
    echo "[INFO] Ja existeix una clau SSH a $HOME/.ssh/id_ed25519. Utilitzant aquesta clau."
fi

echo "[INFO] Copiant la clau SSH pública al servidor remot..."
read -p "Introdueix el nom d'usuari remot per copiar la clau SSH: " remote_user

if ssh-copy-id -o "StrictHostKeyChecking=accept-new" -i ~/.ssh/id_ed25519.pub $remote_user@$host_ip; then
    echo "[OK] Clau SSH copiada correctament a $remote_user@$host_ip."
else
    echo "[ERROR] No s'ha pogut copiar la clau SSH a $remote_user@$host_ip. Comprova les credencials i la connexió de xarxa."
fi