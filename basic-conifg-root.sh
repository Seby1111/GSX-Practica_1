add_user() {
    if id "$1" &>/dev/null; then
        echo "[!] L'usuari $1 ja existeix."
    else
        echo "[INFO] Creant usuari $1..."
        useradd -m "$1"
        echo "$1:milax" | chpasswd
        change -d 0 "$1"

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

echo "[INFO] Actualitzant repositoris..."

apt update

echo "[INFO] Instal·lant paquets necessaris..."
PACKAGES=("sudo" "git" "openssh-server")

for package in "${PACKAGES[@]}"; do
    install_if_missing "$package"
done

echo "[INFO] Configuració inicial del servei SSH..."

echo "[INFO] Canviant el port de SSH a 2222..."
sed -i 's/.*Port 22.*/Port 2222/' /etc/ssh/sshd_config

echo "[INFO] Deshabilitant l'accés directe de root a SSH..."
sudo sed -i 's/.*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

systemctl enable ssh
systemctl restart ssh
