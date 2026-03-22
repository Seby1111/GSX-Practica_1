#!/bin/bash

install_if_missing() {
    if ! dpkg -l | grep -q "^ii  $1 "; then
        echo "[INFO] Instal·lant $1..."
        sudo apt install -y "$1"
    else
        echo "[OK] $1 ja està instal·lat."
    fi
}

echo "[*] Actualitzant repositoris..."

sudo apt update

echo "[*] Instal·lant paquets necessaris..."

PACKAGES=("nginx" "rsync")

for package in "${PACKAGES[@]}"; do
    install_if_missing "$package"
done

if [ -s "$HOME/.ssh/authorized_keys" ]; then
    echo "[INFO] Ja tenim almenos una clau SSH autoritzada a $HOME/.ssh/authorized_keys."
    echo "[INFO] Deshabilitant l'autenticació per contrasenya a SSH..."
    sudo sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

    sudo systemctl restart ssh
else
    echo "[INFO] No s'ha trobat cap clau SSH autoritzada a $HOME/.ssh/authorized_keys."
    echo "[INFO] No podem deshabilitar l'autenticació per contrasenya a SSH fins que no tinguem almenys una clau SSH autoritzada."
fi