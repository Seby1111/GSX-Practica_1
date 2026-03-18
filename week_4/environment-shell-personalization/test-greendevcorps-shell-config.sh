#!/bin/bash

# Nombre del usuario de prueba (dentro del grupo)

TEST_USER="nuevo_usuario"

# Crear usuario solo si no existe
if ! id "$TEST_USER" >/dev/null 2>&1; then
    sudo useradd -m -G greendevcorp "$TEST_USER"
    echo "$TEST_USER:root" | sudo chpasswd
    echo "[INFO] Usuario $TEST_USER creado y agregado al grupo greendevcorp"
else
    echo "[INFO] Usuario $TEST_USER ya existe"
fi

echo "[INFO] Probando entorno de usuario $TEST_USER..."

TMP_SCRIPT=tmp

# Ejecutar un shell de login para el usuario de prueba y verificar variables
cat << 'EOF' > $TMP_SCRIPT
echo "[INFO] PATH: $PATH"
echo "[INFO] LANG: $LANG"
echo "[INFO] TZ: $TZ"
echo "[INFO] EDITOR: $EDITOR"
echo "[INFO] PAGER: $PAGER"

# Probar alias ll
if alias ll >/dev/null 2>&1; then
    echo "[INFO] Alias ll está presente"
else
    echo "[ERROR] Alias ll NO está presente"
fi

# Probar alias git status
if alias gs >/dev/null 2>&1; then
    echo "[INFO] Alias gs está presente"
else
    echo "[ERROR] Alias gs NO está presente"
fi
EOF

chmod 777 $TMP_SCRIPT

sudo -u "$TEST_USER" bash -l $TMP_SCRIPT

# =========================================================

# Nombre del usuario de prueba (fuera del grupo)

TEST_USER="nuevo_usuario2"

# Crear usuario solo si no existe
if ! id "$TEST_USER" >/dev/null 2>&1; then
    sudo useradd -m "$TEST_USER"
    echo "$TEST_USER:root" | sudo chpasswd
    echo "[INFO] Usuario $TEST_USER creado"
else
    echo "[INFO] Usuario $TEST_USER ya existe"
fi

echo "[INFO] Probando entorno de usuario $TEST_USER..."

# Ejecutar un shell de login para el usuario de prueba y verificar variables

sudo -u "$TEST_USER" bash -l $TMP_SCRIPT

rm -f $TMP_SCRIPT

sudo pkill -u nuevo_usuario
sudo pkill -u nuevo_usuario2

sudo userdel -r nuevo_usuario 2> /dev/null
sudo userdel -r nuevo_usuario2 2> /dev/null