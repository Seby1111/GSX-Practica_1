#!/bin/bash

# Aquests traps capturen els senyals i executen el codi entre cometes
trap 'echo -e "\n[$(date +%T)] SIGINT (Ctrl+C) detectat. Finalitzant..."; clean_and_exit' SIGINT
trap 'echo "[$(date +%T)] SIGHUP rebut. (Simulació de recàrrega de config)"' SIGHUP
trap 'echo "[$(date +%T)] SIGUSR1 rebut. (Senyal personalitzat 1)"' SIGUSR1
trap 'echo "[$(date +%T)] SIGUSR2 rebut. (Senyal personalitzat 2)"' SIGUSR2
trap 'echo "[$(date +%T)] SIGTERM rebut. Tancament Graciós (Graceful)..."; clean_and_exit' SIGTERM

# Funció per tancar els processos fills abans de sortir
clean_and_exit() {
    if [ ! -z "$YES_PID" ]; then
        kill $YES_PID 2>/dev/null
    fi
    exit 0
}

# Llançem el procés 'yes' en segon pla per generar consum de CPU
yes > /dev/null &
YES_PID=$!

echo "=========================================================="
echo "   GUIA DE PROVES (Copia i enganxa en un altre terminal)"
echo "=========================================================="
echo "PID de l'SCRIPT (Pare): $$"
echo "PID del WORKLOAD (Fill): $YES_PID"
echo "----------------------------------------------------------"
echo "1. PROVES DE CONTROL (No maten el procés):"
echo "   kill -SIGHUP $$    (Simula recàrrega de configuració)"
echo "   kill -SIGUSR1 $$   (Senyal personalitzat 1)"
echo "   kill -SIGUSR2 $$   (Senyal personalitzat 2)"
echo ""
echo "2. PROVA DE TANCAMENT NET (Graceful Shutdown):"
echo "   kill -SIGTERM $$   (L'script netejarà el fill $YES_PID)"
echo ""
echo "3. PROVA DE MORT FORÇOSA (Zombie/Orphan Creator):"
echo "   kill -SIGKILL $$   (L'script mor immediatament)"
echo "   --> ATENCIÓ: Després d'això, el fill $YES_PID quedarà viu!"
echo "   --> Hauràs de matar-lo manualment: kill -9 $YES_PID"
echo "=========================================================="

# Bucle infinit perquè el procés no acabi sol
while true; do
    sleep 2
done