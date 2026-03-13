CONF="/etc/systemd/system/nginx.service"

# Función para actualizar un valor
update_conf() {
    local key="$1"
    local value="$2"

    # Si la linea está comentada o existe, reemplaza; si no existe, la agrega
    if grep -q "^#\?$key=" "$CONF"; then
        sudo sed -i "s|^#\?$key=.*|$key=$value|" "$CONF"
    else
        echo "$key=$value" >> "$CONF"
    fi
}

# Crear override para nginx
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
# NICE (CPU PRIORITY) // A bit less priority
Nice=5
EOF

sudo systemctl daemon-reload
sudo systemctl restart nginx

echo "Limites de nginx aplicados correctamente."

CONF="/etc/systemd/system.conf"

update_conf DefaultLimitNOFILE 65536
update_conf DefaultLimitNPROC 4096
update_conf DefaultTasksMax 500

echo "Configuración general de sistema aplicada correctamente."

# System level daemon-reload (acabamos de modificiar configuración global)
sudo systemctl daemon-reexec

CONF="/etc/security/limits.conf"

# Configuración para la máquina virtual, la idea del número de ficheros es tener una configuración generosa que te avisa cuando
# empiezas a gastar muchos recursos, pero dentro de lo que cabe es funcional, el hard limit es el doble para usuarios que quieren
# gastar más recursos por cualquier razón, para tener un buen margén entre el usuario promedio y el excepcionalmente pesado en uso
# de recursos. El límite de procesos intenta ser lo suficientemente alto para prácticidad pero no excesivo para ceñirnos a los 2GB
# de memoria.
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
echo "Añadiendo: $LINE"
echo "$LINE" | sudo tee -a "$CONF" > /dev/null
else
echo "Ya existe: $LINE"
fi
done

echo "Acabado de comprobar $CONF"

echo "Modificación de /etc/security/limits.conf aplicada."

echo "Para aplicar los cambios hace falta cerrar y volver a iniciar la sesión."
