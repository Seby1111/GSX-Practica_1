#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <service-name>"
    exit 1
fi

SERVICE="$1"

if ! systemctl list-unit-files --type=service | grep -q "^${SERVICE}.service"; then
    echo "Not a service"
    exit 1
fi

journalctl -u "$SERVICE" --no-pager -n 100