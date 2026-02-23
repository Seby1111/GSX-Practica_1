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

echo "Cal actualitzar el sistema, voleu fer-ho? (y/n)"

read resposta

if [ "$resposta" = "y" ]; then
    sudo apt update && sudo apt upgrade -y
else
    echo "No s'ha actualitzat el sistema, no es poden executar les següents comandes"
    exit 1
fi

echo "Afegim un nou usuari, voleu fer-ho? (y/n)"

read resposta

if [ "$resposta" = "y" ]; then
    sudo useradd eusebiu
    sudo passwd eusebiu
else
    echo "No s'ha afegit l'usuari 'eusebiu'"
fi

echo "Afegim un nou usuari, voleu fer-ho? (y/n)"

read resposta

if [ "$resposta" = "y" ]; then
    sudo useradd alex
    sudo passwd alex
else
    echo "No s'ha afegit l'usuari 'alex'"
fi

echo "Cal instal·lar el servidor SSH, voleu fer-ho? (y/n)"

read resposta

if [ "$resposta" = "y" ]; then
    sudo apt install openssh-server -y
fi