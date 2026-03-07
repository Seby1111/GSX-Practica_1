#!/usr/bin/env bash

# Verifica que un servicio sigue generando logs

SERVICE="$1"               # Primer argumento: nombre del servicio
MINUTES="${2:-60}"         # Segundo argumento (opcional): cuánto tiempo hacia atrás revisar logs, default 60 min

# Comprobamos que el usuario pasó el nombre del servicio
if [ -z "$SERVICE" ]; then
    echo "Usage: $0 <service> [minutes]"
    echo "Example: $0 nginx 30"
    exit 1
fi

# Comprobamos que el servicio existe en systemd
if ! systemctl status "$SERVICE" &> /dev/null; then
    echo "ERROR: Service '$SERVICE' does not exist"
    exit 1
fi

# Obtenemos el número de logs en los últimos MINUTES minutos
RECENT_LOGS=$(journalctl -u "$SERVICE" --since "$MINUTES min ago" --no-pager | wc -l)

# Mensaje según haya o no logs recientes
if [ "$RECENT_LOGS" -gt 0 ]; then
    echo "OK: $RECENT_LOGS log entries in the last $MINUTES minutes for $SERVICE"
else
    echo "WARNING: No logs found in the last $MINUTES minutes for $SERVICE"
fi

ERROR_LOGS=$(journalctl -u "$SERVICE" --since "$MINUTES min ago" --no-pager | grep -Ei 'fail|error|crit|emerg')

if [ -n "$ERROR_LOGS" ]; then
    echo "WARNING: Error logs detected in the last $MINUTES minutes for $SERVICE"
    echo "$ERROR_LOGS"
else
    echo "OK: No error logs detected in the last $MINUTES minutes for $SERVICE"
fi