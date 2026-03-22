#!/bin/bash

# ==============================================================================
# SCRIPT DE SIMULACIÓ DE CÀRREGA I GESTIÓ DE SENYALS
# Objectiu: Experimentar amb la comunicació entre processos mitjançant senyals.
# ==============================================================================

# Els 'traps' permeten que l'script no mori immediatament quan rep un senyal,
# sinó que executi una funció o comanda personalitzada

# SIGINT: Captura el Ctrl+C. Executa la neteja i surt
trap 'echo -e "\n[$(date +%T)] SIGINT (Ctrl+C) detectat. Finalitzant..."; clean_and_exit' SIGINT

# SIGHUP: Normalment indica que la terminal s'ha tancat o que cal recarregar la config
trap 'echo "[$(date +%T)] SIGHUP rebut. (Simulació de recàrrega de config)"' SIGHUP

# SIGUSR1/2: Senyals definits per l'usuari per a funcions personalitzades
trap 'echo "[$(date +%T)] SIGUSR1 rebut. (Senyal personalitzat 1)"' SIGUSR1
trap 'echo "[$(date +%T)] SIGUSR2 rebut. (Senyal personalitzat 2)"' SIGUSR2

# SIGTERM: Senyal de tancament amable
trap 'echo "[$(date +%T)] SIGTERM rebut. Tancament Graciós (Graceful)..."; clean_and_exit' SIGTERM

# Funció per tancar els processos fills abans de sortir
clean_and_exit() {
    if [ ! -z "$YES_PID" ]; then
        kill $YES_PID 2>/dev/null
    fi
    exit 0
}

# Llançem el procés 'yes' en segon pla per per consumir CPU en segon pla (&)
yes > /dev/null &
YES_PID=$! # Guardem el PID del procés fill acabat de crear.

echo "=========================================================="
echo "   GUIA DE PROVES (Copia i enganxa en un altre terminal)"
echo "=========================================================="
echo "PID de l'SCRIPT (Pare): $$" # $$ retorna el PID del propi script.
echo "PID del WORKLOAD (Fill): $YES_PID"
echo "----------------------------------------------------------"
# L'script ens dóna les comandes exactes per provar des d'una altra terminal
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

# Bucle infinit per mantenir el procés viu i a l'espera de senyals
while true; do
    sleep 2
done