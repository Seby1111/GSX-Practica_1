#!/bin/bash

# Comprovem si l'script s'executa com a root
if [[ $EUID -ne 0 ]]; then
   echo "[!] Aquest script s'ha d'executar com a root (fent servir sudo)."
   exit 1
fi

cd ../week_1

chmod +x *.sh

sudo ./basig-config-root.sh

sudo ./basic-config-user.sh

sudo ./directory-structure.sh

sudo ./setup-verification.sh

cd ../week_2

chmod +x *.sh

sudo ./backup-setup.sh

cd ./journald

chmod +x *.sh

sudo ./journald-install-querys.sh

sudo ./journald-system-conf.sh

sudo ./logrotate-install.sh

cd ../nginx

chmod +x *.sh

sudo ./install-nginx-scripts.sh

cd ../../week_3/memory-limiting

chmod +x *.sh

sudo ./cpu-limits-install.sh

sudo ./limits-conf.sh

cd ../../week_4

chmod +x *.sh

sudo ./user-group-structure.sh

sudo ./directory-structure.sh

sudo ./resource-limits.sh

cd environment-shell-personalization

chmod +x *.sh

sudo ./shell-configuration-install.sh

cd ../../week_5

chmod +x *.sh

sudo ./install-backup-system.sh