#!/bin/bash

sudo > /dev/null 2> /dev/null

status=$?

if [ $status -eq 127 ]; then
    echo "'sudo' no trobat, doneu permis per instal·lar-lo? (y/n)"
    read resposta

    if [ "$resposta" = "y" ]; then
        su
        apt install sudo -y
        exit
    else
        echo "No s'ha instal·lat 'sudo', no es poden executar les següents comandes"
        exit 1
    fi
fi

echo "S'ha trobat sudo"


#sudo apt update && sudo apt upgrade -y

#sudo apt install openssh-server -y