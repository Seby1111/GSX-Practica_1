#!/bin/bash

# Comprovem si l'script s'executa com a root
if [[ $EUID -ne 0 ]]; then
   echo "[!] Aquest script s'ha d'executar com a root (fent servir sudo)."
   exit 1
fi

cd ../week_2/journald

sudo ./journald-install-querys.sh

sudo ./journald-system-conf.sh

sudo ./logrotate-install.sh

cd ../nginx

sudo ./install-nginx-scripts.sh

cd ../../week_3/memory-limiting

sudo ./cpu-limits-install.sh

sudo ./limits-conf.sh

cd ../../week_4

sudo ./user-group-structure.sh

sudo ./directory-structure.sh

cd environment-shell-personalization

sudo ./shell-configuration-install.sh

cd ../../week_5

sudo ./install-backup-system.sh