#!/bin/bash

# Comprovem si l'script s'executa com a root
if [[ $EUID -ne 0 ]]; then
   echo "[!] Aquest script s'ha d'executar com a root (fent servir sudo)."
   exit 1
fi

echo "[INFO] Configurant límits de recursos via PAM..."

# Creem el fitxer de configuració
cat <<EOF > /etc/security/limits.d/user_limits.conf
#<domain>      <type>  <item>         <value>

@greendevcorp soft    cpu             20          
@greendevcorp hard    cpu             30          
@greendevcorp soft    as              1024000     
@greendevcorp hard    as              2048000     
@greendevcorp soft    nproc           100         
@greendevcorp hard    nproc           150         
@greendevcorp soft    nofile          512         
@greendevcorp hard    nofile          1024        
EOF

# Verificació de PAM
echo "[INFO] Verificant mòdul pam_limits.so..."
if ! grep -q "pam_limits.so" /etc/pam.d/common-session; then
    echo "session required pam_limits.so" >> /etc/pam.d/common-session
    echo "[OK] Mòdul PAM afegit a common-session."
else
    echo "[OK] PAM ja estava configurat."
fi

echo "[INFO] Torna a iniciar sessio per aplicar els canvis"