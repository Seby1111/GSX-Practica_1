systemctl list-units --type=service --all | grep nginx
if [ $? -ne 0 ]; then
    echo "[!] Nginx no està instal·lat. Executa el script de configuració bàsica abans d'executar aquest script."
    exit 1
else
    echo "[OK] Nginx està instal·lat i actiu."
fi