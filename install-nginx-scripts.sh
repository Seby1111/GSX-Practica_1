#!/bin/bash

# Aquest script activara test-nginx.sh com a test periodic del servei nginx

arxiu="/usr/local/bin/test-nginx.sh"

if [ ! -f "$arxiu" ]; then
    echo "Creant test-nginx.sh..."

    sudo tee "$arxiu" > /dev/null << 'EOF'
#!/bin/bash

# Script per a comprovar la configuració de Nginx, que està actiu i habilitat, i que es reinicia automàticament en cas de fallada.

# Comprova si Nginx està actiu i habilitat, i si no ho està, el posa en marxa i l'habilita. També comprova si Nginx està instal·lat i, si no ho està, mostra un missatge d'error.
if ! sudo systemctl is-active --quiet nginx.service ; then
    echo "[!] Nginx no està actiu. Activant..."
    sudo systemctl start nginx.service
    if [ $? -ne 0 ]; then
        if systemctl is-failed --quiet nginx.service ; then
            echo "[ERROR] Nginx ha fallat en iniciar. Comprovant errors..."
            # Redirigeix la surtida del error sense abreviar ni omitir res.
            journalctl -u nginx.service --no-pager --no-full > nginx_error.log
            echo "Els errors s'han guardat a nginx_error.log"
        elif systemctl is-inactive --quiet nginx.service && grep -q "Restart=always" /lib/systemd/system/nginx.service ; then
            echo "[ERROR] No funciona el automatic restart."
        fi
    fi
else
    echo "[OK] Nginx està actiu."
fi

# Comprova si Nginx està habilitat i, si no ho està, l'habilita.
if ! systemctl is-enabled --quiet nginx.service ; then
    echo "[!] Nginx no està habilitat. Habilitant..."
    sudo systemctl enable nginx.service
else
    echo "[OK] Nginx està habilitat."
fi

# Comprova si Nginx se reinicia automàticament en cas de fallada i, si no ho fa, afegeix la clausula "Restart=always" en l'apartat de [Service] del fitxer de servei de Nginx.
if ! grep -q "Restart=always" /lib/systemd/system/nginx.service; then
    echo "[!] Nginx no té Restart=always. Afegint..."
    sudo sed -i '/\[Service\]/a Restart=always' /lib/systemd/system/nginx.service
    sudo systemctl daemon-reload
    sudo systemctl restart nginx.service
fi

# Comprova si nginx existeix com a servici en systemd
if systemctl list-unit-files | grep -q "nginx.service" ; then
    echo "[OK] Nginx es descubrible amb systemctl."
else
    echo "[!] Nginx no s'ha trobat en systemctl."
fi

# Comprova si hi ha logs de nginx en journalctl
nginxNum=$(journalctl -u nginx.service | wc -l)
if [ $nginxNum -ne 0 ]; then
    echo "[OK] Nginx es descubrible en journalctl."
else
    echo "[!] No s'han trobat logs de nginx en journalctl."
fi
EOF

    sudo chmod +x "$arxiu"
fi

arxiu="/etc/systemd/system/test-nginx.service"

if [ ! -f "$arxiu" ]; then
    echo "Creant test-nginx.service..."

    sudo tee "$arxiu" > /dev/null << 'EOF'
[Unit]
Description=Comprovacio diaria de Nginx

[Service]
Type=oneshot
ExecStart=/usr/local/bin/test-nginx.sh
EOF

arxiu="/etc/systemd/system/test-nginx.timer"

if [ ! -f "$arxiu" ]; then
    echo "Creant test-nginx.timer..."

    sudo tee "$arxiu" > /dev/null << 'EOF'
[Unit]
Description=Timer diari per comprovar Nginx

[Timer]
OnCalendar=daily
Unit=test-nginx.service

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable test-nginx.timer
sudo systemctl start test-nginx.timer

# Comprova si nginx existeix com a servici en systemd
if systemctl list-unit-files | grep -q "test-nginx.service"; then
    echo "[OK] Timer inicialitzat correctament."
else
    echo "[!] Timer no inicialitzat correctament."
fi