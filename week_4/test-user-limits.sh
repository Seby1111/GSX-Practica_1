#!/bin/bash
# Script principal per validar la configuració de PAM

# Nom del grup que té les restriccions
GRUP_LIMIT="greendevcorp"

# Obtenir el nom de l'usuari actual
USUARI_ACTUAL=$(whoami)

# Comprovar si l'usuari pertany al grup
if ! groups "$USUARI_ACTUAL" | grep -q "\b$GRUP_LIMIT\b"; then
    echo "------------------------------------------------------------"
    echo "[!] ATENCIÓ: L'usuari '$USUARI_ACTUAL' NO pertany al grup '$GRUP_LIMIT'."
    echo "[!] Els límits de PAM no s'aplicaran i el test NO serà vàlid."
    echo "------------------------------------------------------------"
    echo "[*] Consell: Executa l'script així: sudo -u dev1 -i -c $0"
    echo "------------------------------------------------------------"
    exit 1
fi

echo "[OK] Usuari '$USUARI_ACTUAL' validat. Començant el test..."
# ... aquí aniria la resta del teu script de test ...

echo "====================================================="
echo "[*] VALIDACIÓ DE CONFIGURACIÓ PAM (Usuari: $USER)"
echo "====================================================="

# Mostrem els límits que PAM ha carregat al login
echo -e "\n[INFO] Límits detectats segons PAM:"
ulimit -Sa | grep -E "open files|max user processes|virtual memory|cpu time"

# Test de fitxers
echo -e "\n[TEST] Comprovant límit de fitxers de PAM..."
fds=()
for i in {1..4000}; do
    if exec {fd}> /dev/null 2>/dev/null; then
        fds+=($fd)
    else
        echo "    -> [OK] PAM ha bloquejat l'obertura al fitxer nº: $i"
        break
    fi
done

# Tanquem els fitxers
for f in "${fds[@]}"; do exec {f}>&- 2>/dev/null; done

# Test de memoria
echo -e "\n[TEST] Comprovant límit de memòria de PAM..."
mem_data=""
for i in {1..20}; do
    # Intentem afegir blocs de 100MB
    if chunk=$(printf '%104857600s' ' ' 2>/dev/null); then
        mem_data="${mem_data}${chunk}"
        echo "    ... Memòria en ús: $((i * 100)) MB"
    else
        echo "    -> [OK] PAM ha restringit la memòria correctament."
        break
    fi
done


# Test de processos
trap 'builtin kill $(jobs -p) 2>/dev/null' EXIT

echo -e "\n[TEST] Comprovant límit de processos de PAM..."
count=0
# Fem un bucle prou gran per superar qualsevol límit normal
for i in {1..2000}; do
    sleep 100 & 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "    -> [OK] PAM ha bloquejat la creació al procés nº: $i"
        break
    fi
    count=$i
    echo -ne "    ... creats: $count\r"
    sleep 0.02
done

echo -e "\n====================================================="
echo "[*] VALIDACIÓ FINALITZADA"