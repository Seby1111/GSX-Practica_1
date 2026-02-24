#!/bin/bash

# Funció per comprovar si tenim sudo
check_sudo() {
    groups $1 | grep -q "\bsudo\b"
}

if ! check_sudo $USER; then
    echo "[!] L'usuari $USER no està al grup sudo."
    echo "[?] Introduïu la contrasenya de ROOT per afegir-lo:"
    
    # Utilitzem 'su' només per a aquesta acció específica
    su -c "apt update && apt install -y sudo && usermod -aG sudo $USER" root
    
    echo "[OK] Usuari afegit a sudoers."
    echo "[!] ATENCIÓ: Has de tancar la sessió ('exit')i tornar a entrar perquè els canvis s'apliquin. Un cop fet això, torna a executar aquest script per completar la instal·lació."
    exit 0
fi

echo "--- Iniciant instal·lació amb l'usuari: $USER ---"

# Funció d'instal·lació segura de paquets
install_if_missing() {
    if ! dpkg -l | grep -q "^ii  $1 "; then
        echo "[INFO] Instal·lant $1..."
        sudo apt install -y "$1"
    else
        echo "[OK] $1 ja està instal·lat."
    fi
}

sudo apt update
PACKAGES=("git" "openssh-server")

for package in "${PACKAGES[@]}"; do
    install_if_missing "$package"
done

# Gestió d'usuaris
while true; do
    read -p "[?] Vols afegir un nou usuari? (s/n): " add_user
    if [[ "$add_user" == "s" ]]; then
        read -p "Introdueix el nom del nou usuari: " new_user
        if id "$new_user" &>/dev/null; then
            echo "[!] L'usuari $new_user ja existeix."
        else
            sudo adduser "$new_user"
            echo "[OK] Usuari $new_user creat correctament."

            read -p "[?] Vols afegir $new_user al grup sudo? (s/n): " add_sudo
            if check_sudo "$new_user"; then
                echo "[INFO] $new_user ja té permisos de sudo."
            else
                sudo usermod -aG sudo "$new_user"
                echo "[OK] Afegit al grup sudo."
            fi
        fi
    elif [[ "$add_user" == "n" ]]; then
        echo "Finalitzant la gestió d'usuaris."
        break
    else
        echo "[!] Opció no vàlida. Intenta-ho de nou."
    fi
done

# Configuració del servei SSH 
sudo systemctl enable --now ssh

echo "[OK] Servei SSH habilitat i en execució."

while true; do
    read -p "[?] Vols afegir una clau SSH pública? (s/n): " add_ssh_key

    if [[ "$add_ssh_key" == "s" ]]; then
        read -p "A quin usuari vols afegir la clau? " target_user

        if ! id "$target_user" &>/dev/null; then
            echo "[!] L'usuari $target_user no existeix."
        else
            read -p "Introdueix la teva clau pública: " ssh_key

            if [[ -n "$ssh_key" && "$ssh_key" == ssh-* ]]; then
                # Validació: que no estigui buida i sembli una clau
                # Definim la ruta del home de l'usuari destí
                user_home=$(eval echo "~$target_user")
                ssh_dir="$user_home/.ssh"
                auth_file="$ssh_dir/authorized_keys"

                # 1. Creem el directori amb SUDO
                sudo mkdir -p "$ssh_dir"
                
                # 2. Afegim la clau (tee -a serveix per escriure com a sudo en un fitxer)
                if ! sudo grep -qF "$ssh_key" "$auth_file" 2>/dev/null; then
                    echo "$ssh_key" | sudo tee -a "$auth_file" > /dev/null
                    
                    # 3. LA PART CLAU: Canviem el propietari a l'usuari destí
                    sudo chown -R "$target_user":"$target_user" "$ssh_dir"
                    
                    # 4. Ajustem permisos de seguretat
                    sudo chmod 700 "$ssh_dir"
                    sudo chmod 600 "$auth_file"
                    
                    echo "[OK] Clau afegida correctament a l'usuari $target_user."
                else
                    echo "[INFO] La clau ja existeix per a aquest usuari."
                fi
            else
                echo "[!] Format de clau no vàlid. Ha de començar per 'ssh-...'."
            fi
        fi
    elif [[ "$add_ssh_key" == "n" ]]; then
        echo "Finalitzant la gestió de claus ssh."
        break
    else
        echo "[!] Opció no vàlida. Intenta-ho de nou."
    fi
done

echo "--- Configuració de programari finalitzada ---"