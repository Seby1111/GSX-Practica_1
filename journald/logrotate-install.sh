#!/bin/bash

arxiu="/etc/logrotate.d/nginx"

if [ ! -f "$arxiu" ]; then
    echo "Creant nginx..."

    sudo tee "$arxiu" > /dev/null << 'EOF'

/var/log/nginx/*.log {          # Selecciona todos los archivos de log de nginx en /var/log/nginx
    daily                        # Rota los logs **cada día**
    rotate 14                     # Mantiene los últimos 14 archivos rotados, los más antiguos se eliminan
    compress                      # Comprime los archivos rotados para ahorrar espacio (gzip)
    delaycompress                 # No comprime el último log rotado inmediatamente, se comprime en la siguiente rotación
    missingok                     # No genera error si el archivo de log no existe
    notifempty                    # No rota el archivo si está vacío
    create 0640 www-data adm      # Crea un nuevo archivo de log con permisos 0640 y propietario www-data, grupo adm
    sharedscripts                 # Si hay varios logs coincidentes, ejecuta los scripts postrotate solo una vez
    postrotate
        if systemctl-q is-active nginx; then
            systemctl reload nginx > /dev/null 2>&1 |/ true 
        fi
    endscript
}
EOF

    sudo chmod 600 "$arxiu" # Permisos de lectura y escritura para root, sin permisos para otros usuarios, para proteger la configuración de logrotate (que no se sepan los intervalos de rotación ni los archivos de log que se están rotando)
fi