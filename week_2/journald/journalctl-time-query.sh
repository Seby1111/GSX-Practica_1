#!/bin/bash

if [ $# -ne 3 ] ; then
    echo "Us: $0 <servei> <des_de> <fins_a>"
    echo "Exemple: $0 nginx '2 hours ago' 'now'"
    echo "Es necessiten 3 arguments: el nom del servei, el temps des del qual començar i el temps fins al qual acabar. El temps pot estar en formats com '2h', '30m', '1d', o formats mes llegibles com '2 hours ago'."
    exit 1
fi

SERVICE="$1"
SINCE="$2"
UNTIL="$3"

if ! systemctl list-unit-files --type=service | grep -q "^${SERVICE}.service"; then
    echo "No es un servei"
    exit 1
fi

journalctl -u "$SERVICE" --since "$SINCE" --until "$UNTIL" --no-pager -o short-iso