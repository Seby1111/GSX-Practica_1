#!/bin/bash

# ==============================================================================
# SCRIPT DE VALIDACIÓ DE LÍMITS PAM (STRESS TEST)
# Objectiu: Provar empíricament que les restriccions de recursos funcionen.
# ==============================================================================

# Grup que hem definit a /etc/security/limits.d/user_limits.conf
GRUP_LIMIT="greendevcorp"
USUARI_ACTUAL=$(whoami)

# Si l'usuari no pertany al grup, els límits no s'aplicaran i el test sera inútil
if ! groups "$USUARI_ACTUAL" | grep -q "\b$GRUP_LIMIT\b"; then
    # Cerquem un usuari real del grup per suggerir-lo a l'administrador
    EXEMPLE_USER=$(getent group "$GRUP_LIMIT" | cut -d: -f4 | cut -d, -f1)
    [[ -z "$EXEMPLE_USER" ]] && EXEMPLE_USER="nom_usuari_dev"
    
    echo "------------------------------------------------------------"
    echo "[!] ATENCIÓ: L'usuari '$USUARI_ACTUAL' NO pertany al grup '$GRUP_LIMIT'."
    echo "[!] Els límits de PAM no s'aplicaran i el test NO serà vàlid."
    echo "------------------------------------------------------------"
    echo "[*] Consell per executar el test correctament:"
    echo ""
    echo "  1. Copia l'script a una zona pública:"
    echo "     cp $0 /tmp/test-unificat.sh"
    echo ""
    echo "  2. Dona permisos d'execució:"
    echo "     chmod +x /tmp/test-unificat.sh"
    echo ""
    echo "  3. Executa com a usuari del grup (ex: $EXEMPLE_USER):"
    echo "     sudo -u $EXEMPLE_USER -i /tmp/test-unificat.sh"
    echo "------------------------------------------------------------"
    exit 1
fi

echo "[OK] Usuari '$USUARI_ACTUAL' validat. Començant el test..."

echo "====================================================="
echo "[*] VALIDACIÓ DE CONFIGURACIÓ PAM (Usuari: $USER)"
echo "====================================================="

# Mostrem el límit actual carregat en la sessió de l'usuari (ulimit)
echo -e "\n[INFO] Límits detectats segons PAM:"
ulimit -Sa | grep -E "open files|max user processes|virtual memory|cpu time"

test_nofile() {
    echo "[TEST] Obrint fitxers fins al límit..."
    local i=0

    # Intentem obrir descriptors de fitxer (fd) infinitament
    while true; do
        if exec {fd}> /dev/null 2>/dev/null; then
            ((i++))
            echo -ne "Fitxers oberts: $i\r"
        else
            # Quan 'exec' falla, hem arribat al límit de PAM
            echo -e "\n[OK] El sistema ha bloquejat l'obertura a l'intent: $i"
            break
        fi
    done
}

test_nproc() {
    echo "[TEST] Iniciant prova de límit de processos (nproc)..."
    
    local i=0

    while true; do
        # Creem un procés fill (sleep) en segon pla (&)
        sleep 10 &
        
        # Si $? (codi de retorn de l'última comanda) no és 0, el kernel ha prohibit el 'fork'        
        if [ $? -ne 0 ]; then
            break
        fi
        
        ((i++))
        echo -ne "Processos actius creats: $i\r"
        sleep 0.01
    done
}

test_memoria() {
    echo "[TEST] Omplint memòria virtual (as) fins al límit..."
    
    local i=0
    local d=""
    # Creem una cadena de text buida de 50MB per cada iteració
    local bloc=$(printf '%52428800s' ' ')

    while true; do
        # Intentem concatenar el bloc a la variable 'd' (emmagatzemada en RAM)        
        if d="${d}${bloc}" 2>/dev/null; then
            ((i++))
            # Mostrem el total acumulat
            echo -ne "Memòria virtual ocupada: $((i * 50)) MB\r"
        else
            # Quan Bash no pot assignar més memòria a la variable, salta el límit
            echo -e "\n\n[OK] LÍMIT PAM (as) ASSOLIT!"
            echo "[INFO] El procés ha fallat en intentar superar els $((i * 50)) MB."
            break
        fi
    done
}

# --- MENÚ D'USUARI ---
echo ""
echo "Tria el test a realitzar:"

echo "1) Fitxers (nofile)"
echo "2) Processos (nproc)"
echo "3) Memòria (as)"
read -p "Opció: " opc

case $opc in
    1) test_nofile ;;
    2) test_nproc ;;
    3) test_memoria ;;
    *) echo "Opció no vàlida" ;;
esac