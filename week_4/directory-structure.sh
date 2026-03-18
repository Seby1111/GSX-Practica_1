#!/bin/bash

# Comprovem si l'script s'executa com a root
if [[ $EUID -ne 0 ]]; then
   echo "[!] Aquest script s'ha d'executar com a root (fent servir sudo)."
   exit 1
fi

echo "[INFO] Creant i configurant el directori /home/greendevcorp/bin..."

# Creem el directori només si no existeix
mkdir -p /home/greendevcorp/bin

groupadd -f greendevcorp

# Assignem el grup
chown :greendevcorp /home/greendevcorp/bin

# L'amo pot fer tot (7), el grup pot llegir i executar (5) i la resta res (0)
chmod 750 /home/greendevcorp/bin

# u::rwx (L'amo del script pot fer de tot)
# g:greendevcorp:rx (L'equip pot llegir i executar els scripts)
# o::--- (La resta del món no pot fer res)
setfacl -d -m u::rwx,g:greendevcorp:rx,o::--- /home/greendevcorp/bin

echo "[INFO] Creant i configurant el directori /home/greendevcorp/shared..."

# Creem el directori només si no existeix
mkdir -p /home/greendevcorp/shared

# Assignem el grup (perquè el setgid tingui sentit)
chown :greendevcorp /home/greendevcorp/shared

# El '2' és el SetGID, el '1' és el Sticky Bit. Sumats al principi: 3
# El '770' dóna control total a l'amo i al grup, i res a altres.
chmod 3770 /home/greendevcorp/shared

echo "[INFO] Creant i configurant el fitxer /home/greendevcorp/done.log..."

# Creem el fitxer només si no existeix
touch /home/greendevcorp/done.log

# Assignem el grup i root com a propietari
chown root:greendevcorp /home/greendevcorp/done.log

# L'amo (root) pot llegir i escriure (6) i la resta només llegir (4)
chmod 644 /home/greendevcorp/done.log

# Donem permís de lectura i escriptura (rw) a dev1
setfacl -m u:dev1:rw /home/greendevcorp/done.log