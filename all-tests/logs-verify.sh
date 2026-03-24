#!/usr/bin/env bash

# Verifica que un servei continua generant logs

SERVICE="$1"               # Primer argument: nom del servei
MINUTES="${2:-60}"         # Segon argument (opcional): quant temps enrere revisar logs, per defecte 60 min

# Comprovem que l'usuari ha passat el nom del servei
if [ -z "$SERVICE" ]; then
    echo "Usa: $0 <servei> [minuts]"
    echo "Exemple: $0 nginx 30"
    exit 1
fi

# Comprovem que el servei existeix a systemd
if ! systemctl status "$SERVICE" &> /dev/null; then
    echo "ERROR: Servei '$SERVICE' no existix"
    exit 1
fi

# Obtenim el nombre de logs en els últims MINUTES minuts
RECENT_LOGS=$(sudo journalctl -u "$SERVICE" --since "$MINUTES min ago" --no-pager | wc -l)

# Missatge segons hi hagi o no logs recents
if [ "$RECENT_LOGS" -gt 0 ]; then
    echo "OK: $RECENT_LOGS entrades de log en els ultims $MINUTES minuts per $SERVICE"
else
    echo "WARNING: No s'ha trobat logs en els ultims $MINUTES minuts per $SERVICE"
fi

ERROR_LOGS=$(sudo journalctl -u "$SERVICE" --since "$MINUTES min ago" --no-pager | grep -Ei 'fail|error|crit|emerg')

if [ -n "$ERROR_LOGS" ]; then
    echo "WARNING: Logs d'error detectats en els ultims $MINUTES minuts per $SERVICE"
    echo "$ERROR_LOGS"
else
    echo "OK: No ha hagut logs d'error detectats en els ultims $MINUTES minuts per $SERVICE"
fi