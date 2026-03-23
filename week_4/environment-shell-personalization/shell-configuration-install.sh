#!/bin/bash

arxiu="/etc/profile.d/greendevcorp-shell-configuration.sh"

if [ ! -f "$arxiu" ]; then
    echo "Creant greendevcorp-shell-configuration.sh..."

    sudo tee "$arxiu" > /dev/null << 'EOF'
#!/bin/bash

# Només per a membres del grup greendevcorp
if id -nG "$USER" | grep -qw "greendevcorp"; then

    # Configuració compartida de l'equip:

    # PATH addicional per a scripts del grup
    export PATH="$PATH:/home/greendevcorp/bin"

    # Alias útils per a tothom
    alias ll='ls -la'
    alias gs='git status'
    alias gp='git pull'

    # Configuració de llengua (espanyol)
    export LANG=es_ES.UTF-8

    # Configuració de zona horària
    export TZ=Europe/Madrid

    # Editor per defecte
    export EDITOR=nano

    # Pager per defecte
    export PAGER=less
fi
EOF
    # Lectura per als membres del grup, escriptura només per root
    sudo chmod 640 /etc/profile.d/greendevcorp-shell-configuration.sh
fi