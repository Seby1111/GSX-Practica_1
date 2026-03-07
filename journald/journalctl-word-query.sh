#!/bin/bash

if [ $# -ne 2 ] ; then
    echo "Usage: $0 <service> <query>"
    echo "Example: $0 nginx error"
    echo "It needs 2 arguments: the service name and the query to search for in the logs. If the query is empty, it will show all logs for the service."
    exit 1
fi

SERVICE="$1"
QUERY="$2"

if ! systemctl list-unit-files --type=service | grep -q "^${SERVICE}.service"; then
    echo "Not a service"
    exit 1
fi

journalctl -u "$SERVICE" --no-pager | grep -i "$QUERY"