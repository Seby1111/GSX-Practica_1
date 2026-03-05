#!/bin/bash

sudo echo "Comprimint els scripts del set-up inicial..."

cp etc/passwd backup
sudo cp etc/shadow backup
cp etc/group backup
cd backup
tar -czvf backup.tar *