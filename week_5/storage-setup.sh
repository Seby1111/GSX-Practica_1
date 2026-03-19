#!/bin/bash

lsblk

echo ""
read -p "Introdueix el dispositiu (ex: /dev/sdb): " NOM_DISPOSITIU

if [ ! -b "$NOM_DISPOSITIU" ]; then
    echo "[ERROR] El dispositiu $NOM_DISPOSITIU no existeix o no és un bloc de disc."
    exit 1
fi

# Crear la taula de particions i la partició (del 0% al 100% del disc)
# Fem servir 1MiB d'inici per l'alineament correcte del disc
sudo parted -s $NOM_DISPOSITIU mklabel gpt mkpart primary ext4 1MiB 100%

# Espera que el nucli registri la nova partició
sudo udevadm settle

lsblk

echo ""
read -p "Introdueix la partició creada (ex: /dev/sdb1): " PARTICIO

if [ ! -b "$PARTICIO" ]; then
    echo "[ERROR] La partició $PARTICIO no existeix o no és vàlida."
    exit 1
fi

# Formatejar la partició creada
sudo mkfs.ext4 $PARTICIO

read -p "Introdueix ruta on vols muntar (ex: /mnt/data): " RUTA

# Comprovar si la ruta és absoluta
if [[ ! "$RUTA" == /* ]]; then
    echo "[ERROR] La ruta ha de ser absoluta (començar per /)."
    exit 1
fi

# Evitar rutes del sistema per seguretat
if [[ "$RUTA" == "/" || "$RUTA" == "/etc"* || "$RUTA" == "/boot"* ]]; then
    echo "[PERILL] No pots muntar un disc sobre una carpeta crítica del sistema!"
    exit 1
fi

# Crear punt de muntatge i muntar
sudo mkdir -p $RUTA
sudo mount $PARTICIO $RUTA

# Persistència de muntatge (fstab) sense duplicats
UUID_PART=$(sudo blkid -s UUID -o value $PARTICIO)

if [ -z "$UUID_PART" ]; then
    echo "[ERROR] No s'ha pogut obtenir l'UUID."
    exit 1
fi

if grep -q "$UUID_PART" /etc/fstab; then
    echo "[AVÍS] Aquest UUID ja està configurat al /etc/fstab."
else
    echo "UUID=$UUID_PART $RUTA ext4 defaults 0 2" | sudo tee -a /etc/fstab
    echo "[OK] Configuració afegida al /etc/fstab per UUID."
fi

# Verificació final de muntatge
sudo mount -a

if [ $? -eq 0 ]; then
    echo "[OK] El fitxer /etc/fstab és correcte."
else
    echo "[ALERTA] Hi ha un error al /etc/fstab! Revisa'l abans de reiniciar."
fi

echo "--- RESUM DEL MUNTATGE ---"
df -h $RUTA
