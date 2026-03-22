#!/bin/bash

# ==============================================================================
# SCRIPT DE POST-INSTAL·LACIÓ I CONFIGURACIÓ DE SEGURETAT
# Objectiu: Automatitzar la creació d'usuaris, gestió de paquets i hardening de SSH.
# ==============================================================================

# Verificació de privilegis: L'administració de sistema requereix root
if [[ $EUID -ne 0 ]]; then
   echo "[!] Aquest script s'ha d'executar com a root (fent servir sudo)."
   exit 1
fi

# Crea un usuari administrador
add_user() {
    # Comprovem si l'usuari ja existeix
    if id "$1" &>/dev/null; then
        echo "[!] L'usuari $1 ja existeix."
    else
        echo "[INFO] Creant usuari $1..."

        # Creem l'usuari amb shell bash
        useradd -m -s /bin/bash "$1"

        # Assignem 'milax' com a contrasenya per defecte
        echo "$1:milax" | chpasswd

        # Forcem el canvi de contrasenya al primer login
        chage -d 0 "$1"

        echo "[INFO] Afegint $1 al grup sudo..."

        # Afegim l'usuari al grup sudo (es administrador)
        usermod -aG sudo "$1"

        echo "[OK] Usuari $1 creat correctament."
    fi
}

# Comprova si un paquet està instal·lat abans d'intentar la instal·lació
install_if_missing() {
    if ! dpkg -l | grep -q "^ii  $1 "; then
        echo "[INFO] Instal·lant $1..."
        apt install -y "$1"
    else
        echo "[OK] $1 ja està instal·lat."
    fi
}

# Llistat dels usuaris administradors que s'afegiran
USERS=("eusebiu" "alex")
echo "[INFO] Configurant usuaris..."
for user in "${USERS[@]}"; do
    add_user "$user"
done

# Actualitzem el sistema
echo "[INFO] Actualitzant repositoris..."
apt update
echo "[INFO] Actualitzant paquets instal·lats..."
apt upgrade -y

# Llistat de paquets importants per a la configuració inicial del sistema
PACKAGES=("sudo" "git" "openssh-server" "unattended-upgrades" "apt-listchanges")
echo "[INFO] Instal·lant paquets necessaris..."
for package in "${PACKAGES[@]}"; do
    install_if_missing "$package"
done

# Hardening del servei ssh
echo "[INFO] Configuració inicial del servei SSH..."

# Canviem el port per defecte (22) per evitar atacs automatitzats de bots (seguretat per obscuritat)
echo "[INFO] Canviant el port de SSH a 2222..."
sed -i 's/^#\?Port .*/Port 2222/' /etc/ssh/sshd_config

# Bloquegem l'accés directe de root per SSH (principi de mínim privilegi)
echo "[INFO] Deshabilitant l'accés directe de root a SSH..."
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

systemctl enable ssh
systemctl restart ssh
echo "[OK] Configuració de SSH completada."

# Actualitzacions automàtiques
echo "[INFO] Activant actualitzacions de seguretat automàtiques..."

cat <<EOF > /etc/apt/apt.conf.d/50unattended-upgrades
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};

Unattended-Upgrade::Package-Blacklist {
};
EOF

cat <<EOF > /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

systemctl enable --now unattended-upgrades
echo "[OK] Actualitzacions de seguretat automàtiques activades."

echo "[OK] Configuració bàsica completada. Els usuaris creats són: ${USERS[*]}."
