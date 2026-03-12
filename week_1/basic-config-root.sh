#!/bin/bash

add_user() {
    if id "$1" &>/dev/null; then
        echo "[!] L'usuari $1 ja existeix."
    else
        echo "[INFO] Creant usuari $1..."
        useradd -m -s /bin/bash "$1"
        echo "$1:milax" | chpasswd
        chage -d 0 "$1"

        echo "[INFO] Afegint $1 al grup sudo..."
        usermod -aG sudo "$1"

        echo "[OK] Usuari $1 creat correctament."
    fi
}

install_if_missing() {
    if ! dpkg -l | grep -q "^ii  $1 "; then
        echo "[INFO] Instal·lant $1..."
        apt install -y "$1"
    else
        echo "[OK] $1 ja està instal·lat."
    fi
}

USERS=("eusebiu" "alex")

echo "[INFO] Configurant usuaris..."

for user in "${USERS[@]}"; do
    add_user "$user"
done

for user_dir in /home/*; do
    [ -d "$user_dir" ] || continue # Si no és un directori, ignora'l
    
    username=$(basename "$user_dir")
    is_allowed=false
    
    # Comprovem si l'usuari del directori està a la llista d'autoritzats
    for allowed in "${USERS[@]}"; do
        if [[ "$username" == "$allowed" ]]; then
            is_allowed=true
            break
        fi
    done
    
    # Si no està autoritzat, l'esborrem
    if [ "$is_allowed" = false ]; then
        echo "[INFO] Esborrant usuari sobrant: $username..."
        
        # Matem processos restants de l'usuari per si de cas
        pkill -u "$username" 2>/dev/null
        
        # L'esborrem amb la seva carpeta personal
        deluser --remove-home "$username" && echo "[OK] Usuari $username eliminat." || echo "[!] Error eliminant $username."
    fi
done

echo "[INFO] Actualitzant repositoris..."
apt update

echo "[INFO] Actualitzant paquets instal·lats..."
apt upgrade -y

echo "[INFO] Instal·lant paquets necessaris..."

PACKAGES=("sudo" "git" "openssh-server" "unattended-upgrades" "apt-listchanges")

for package in "${PACKAGES[@]}"; do
    install_if_missing "$package"
done

echo "[INFO] Configuració inicial del servei SSH..."

echo "[INFO] Canviant el port de SSH a 2222..."
sed -i 's/^#\?Port .*/Port 2222/' /etc/ssh/sshd_config

echo "[INFO] Deshabilitant l'accés directe de root a SSH..."
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

systemctl enable ssh
systemctl restart ssh

echo "[OK] Configuració de SSH completada."

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
