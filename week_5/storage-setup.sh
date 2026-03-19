#!/bin/bash

lsblk
read -p "Introdueix el dispositiu (ex: /dev/sdb): " NOM_DISPOSITIU

# Crear la taula de particions i la partició (del 0% al 100% del disc)
# Fem servir 1MiB d'inici per l'alineament correcte del disc
sudo parted -s $NOM_DISPOSITIU mklabel gpt mkpart primary ext4 1MiB 100%

lsblk
read read -p "Introdueix la partició creada (ex: /dev/sdb1): " PARTICIO

# Formatejar la partició creada
sudo mkfs.ext4 $PARTICIO

read read -p "Introdueix ruta on vols muntar (ex: /mnt/dades_empresa): " RUTA

# Crear punt de muntatge i muntar
sudo mkdir -p $RUTA
sudo mount $PARTICIO $RUTA

# Persistència  de muntatge (fstab)
UUID_PART=$(blkid -s UUID -o value $PARTICIO)

if [ -n "$UUID_PART" ]; then
    echo "UUID=$UUID_PART $RUTA ext4 defaults 0 2" | sudo tee -a /etc/fstab
    echo "[OK] Configuració afegida al /etc/fstab per UUID."
else
    echo "[ERROR] No s'ha pogut obtenir l'UUID."
fi

echo "--- RESUM DEL MUNTATGE ---"
df -h $RUTA
