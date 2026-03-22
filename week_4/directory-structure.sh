#!/bin/bash

# ==============================================================================
# SCRIPT DE CONFIGURACIÓ DE L'ESTRUCTURA DE DIRECTORIS I PERMISOS ESPECIALS
# Objectiu: Crear espais de treball compartits i segurs per a l'equip 'greendevcorp'.
# ==============================================================================

# Comprovem si l'script s'executa com a root
if [[ $EUID -ne 0 ]]; then
   echo "[!] Aquest script s'ha d'executar com a root (fent servir sudo)."
   exit 1
fi

echo "[INFO] Creant i configurant el directori /home/greendevcorp/bin..."

# Creem el directori amb -p per evitar errors si ja existeix
mkdir -p /home/greendevcorp/bin
groupadd -f greendevcorp
chown :greendevcorp /home/greendevcorp/bin

# 750 (rwxr-x---): L'amo (root) llegeix/escriu/executa, el grup (equip) llegeix/executa, altres res
chmod 750 /home/greendevcorp/bin

# ACLs per defecte (-d): Garanteixen que qualsevol fitxer NOU que es creï
# dins d'aquesta carpeta hereti automàticament els permisos de lectura per a l'equip
setfacl -d -m u::rwx,g:greendevcorp:rx,o::--- /home/greendevcorp/bin

echo "[INFO] Creant i configurant el directori /home/greendevcorp/shared..."

# Creem el directori amb -p per evitar errors si ja existeix
mkdir -p /home/greendevcorp/shared
chown :greendevcorp /home/greendevcorp/shared

# 2 (SetGID): Fa que els fitxers creats dins heretin el grup 'greendevcorp' automàticament
# 1 (Sticky Bit): Només l'amo d'un fitxer el pot esborrar, evitant que un dev esborri la feina d'un altre
# 770: Control total per a l'amo i el grup, cap accés per a la resta
chmod 3770 /home/greendevcorp/shared

echo "[INFO] Creant i configurant el fitxer /home/greendevcorp/done.log..."

# Creem el fitxer només si no existeix
touch /home/greendevcorp/done.log
chown root:greendevcorp /home/greendevcorp/done.log

# Permisos base: Root pot modificar, l'equip només pot llegir
chmod 644 /home/greendevcorp/done.log

# Donem permís d'escriptura específic a 'dev1'
# sense haver de canviar el propietari del fitxer
setfacl -m u:dev1:rw /home/greendevcorp/done.log