#!/bin/bash

arxiu="/etc/logrotate.d/nginx"

if [ ! -f "$arxiu" ]; then
    echo "Creant nginx..."

    sudo tee "$arxiu" > /dev/null << 'EOF'

/var/log/nginx/*.log {          # Selecciona tots els arxius de log de nginx a /var/log/nginx
    daily                        # Rota els logs (cada dia)
    rotate 14                     # Manté els últims 14 arxius rotats, els més antics s'eliminen
    compress                      # Comprimeix els arxius rotats per estalviar espai (gzip)
    delaycompress                 # No comprimeix l'últim log rotat immediatament, es comprimeix en la següent rotació
    missingok                     # No genera error si l'arxiu de log no existeix
    notifempty                    # No rota l'arxiu si està buit
    create 0640 www-data adm      # Crea un nou arxiu de log amb permisos 0640 i propietari www-data, grup adm
    sharedscripts                 # Si hi ha diversos logs coincidents, executa els scripts postrotate només una vegada
    postrotate
        if systemctl -q is-active nginx; then
            systemctl reload nginx > /dev/null 2>&1 || true 
        fi
    endscript
}
EOF

    sudo chmod 600 "$arxiu" # Permisos de lectura i escriptura per root, sense permisos per altres usuaris, per protegir la configuració de logrotate (que no es coneguin els intervals de rotació ni els arxius de log que es roten)
else
    # Comparar el contingut actual amb el desitjat i actualitzar només si és diferent
    sudo tee /tmp/nginx_tmp > /dev/null << 'EOF'

/var/log/nginx/*.log {          # Selecciona tots els arxius de log de nginx a /var/log/nginx
    daily                        # Rota els logs (cada dia)
    rotate 14                     # Manté els últims 14 arxius rotats, els més antics s'eliminen
    compress                      # Comprimeix els arxius rotats per estalviar espai (gzip)
    delaycompress                 # No comprimeix l'últim log rotat immediatament, es comprimeix en la següent rotació
    missingok                     # No genera error si l'arxiu de log no existeix
    notifempty                    # No rota l'arxiu si està buit
    create 0640 www-data adm      # Crea un nou arxiu de log amb permisos 0640 i propietari www-data, grup adm
    sharedscripts                 # Si hi ha diversos logs coincidents, executa els scripts postrotate només una vegada
    postrotate
        if systemctl -q is-active nginx; then
            systemctl reload nginx > /dev/null 2>&1 || true 
        fi
    endscript
}
EOF

    if ! cmp -s /tmp/nginx_tmp "$arxiu"; then
        echo "Actualitzant $arxiu..."
        sudo mv /tmp/nginx_tmp "$arxiu"
        sudo chmod 600 "$arxiu"
    else
        sudo rm /tmp/nginx_tmp
    fi
fi