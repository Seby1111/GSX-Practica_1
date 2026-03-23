#!/bin/bash

# Script per a crear els scripts de consulta de journalctl per a qualsevol servei, que es poden utilitzar per a consultar els logs d'un servei específic, filtrar-los per paraules clau o per rangs de temps.

arxiu="/usr/local/bin/journalctl-query.sh"

if [ ! -f "$arxiu" ]; then
    echo "Creant journalctl-query.sh..."

    sudo tee "$arxiu" > /dev/null << 'EOF'
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
EOF

    sudo chmod +x "$arxiu"
fi

arxiu="/usr/local/bin/journalctl-time-query.sh"

if [ ! -f "$arxiu" ]; then
    echo "Creant journalctl-time-query.sh..."

    sudo tee "$arxiu" > /dev/null << 'EOF'
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
EOF

    sudo chmod +x "$arxiu"
fi

arxiu="/usr/local/bin/journalctl-word-query.sh"

if [ ! -f "$arxiu" ]; then
    echo "Creant journalctl-word-query.sh..."

    sudo tee "$arxiu" > /dev/null << 'EOF'
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
EOF

    sudo chmod +x "$arxiu"
fi