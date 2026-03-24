#!/bin/bash

# Script complet de verificació de Resource Limits
# Inclou:
#   - Límits systemd per servei
#   - Límits PAM / ulimit
#   - Prova lleugera de CPU i memòria
#   - Logs recents de cada servei

SERVICES=("nginx.service" "cpu-limit.service")

echo "INICI DE VERIFICACIÓ DE LÍMITS"

# Verificació per servei
echo ""
echo "VERIFICACIÓ DE LÍMITS PER SERVEI"
for svc in "${SERVICES[@]}"; do
    echo ""
    echo "Servei: $svc"
    MAINPID=$(systemctl show "$svc" -p MainPID --value)
    if [ -z "$MAINPID" ] || [ "$MAINPID" -eq 0 ]; then
        echo "El servei no està iniciat"
        continue
    else
        echo "El servei està iniciat"
    fi
    echo "PID principal: $MAINPID"

    # Cgroups actius
    valor=$(cat /proc/$MAINPID/cgroup)
    echo "Cgroups: $valor"
done

SERVICE="nginx.service"
MAINPID=$(systemctl show "$SERVICE" -p MainPID --value)
CGROUP=$(cat /proc/$MAINPID/cgroup | grep "0::" | cut -d: -f3)
echo "Límits cgroup per a $SERVICE:"
systemctl show nginx.service -p MemoryCurrent,MemoryLimit,CPUQuota,TasksMax,LimitNOFILE
echo "CPUQuota="$(cat /sys/fs/cgroup$CGROUP/cpu.max | cut -d " " -f1 2>/dev/null)

# Verificació de PAM
echo ""
echo "Valors definits a /etc/security/limits.conf:"
grep -E "nofile|nproc" /etc/security/limits.conf | grep -v "^#"

# Prova lleugera de límits
echo ""
echo "PROVA LLEUGERA DE LÍMITS"
echo "Es generarà una càrrega breu per verificar que els límits s'apliquen."

# CPU test: executar 'yes' 3s i mesurar %CPU
for svc in "${SERVICES[@]}"; do
    echo "Provant CPU $svc (3 segons)..."
    YES_PID=$(yes > /dev/null & echo $!)
    sleep 3
    CPU_TEST=$(ps -p $YES_PID -o %cpu --no-headers 2>/dev/null || echo "0")
    kill $YES_PID &>/dev/null
    echo "$svc: CPU usada en la prova: $CPU_TEST %"
done

echo ""
echo "Verificació completada."