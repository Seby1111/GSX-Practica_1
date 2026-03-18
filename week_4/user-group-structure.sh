#!/bin/bash

# Comprovem si l'script s'executa com a root
if [[ $EUID -ne 0 ]]; then
   echo "[!] Aquest script s'ha d'executar com a root (fent servir sudo)."
   exit 1
fi

add_user() {
    local username=$1
    if id "$username" &>/dev/null; then
        echo "[!] L'usuari $username ja existeix."
    else
        echo "[INFO] Creant usuari $username..."
        
        # -m crea la home directory
        useradd -m -s /bin/bash "$username"
        
        # Configurem la contrasenya i forcem el canvi en el primer log-in
        echo "$username:milax" | chpasswd
        chage -d 0 "$username"
        
        # Afegim l'usuari al grup
        usermod -aG greendevcorp "$username"

        # Fem que el directory home de cada usuari sigui privat
        chmod 700 /home/"$username"
        
        echo "[OK] Usuari $username creat i afegit a 'greendevcorp'."
    fi
}

echo "[INFO] Creant grup 'greendevcorp'..."
groupadd -f greendevcorp

echo "[OK] Grup 'greendevcorp' creat correctament."

USERS=("dev1" "dev2" "dev3" "dev4")

echo "[INFO] Afegint usuaris ${USERS[@]}"

for user in "${USERS[@]}"; do
    add_user "$user"
done
