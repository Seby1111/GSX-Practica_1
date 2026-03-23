#!/bin/bash

if [ $# -ne 2 ] ; then
    echo "Us: $0 <servei> <consulta>"
    echo "Exemple: $0 nginx error"
    echo "Es necessiten 2 arguments: el nom del servei i la consulta per buscar als logs. Si la consulta esta buida, mostrara tots els logs del servei."
    exit 1
fi

SERVICE="$1"
QUERY="$2"

if ! systemctl list-unit-files --type=service | grep -q "^${SERVICE}.service"; then
    echo "No es un servei"
    exit 1
fi

journalctl -u "$SERVICE" --no-pager | grep -i "$QUERY"