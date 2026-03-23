#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Us: $0 <nom-del-servei>"
    exit 1
fi

SERVICE="$1"

if ! systemctl list-unit-files --type=service | grep -q "^${SERVICE}.service"; then
    echo "No es un servei"
    exit 1
fi

journalctl -u "$SERVICE" --no-pager -n 100