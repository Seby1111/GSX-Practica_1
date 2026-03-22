#!/bin/bash

# ==============================================================================
# SCRIPT DE GESTIÓ D'USUARIS I GRUPS (PROVISIONING)
# Objectiu: Automatitzar la creació d'usuaris de desenvolupament i la seva seguretat.
# ==============================================================================

# Verifiquem si l'usuari és root (EUID 0). Crear usuaris requereix permisos totals.
 [[ $EUID -ne 0 ]]; then
   echo "[!] Aquest script s'ha d'executar com a root (fent servir sudo)."
   exit 1
fi

add_user() {
    local username=$1

    # Comprovem si l'usuari ja existeix per evitar errors de duplicitat (Idempotència)
    if id "$username" &>/dev/null; then
        echo "[!] L'usuari $username ja existeix."
    else
        echo "[INFO] Creant usuari $username..."
        
        # useradd -m: Crea el directori personal /home/usuari
        # -s /bin/bash: Assigna la shell estàndard de Linux
        useradd -m -s /bin/bash "$username"
        
        # Assignem una contrasenya temporal i forcem el canvi immediat (-d 0)
        # en el primer inici de sessió per seguretat.        
        echo "$username:milax" | chpasswd
        chage -d 0 "$username"
        
        # Afegim l'usuari al grup greendevcorp
        usermod -aG greendevcorp "$username"

        # Fem que el directory home de cada usuari sigui privat
        chmod 700 /home/"$username"
        
        echo "[OK] Usuari $username creat i afegit a 'greendevcorp'."
    fi
}

echo "[INFO] Creant grup 'greendevcorp'..."
# -f: Crea el grup només si no existeix, sense donar error si ja hi és
groupadd -f greendevcorp

echo "[OK] Grup 'greendevcorp' creat correctament."

# Llista d'usuaris a crear (escalable: pots afegir-ne més aquí)
USERS=("dev1" "dev2" "dev3" "dev4")

echo "[INFO] Afegint usuaris ${USERS[@]}"

# Bucle per processar cada usuari de la llista
for user in "${USERS[@]}"; do
    add_user "$user"
done
