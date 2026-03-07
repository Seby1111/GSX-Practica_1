#!/bin/bash

# Script per a crear els scripts de consulta de journalctl per a qualsevol servei, que es poden utilitzar per a consultar els logs d'un servei específic, filtrar-los per paraules clau o per rangs de temps.

arxiu="/usr/local/bin/journalctl-query.sh"

if [ ! -f "$arxiu" ]; then
    echo "Creant journalctl-query.sh..."

    sudo tee "$arxiu" > /dev/null << 'EOF'
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
EOF

    sudo chmod +x "$arxiu"
fi

arxiu="/usr/local/bin/journalctl-time-query.sh"

if [ ! -f "$arxiu" ]; then
    echo "Creant journalctl-time-query.sh..."

    sudo tee "$arxiu" > /dev/null << 'EOF'
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
EOF

    sudo chmod +x "$arxiu"
fi

arxiu="/usr/local/bin/journalctl-word-query.sh"

if [ ! -f "$arxiu" ]; then
    echo "Creant journalctl-word-query.sh..."

    sudo tee "$arxiu" > /dev/null << 'EOF'
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
EOF

    sudo chmod +x "$arxiu"
fi