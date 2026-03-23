#!/bin/bash

arxiu="/etc/systemd/system/cpu-limit.service"

if [ ! -f "$arxiu" ]; then
    echo "Creant cpu-limits.service..."

    sudo tee "$arxiu" > /dev/null << 'EOF'
[Unit]
Description=Servei de prova amb límit de CPU
After=network.target

[Service]
ExecStart=/usr/bin/yes
Restart=always

# Límit de CPU
CPUQuota=50%

# Límits de memòria
MemoryHigh=128M
MemoryMax=256M

# Límits de processos
TasksMax=50

# Descriptors de fitxers
LimitNOFILE=4096

# Prioritat més baixa
Nice=10

[Install]
WantedBy=multi-user.target
EOF
fi

sudo systemctl daemon-reload

sudo systemctl start cpu-limit.service

sudo systemctl enable cpu-limit.service