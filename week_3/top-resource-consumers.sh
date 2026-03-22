#!/bin/bash

# ==============================================================================
# SCRIPT DE MONITORATGE DE RECURSOS (TOP 25 PROCESSOS)
# Objectiu: Llistar els processos que més CPU i Memòria consumeixen actualment.
# ==============================================================================

echo "===================================================================="
echo "  TOP 25 PROCESSOS - CONSUM (CPU I MEMORIA)"
echo "===================================================================="

# Impressió de la capçalera formatada per columnes
# %-8s significa una cadena de text alineada a l'esquerra amb un espai de 8 caràcters.
printf "%-8s %-10s %-6s %-6s %-10s %-8s %-s\n" "PID" "USER" "%CPU" "%MEM" "VSZ" "RSS" "COMMAND"
echo "--------------------------------------------------------------------"


# Lògica d'extracció de dades:
# 1. ps -eo: Seleccionem columnes específiques (PID, usuari, CPU, memòria, memòria virtual, RAM real, comanda).
# 2. grep -vE: Excloem els processos que genera el propi script per no "embrutar" el resultat.
# 3. sort -k3,3rn: Ordenem per la 3a columna (CPU) de forma numèrica i inversa (de major a menor).
# 4. head -n 25: Limitem el resultat als 25 primers.
# 5. awk: Repliquem el format de columnes per assegurar que la sortida visual sigui perfecta.

ps -eo pid,user,%cpu,%mem,vsz,rss,comm --no-headers | \
grep -vE "ps|sort|grep|head" | \
sort -k3,3rn -k4,4rn | \
head -n 25 | \
awk '{printf "%-8s %-10s %-6s %-6s %-10s %-8s %-s\n", $1, $2, $3, $4, $5, $6, $7}'

echo "===================================================================="
