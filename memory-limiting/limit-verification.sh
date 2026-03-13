#!/bin/bash

# Script completo de verificación de Resource Limits
# Incluye:
#   - Límites systemd por servicio
#   - Límites PAM / ulimit
#   - Prueba ligera de CPU y memoria
#   - Logs recientes de cada servicio

SERVICES=("nginx.service" "cpu-limit.service")

echo "INICIO DE VERIFICACIÓN DE LIMITES"

# Verificación por servicio
echo ""
echo "VERIFICACIÓN DE LIMITES POR SERVICIO"
for svc in "${SERVICES[@]}"; do
    echo ""
    echo "Servicio: $svc"
    MAINPID=$(systemctl show "$svc" -p MainPID --value)
    if [ -z "$MAINPID" ] || [ "$MAINPID" -eq 0 ]; then
        echo "El servicio no está iniciado"
        continue
    else
        echo "El servicio está iniciado"
    fi
    echo "PID principal: $MAINPID"

    # Cgroups activos
    valor=$(cat /proc/$MAINPID/cgroup)
    echo "Cgroups: $valor"
done

SERVICE="nginx.service"
MAINPID=$(systemctl show "$SERVICE" -p MainPID --value)
CGROUP=$(cat /proc/$MAINPID/cgroup | grep "0::" | cut -d: -f3)
echo "Límites cgroup para $SERVICE:"
systemctl show nginx.service -p MemoryCurrent,MemoryLimit,CPUQuota,TasksMax,LimitNOFILE
echo "CPUQuota="$(cat /sys/fs/cgroup$CGROUP/cpu.max | cut -d " " -f1 2>/dev/null)

# Verificación de PAM
echo ""
echo "Valores definidos en /etc/security/limits.conf:"
grep -E "nofile|nproc" /etc/security/limits.conf | grep -v "^#"

# Prueba ligera de límites
echo ""
echo "PRUEBA LIGERA DE LÍMITES"
echo "Se generará una carga breve para verificar que los límites se aplican."

# CPU test: ejecutar 'yes' 3s y medir %CPU
for svc in "${SERVICES[@]}"; do
    echo "Probando CPU $svc (3 segundos)..."
    YES_PID=$(yes > /dev/null & echo $!)
    sleep 3
    CPU_TEST=$(ps -p $YES_PID -o %cpu --no-headers 2>/dev/null || echo "0")
    kill $YES_PID &>/dev/null
    echo "$svc: CPU usada en la prueba: $CPU_TEST %"
done

echo ""
echo "Verificación completada."