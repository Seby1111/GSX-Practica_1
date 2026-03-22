#!/bin/bash

# ==============================================================================
# SCRIPT DE GENERACIÓ I DESPLEGAMENT DE CLAUS SSH (CLIENT)
# Objectiu: Crear una identitat digital segura i exportar-la al servidor remot.
# ==============================================================================

# Sol·licitud de dades de xarxa per a la connexió
read -p "Introdueix la IP del servidor: " host_ip
read -p "Introdueix el port del servidor (deixa-ho en blanc per defecte 22): " host_port
# Assignació de valor per defecte si l'usuari prem Enter (Port 22)
host_port=${host_port:-22}

# Generació de la clau
# Comprovem si l'usuari ja té una clau del tipus més segur 'ed25519'
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    echo "[INFO] No s'ha trobat cap clau SSH. Creant una nova clau SSH..."
    
    # -sp amaga l'entrada de text per seguretat mentre s'escriu la contrasenya
    read -sp "[*] Introdueix una contrasenya per protegir la clau SSH (deixa-ho en blanc per no utilitzar contrasenya): " ssh_passphrase
    echo ""

    # Generem la clau amb l'algorisme Ed25519 (més ràpid i segur que RSA).
    ssh-keygen -t ed25519 -C "$USER@$host_ip" -f "$HOME/.ssh/id_ed25519" -N "$ssh_passphrase"
else
    echo "[INFO] Ja existeix una clau SSH a $HOME/.ssh/id_ed25519. Utilitzant aquesta clau."
fi

# Desplegament al servidor remot
echo "[INFO] Copiant la clau SSH pública al servidor remot..."
read -p "Introdueix el nom d'usuari remot per copiar la clau SSH: " remote_user

# Enviament de la clau pública mitjançant un túnel SSH segur
# S'utilitza 'StrictHostKeyChecking=accept-new' per acceptar la signatura del servidor automàticament la 1a vegada
# L'ordre remota crea el directori .ssh, ajusta permisos i afegeix la clau a 'authorized_keys'
if cat "$HOME/.ssh/id_ed25519.pub" | ssh -p "$host_port" -o "StrictHostKeyChecking=accept-new" "$remote_user@$host_ip" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"; then
    echo "[OK] Clau SSH copiada correctament a $remote_user@$host_ip."
else
    echo "[ERROR] No s'ha pogut copiar la clau SSH a $remote_user@$host_ip. Comprova les credencials i la connexió de xarxa."
fi