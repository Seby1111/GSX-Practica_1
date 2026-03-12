cd /etc/systemd/system/nginx.service

# Función para actualizar un valor
update_conf() {
    local key="$1"
    local value="$2"

    # Si la linea está comentada o existe, reemplaza; si no existe, la agrega
    if grep -q "^#\?$key=" "$JOURNAL_CONF"; then
        sudo sed -i "s|^#\?$key=.*|$key=$value|" "$JOURNAL_CONF"
    else
        echo "$key=$value" >> "$JOURNAL_CONF"
    fi
}

# Modificar valores:


echo "Configuración de journal.conf actualizada correctamente."

[Unit]
Description=Performance-Tuned Application
After=network.target

[Service]
Type=simple
User=appuser
ExecStart=/usr/bin/myapp

# CPU MANAGEMENT
# Give this service half the core (50%)
update_conf CPUQuota 50%

# CPU affinity (pin to cores 0)
update_conf CPUAffinity 0

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