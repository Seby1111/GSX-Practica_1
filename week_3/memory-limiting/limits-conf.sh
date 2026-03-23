#!/bin/bash

CONF="/etc/systemd/system/nginx.service"

# Funció per actualitzar un valor
update_conf() {
    local key="$1"
    local value="$2"
    if grep -q "^#\?$key=" "$CONF"; then
        sudo sed -i "s|^#\?$key=.*|$key=$value|" "$CONF"
    else
        echo "$key=$value" >> "$CONF"
    fi
}

# Crear override per nginx
sudo mkdir -p /etc/systemd/system/nginx.service.d
sudo tee /etc/systemd/system/nginx.service.d/limits.conf > /dev/null <<EOF
[Service]
# CPU MANAGEMENT
# Give this service half the core (50%)
CPUQuota=50%
# CPU affinity (pin to cores 0)
CPUAffinity=0
# Memory MANAGEMENT
# Soft limit (warning at 512MB)
MemoryLimit=512M
# Hard limit (SIGKILL if exceeded)
MemoryMax=1024M
# FILE DESCRIPTOR LIMITS
LimitNOFILE=65536
# PROCESS LIMITS
LimitNPROC=4096
TasksMax=500
# NICE (CPU PRIORITY) // A bit more priority
Nice=-2
EOF

sudo systemctl daemon-reload
sudo systemctl restart nginx

echo "Limits de nginx aplicats correctament."

CONF="/etc/systemd/system.conf"

update_conf DefaultLimitNOFILE 65536
update_conf DefaultLimitNPROC 4096
update_conf DefaultTasksMax 500

echo "Configuració general de sistema aplicada correctament."

# System level daemon-reload (ac acabat de modificar configuració global)
sudo systemctl daemon-reexec

CONF="/etc/security/limits.conf"

# Configuració per la màquina virtual, la idea del nombre de fitxers és tenir una configuració generosa que t'avisa quan
# comences a gastar molts recursos, però dins del que es pot és funcional, el hard limit és el doble per usuaris que volen
# gastar més recursos per qualsevol raó, per tenir un bon marge entre l'usuari mitjà i l'excepcionalment pesat en ús
# de recursos. El límit de processos intenta ser prou alt per practicitat però no excessiu per ceñir-nos als 2GB
# de memòria.
LINES=(
"sshuser soft nofile 4096"
"sshuser hard nofile 8192"
"sshuser soft nproc 200"
"sshuser hard nproc 300"
"nginx soft nofile 4096"
"nginx hard nofile 8192"
"nginx soft nproc 200"
"nginx hard nproc 300"
)

for LINE in "${LINES[@]}"; do
if ! grep -Fxq "$LINE" "$CONF"; then
echo "Afegint: $LINE"
echo "$LINE" | sudo tee -a "$CONF" > /dev/null
else
echo "Ja existeix: $LINE"
fi
done

echo "Acabat de comprovar $CONF"

echo "Modificació de /etc/security/limits.conf aplicada."

echo "Per aplicar els canvis cal tancar i tornar a iniciar la sessió."