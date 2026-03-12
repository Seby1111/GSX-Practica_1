#!/bin/bash

if [ $# -ne 3 ] ; then
    echo "Usage: $0 <service> <since> <until>"
    echo "Example: $0 nginx '2 hours ago' 'now'"
    echo "It needs 3 arguments: the service name, the time to start from and the time to end at. The time can be in formats like '2h', '30m', '1d', or more human-readable formats like '2 hours ago'."
    exit 1
fi

SERVICE="$1"
SINCE="$2"
UNTIL="$3"

if ! systemctl list-unit-files --type=service | grep -q "^${SERVICE}.service"; then
    echo "Not a service"
    exit 1
fi

journalctl -u "$SERVICE" --since "$SINCE" --until "$UNTIL" --no-pager -o short-iso