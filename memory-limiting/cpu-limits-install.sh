#!/bin/bash

arxiu="/etc/systemd/system/cpu-limit.service"

if [ ! -f "$arxiu" ]; then
    echo "Creant cpu-limits.service..."

    sudo tee "$arxiu" > /dev/null << 'EOF'
[Unit]
Description=CPU Limited Test Service
After=network.target

[Service]
ExecStart=/usr/bin/yes
Restart=always

# CPU limit
CPUQuota=50%

# Memory limits
MemoryHigh=128M
MemoryMax=256M

# Process limits
TasksMax=50

# File descriptors
LimitNOFILE=4096

# Lower priority
Nice=10

[Install]
WantedBy=multi-user.target
EOF
fi

sudo systemctl daemon-reload

sudo systemctl start cpu-limit.service

sudo systemctl enable cpu-limit.service