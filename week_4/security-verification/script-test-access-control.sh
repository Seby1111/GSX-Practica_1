#!/bin/bash

echo "[INFO] Comprobando permisos del usuario: $(whoami)"

BASE="/home/greendevcorp"

# -------------------------------
# 1. ROOT
# -------------------------------
if [[ $EUID -eq 0 ]]; then
    echo "[INFO] El usuario es root"
else
    echo "[ERROR] El usuario NO es root"
fi

# -------------------------------
# 2. BIN
# -------------------------------
echo "[INFO] Comprobando /home/greendevcorp/bin"

# Permisos base

if [ -r "$BASE/bin" ]; then
    echo "[INFO] Tiene permiso de lectura en bin"
else
    echo "[ERROR] NO tiene permiso de lectura en bin"
fi

if [ -w "$BASE/bin" ]; then
    echo "[INFO] Tiene permiso de escritura en bin"
else
    echo "[ERROR] NO tiene permiso de escritura en bin"
fi

if [ -x "$BASE/bin" ]; then
    echo "[INFO] Tiene permiso de ejecución en bin"
else
    echo "[ERROR] NO tiene permiso de ejecución en bin"
fi

# Crear

if touch "$BASE/bin/test_file" 2>/dev/null; then
    echo "[INFO] Puede crear ficheros en bin"
    rm -f "$BASE/bin/test_file"
else
    echo "[ERROR] NO puede crear ficheros en bin"
fi

if mkdir "$BASE/bin/test_dir" 2>/dev/null; then
    echo "[INFO] Puede crear directorios en bin"
    rmdir "$BASE/bin/test_dir"
else
    echo "[ERROR] NO puede crear directorios en bin"
fi

# Borrado

touch "$BASE/bin/test_file_self" 2>/dev/null
if rm "$BASE/bin/test_file_self" 2>/dev/null; then
    echo "[INFO] Puede borrar ficheros propios en bin"
else
    echo "[ERROR] NO puede borrar ficheros propios en bin"
fi

touch "$BASE/bin/test_file_other" 2>/dev/null
chown root "$BASE/bin/test_file_other" 2>/dev/null
if rm "$BASE/bin/test_file_other" 2>/dev/null; then
    echo "[INFO] Puede borrar ficheros de otros en bin"
else
    echo "[ERROR] NO puede borrar ficheros de otros en bin"
fi

mkdir "$BASE/bin/test_dir_self" 2>/dev/null
if rmdir "$BASE/bin/test_dir_self" 2>/dev/null; then
    echo "[INFO] Puede borrar directorios propios en bin"
else
    echo "[ERROR] NO puede borrar directorios propios en bin"
fi

mkdir "$BASE/bin/test_dir_other" 2>/dev/null
chown root "$BASE/bin/test_dir_other" 2>/dev/null
if rmdir "$BASE/bin/test_dir_other" 2>/dev/null; then
    echo "[INFO] Puede borrar directorios de otros en bin"
else
    echo "[ERROR] NO puede borrar directorios de otros en bin"
fi

# -------------------------------
# 3. SHARED
# -------------------------------
echo "[INFO] Comprobando /home/greendevcorp/shared"

# Permisos base

if [ -r "$BASE/shared" ]; then
    echo "[INFO] Tiene permiso de lectura en shared"
else
    echo "[ERROR] NO tiene permiso de lectura en shared"
fi

if [ -w "$BASE/shared" ]; then
    echo "[INFO] Tiene permiso de escritura en shared"
else
    echo "[ERROR] NO tiene permiso de escritura en shared"
fi

if [ -x "$BASE/shared" ]; then
    echo "[INFO] Tiene permiso de ejecución en shared"
else
    echo "[ERROR] NO tiene permiso de ejecución en shared"
fi

# Crear

if touch "$BASE/shared/test_file" 2>/dev/null; then
    echo "[INFO] Puede crear ficheros en shared"
    rm -f "$BASE/shared/test_file"
else
    echo "[ERROR] NO puede crear ficheros en shared"
fi

if mkdir "$BASE/shared/test_dir" 2>/dev/null; then
    echo "[INFO] Puede crear directorios en shared"
    rmdir "$BASE/shared/test_dir"
else
    echo "[ERROR] NO puede crear directorios en shared"
fi

# Borrado

touch "$BASE/shared/test_file_self" 2>/dev/null
if rm "$BASE/shared/test_file_self" 2>/dev/null; then
    echo "[INFO] Puede borrar ficheros propios en shared"
else
    echo "[ERROR] NO puede borrar ficheros propios en shared"
fi

touch "$BASE/shared/test_file_other" 2>/dev/null
chown root "$BASE/shared/test_file_other" 2>/dev/null
if rm "$BASE/shared/test_file_other" 2>/dev/null; then
    echo "[INFO] Puede borrar ficheros de otros en shared"
else
    echo "[ERROR] NO puede borrar ficheros de otros en shared"
fi

mkdir "$BASE/shared/test_dir_self" 2>/dev/null
if rmdir "$BASE/shared/test_dir_self" 2>/dev/null; then
    echo "[INFO] Puede borrar directorios propios en shared"
else
    echo "[ERROR] NO puede borrar directorios propios en shared"
fi

mkdir "$BASE/shared/test_dir_other" 2>/dev/null
chown root "$BASE/shared/test_dir_other" 2>/dev/null
if rmdir "$BASE/shared/test_dir_other" 2>/dev/null; then
    echo "[INFO] Puede borrar directorios de otros en shared"
else
    echo "[ERROR] NO puede borrar directorios de otros en shared"
fi


# -------------------------------
# 4. DONE.LOG
# -------------------------------
echo "[INFO] Comprobando /home/greendevcorp/done.log"

FILE="$BASE/done.log"

# Permisos base

if [ -r "$FILE" ]; then
    echo "[INFO] Tiene permiso de lectura en done.log"
else
    echo "[ERROR] NO tiene permiso de lectura en done.log"
fi

if [ -w "$FILE" ]; then
    echo "[INFO] Tiene permiso de escritura en done.log"
else
    echo "[ERROR] NO tiene permiso de escritura en done.log"
fi

if [ -x "$FILE" ]; then
    echo "[INFO] Tiene permiso de ejecución en done.log"
else
    echo "[ERROR] NO tiene permiso de ejecución en done.log"
fi

# Crear

if touch "$BASE/done_test_file" 2>/dev/null; then
    echo "[INFO] Puede crear ficheros en done.log"
    rm -f "$BASE/done_test_file"
else
    echo "[ERROR] NO puede crear ficheros en done.log"
fi

if mkdir "$BASE/done_test_dir" 2>/dev/null; then
    echo "[INFO] Puede crear directorios en done.log"
    rmdir "$BASE/done_test_dir"
else
    echo "[ERROR] NO puede crear directorios en done.log"
fi

# Borrado

touch "$BASE/done_test_self.log" 2>/dev/null
if rm "$BASE/done_test_self.log" 2>/dev/null; then
    echo "[INFO] Puede borrar ficheros propios en done.log"
else
    echo "[ERROR] NO puede borrar ficheros propios en done.log"
fi

touch "$BASE/done_test_other.log" 2>/dev/null
chown root "$BASE/done_test_other.log" 2>/dev/null
if rm "$BASE/done_test_other.log" 2>/dev/null; then
    echo "[INFO] Puede borrar ficheros de otros en done.log"
else
    echo "[ERROR] NO puede borrar ficheros de otros en done.log"
fi