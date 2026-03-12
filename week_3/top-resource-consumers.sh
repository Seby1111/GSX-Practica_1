#!/bin/bash

echo "===================================================================="
echo "  TOP 25 PROCESSOS - CONSUM (CPU I MEMORIA)"
echo "===================================================================="

printf "%-8s %-10s %-6s %-6s %-10s %-8s %-s\n" "PID" "USER" "%CPU" "%MEM" "VSZ" "RSS" "COMMAND"
echo "--------------------------------------------------------------------"

ps -eo pid,user,%cpu,%mem,vsz,rss,comm --no-headers | \
grep -vE "ps|sort|grep|head" | \
sort -k3,3rn -k4,4rn | \
head -n 25 | \
awk '{printf "%-8s %-10s %-6s %-6s %-10s %-8s %-s\n", $1, $2, $3, $4, $5, $6, $7}'
echo "===================================================================="
