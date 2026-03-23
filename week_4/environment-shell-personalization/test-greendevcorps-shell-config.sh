#!/bin/bash

# Nom de l'usuari de prova (dins del grup)

TEST_USER="nuevo_usuario"

# Crear usuari només si no existeix
if ! id "$TEST_USER" >/dev/null 2>&1; then
    sudo useradd -m -G greendevcorp "$TEST_USER"
    echo "$TEST_USER:root" | sudo chpasswd
    echo "[INFO] Usuari $TEST_USER creat i afegit al grup greendevcorp"
else
    echo "[INFO] Usuari $TEST_USER ja existeix"
fi

echo "[INFO] Provant entorn d'usuari $TEST_USER..."

TMP_SCRIPT=tmp

# Executar un shell de login per a l'usuari de prova i verificar variables
cat << 'EOF' > $TMP_SCRIPT
echo "[INFO] PATH: $PATH"
echo "[INFO] LANG: $LANG"
echo "[INFO] TZ: $TZ"
echo "[INFO] EDITOR: $EDITOR"
echo "[INFO] PAGER: $PAGER"

# Provar alias ll
if alias ll >/dev/null 2>&1; then
    echo "[INFO] Alias ll està present"
else
    echo "[ERROR] Alias ll NO està present"
fi

# Provar alias git status
if alias gs >/dev/null 2>&1; then
    echo "[INFO] Alias gs està present"
else
    echo "[ERROR] Alias gs NO està present"
fi
EOF

chmod 777 $TMP_SCRIPT

sudo -u "$TEST_USER" bash -l $TMP_SCRIPT

# =========================================================

# Nom de l'usuari de prova (fora del grup)

TEST_USER="nuevo_usuario2"

# Crear usuari només si no existeix
if ! id "$TEST_USER" >/dev/null 2>&1; then
    sudo useradd -m "$TEST_USER"
    echo "$TEST_USER:root" | sudo chpasswd
    echo "[INFO] Usuari $TEST_USER creat"
else
    echo "[INFO] Usuari $TEST_USER ja existeix"
fi

echo "[INFO] Provant entorn d'usuari $TEST_USER..."

# Executar un shell de login per a l'usuari de prova i verificar variables

sudo -u "$TEST_USER" bash -l $TMP_SCRIPT

rm -f $TMP_SCRIPT

sudo pkill -u nuevo_usuario
sudo pkill -u nuevo_usuario2

sudo userdel -r nuevo_usuario 2> /dev/null
sudo userdel -r nuevo_usuario2 2> /dev/null