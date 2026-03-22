#!/bin/bash

# ==============================================================================
# SCRIPT DE CONFIGURACIÓ DE SERVEIS I SEGURETAT SSH PER CLAU PÚBLICA
# Objectiu: Instal·lar el servidor web i desactivar l'accés per contrasenya si hi ha claus.
# ==============================================================================

# Comprova si un paquet està instal·lat abans d'intentar la instal·lació
install_if_missing() {
    if ! dpkg -l | grep -q "^ii  $1 "; then
        echo "[INFO] Instal·lant $1..."
        sudo apt install -y "$1"
    else
        echo "[OK] $1 ja està instal·lat."
    fi
}

# Actualització de l'índex de paquets per assegurar la versió més recent
echo "[*] Actualitzant repositoris..."
sudo apt update

# Llistat de paquests que necessitem instal·lar en el servidor
PACKAGES=("nginx")
echo "[*] Instal·lant paquets necessaris..."
for package in "${PACKAGES[@]}"; do
    install_if_missing "$package"
done

# Només desactivem contrasenyes si l'usuari té una clau configurada
# L'opció -s comprova si el fitxer existeix i té una mida superior a zero
if [ -s "$HOME/.ssh/authorized_keys" ]; then
    echo "[INFO] Ja tenim almenos una clau SSH autoritzada a $HOME/.ssh/authorized_keys."
    echo "[INFO] Deshabilitant l'autenticació per contrasenya a SSH..."
    
    # Modifiquem la configuració per forçar l'ús de claus privades (més segur que contrasenyes)
    sudo sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    # Reiniciem el servei per aplicar el canvi de seguretat
    sudo systemctl restart ssh
else
    # Si no hi ha claus, no desactivem les contrasenyes o perdrem l'accés
    echo "[INFO] No s'ha trobat cap clau SSH autoritzada a $HOME/.ssh/authorized_keys."
    echo "[INFO] No podem deshabilitar l'autenticació per contrasenya a SSH fins que no tinguem almenys una clau SSH autoritzada."
fi