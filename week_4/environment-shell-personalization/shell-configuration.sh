#!/bin/bash

# Solo para miembros del grupo greendevcorp
if id -nG "$USER" | grep -qw "greendevcorp"; then

    # Configuración compartida del equipo:

    # PATH adicional para scripts del grupo
    export PATH="$PATH:/home/greendevcorp/bin"

    # Alias útiles para todos
    alias ll='ls -la'
    alias gs='git status'
    alias gp='git pull'

    # Set language (Spanish)
    export LANG=es_ES.UTF-8

    # Set timezone
    export TZ=Europe/Madrid

    # Set default editor
    export EDITOR=nano

    # Set default pager
    export PAGER=less
fi