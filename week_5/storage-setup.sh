#!/bin/bash

# ==============================================================================
# SCRIPT DE CONFIGURACIÓ D'EMMAGATZEMATGE
# Objectiu: Automatitzar el particionat, formatat i muntatge permanent d'un disc.
# ==============================================================================

# Llistem els discos disponibles per ajudar l'usuari a identificar el nou disc (ex: sdb)
lsblk

echo ""
read -p "Introdueix el dispositiu (ex: /dev/sdb): " NOM_DISPOSITIU

# Verifiquem que el fitxer de dispositiu existeix i és un bloc de disc
if [ ! -b "$NOM_DISPOSITIU" ]; then
    echo "[ERROR] El dispositiu $NOM_DISPOSITIU no existeix o no és un bloc de disc."
    exit 1
fi

# Creem una taula GPT (moderna) i una partició primària que ocupi tot el disc.
# Usem 1MiB d'inici per assegurar l'alineament físic òptim dels sectors.
sudo parted -s $NOM_DISPOSITIU mklabel gpt mkpart primary ext4 1MiB 100%

# Esperem que el kernel registri els canvis al hardware abans de continuar
sudo udevadm settle

lsblk

echo ""
read -p "Introdueix la partició creada (ex: /dev/sdb1): " PARTICIO

if [ ! -b "$PARTICIO" ]; then
    echo "[ERROR] La partició $PARTICIO no existeix o no és vàlida."
    exit 1
fi

# Apliquem el sistema de fitxers ext4 (estàndard de Linux per a dades)
sudo mkfs.ext4 $PARTICIO

read -p "Introdueix ruta on vols muntar (ex: /mnt/data): " RUTA

# La ruta ha de ser absoluta i no pot trepitjar directoris crítics del sistema
if [[ ! "$RUTA" == /* ]]; then
    echo "[ERROR] La ruta ha de ser absoluta (començar per /)."
    exit 1
fi

if [[ "$RUTA" == "/" || "$RUTA" == "/etc"* || "$RUTA" == "/boot"* ]]; then
    echo "[PERILL] No pots muntar un disc sobre una carpeta crítica del sistema!"
    exit 1
fi

# Creem el punt de muntatge i realitzem el muntatge
sudo mkdir -p $RUTA
sudo mount $PARTICIO $RUTA

# Obtenim l'UUID (identificador únic universal) per evitar errors si canvien els cables/ports
UUID_PART=$(sudo blkid -s UUID -o value $PARTICIO)

if [ -z "$UUID_PART" ]; then
    echo "[ERROR] No s'ha pogut obtenir l'UUID."
    exit 1
fi

# Afegim la línia al fstab només si no existeix ja, per evitar corrupció del fitxer
if grep -q "$UUID_PART" /etc/fstab; then
    echo "[AVÍS] Aquest UUID ja està configurat al /etc/fstab."
else
    echo "UUID=$UUID_PART $RUTA ext4 defaults 0 2" | sudo tee -a /etc/fstab
    echo "[OK] Configuració afegida al /etc/fstab per UUID."
fi

# Verificació final: Simulem un muntatge de tot el fitxer fstab
sudo mount -a

if [ $? -eq 0 ]; then
    echo "[OK] El fitxer /etc/fstab és correcte."
else
    echo "[ALERTA] Hi ha un error al /etc/fstab! Revisa'l abans de reiniciar."
fi

echo "--- RESUM DEL MUNTATGE ---"
df -h $RUTA
