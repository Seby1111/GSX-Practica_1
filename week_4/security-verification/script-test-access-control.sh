#!/bin/bash

echo "[INFO] Comprovant permisos de l'usuari: $(whoami)"

BASE="/home/greendevcorp"

# -------------------------------
# 1. ROOT
# -------------------------------
if [[ $EUID -eq 0 ]]; then
    echo "[INFO] L'usuari és root"
else
    echo "[ERROR] L'usuari NO és root"
fi

# -------------------------------
# 2. BIN
# -------------------------------
echo "[INFO] Comprovant /home/greendevcorp/bin"

# Permisos base

if [ -r "$BASE/bin" ]; then
    echo "[INFO] Té permís de lectura a bin"
else
    echo "[ERROR] NO té permís de lectura a bin"
fi

if [ -w "$BASE/bin" ]; then
    echo "[INFO] Té permís d'escriptura a bin"
else
    echo "[ERROR] NO té permís d'escriptura a bin"
fi

if [ -x "$BASE/bin" ]; then
    echo "[INFO] Té permís d'execució a bin"
else
    echo "[ERROR] NO té permís d'execució a bin"
fi

# Crear

if touch "$BASE/bin/test_file" 2>/dev/null; then
    echo "[INFO] Pot crear fitxers a bin"
    rm -f "$BASE/bin/test_file"
else
    echo "[ERROR] NO pot crear fitxers a bin"
fi

if mkdir "$BASE/bin/test_dir" 2>/dev/null; then
    echo "[INFO] Pot crear directoris a bin"
    rmdir "$BASE/bin/test_dir"
else
    echo "[ERROR] NO pot crear directoris a bin"
fi

# Borrat

touch "$BASE/bin/test_file_self" 2>/dev/null
if rm "$BASE/bin/test_file_self" 2>/dev/null; then
    echo "[INFO] Pot esborrar fitxers propis a bin"
else
    echo "[ERROR] NO pot esborrar fitxers propis a bin"
fi

touch "$BASE/bin/test_file_other" 2>/dev/null
chown root "$BASE/bin/test_file_other" 2>/dev/null
if rm "$BASE/bin/test_file_other" 2>/dev/null; then
    echo "[INFO] Pot esborrar fitxers d'altres a bin"
else
    echo "[ERROR] NO pot esborrar fitxers d'altres a bin"
fi

mkdir "$BASE/bin/test_dir_self" 2>/dev/null
if rmdir "$BASE/bin/test_dir_self" 2>/dev/null; then
    echo "[INFO] Pot esborrar directoris propis a bin"
else
    echo "[ERROR] NO pot esborrar directoris propis a bin"
fi

mkdir "$BASE/bin/test_dir_other" 2>/dev/null
chown root "$BASE/bin/test_dir_other" 2>/dev/null
if rmdir "$BASE/bin/test_dir_other" 2>/dev/null; then
    echo "[INFO] Pot esborrar directoris d'altres a bin"
else
    echo "[ERROR] NO pot esborrar directoris d'altres a bin"
fi

# -------------------------------
# 3. SHARED
# -------------------------------
echo "[INFO] Comprovant /home/greendevcorp/shared"

# Permisos base

if [ -r "$BASE/shared" ]; then
    echo "[INFO] Té permís de lectura a shared"
else
    echo "[ERROR] NO té permís de lectura a shared"
fi

if [ -w "$BASE/shared" ]; then
    echo "[INFO] Té permís d'escriptura a shared"
else
    echo "[ERROR] NO té permís d'escriptura a shared"
fi

if [ -x "$BASE/shared" ]; then
    echo "[INFO] Té permís d'execució a shared"
else
    echo "[ERROR] NO té permís d'execució a shared"
fi

# Crear

if touch "$BASE/shared/test_file" 2>/dev/null; then
    echo "[INFO] Pot crear fitxers a shared"
    rm -f "$BASE/shared/test_file"
else
    echo "[ERROR] NO pot crear fitxers a shared"
fi

if mkdir "$BASE/shared/test_dir" 2>/dev/null; then
    echo "[INFO] Pot crear directoris a shared"
    rmdir "$BASE/shared/test_dir"
else
    echo "[ERROR] NO pot crear directoris a shared"
fi

# Borrat

touch "$BASE/shared/test_file_self" 2>/dev/null
if rm "$BASE/shared/test_file_self" 2>/dev/null; then
    echo "[INFO] Pot esborrar fitxers propis a shared"
else
    echo "[ERROR] NO pot esborrar fitxers propis a shared"
fi

touch "$BASE/shared/test_file_other" 2>/dev/null
chown root "$BASE/shared/test_file_other" 2>/dev/null
if rm "$BASE/shared/test_file_other" 2>/dev/null; then
    echo "[INFO] Pot esborrar fitxers d'altres a shared"
else
    echo "[ERROR] NO pot esborrar fitxers d'altres a shared"
fi

mkdir "$BASE/shared/test_dir_self" 2>/dev/null
if rmdir "$BASE/shared/test_dir_self" 2>/dev/null; then
    echo "[INFO] Pot esborrar directoris propis a shared"
else
    echo "[ERROR] NO pot esborrar directoris propis a shared"
fi

mkdir "$BASE/shared/test_dir_other" 2>/dev/null
chown root "$BASE/shared/test_dir_other" 2>/dev/null
if rmdir "$BASE/shared/test_dir_other" 2>/dev/null; then
    echo "[INFO] Pot esborrar directoris d'altres a shared"
else
    echo "[ERROR] NO pot esborrar directoris d'altres a shared"
fi

# -------------------------------
# 4. DONE.LOG
# -------------------------------
echo "[INFO] Comprovant /home/greendevcorp/done.log"

FILE="$BASE/done.log"

# Permisos base

if [ -r "$FILE" ]; then
    echo "[INFO] Té permís de lectura a done.log"
else
    echo "[ERROR] NO té permís de lectura a done.log"
fi

if [ -w "$FILE" ]; then
    echo "[INFO] Té permís d'escriptura a done.log"
else
    echo "[ERROR] NO té permís d'escriptura a done.log"
fi

if [ -x "$FILE" ]; then
    echo "[INFO] Té permís d'execució a done.log"
else
    echo "[ERROR] NO té permís d'execució a done.log"
fi

# Crear

if touch "$BASE/done_test_file" 2>/dev/null; then
    echo "[INFO] Pot crear fitxers a done.log"
    rm -f "$BASE/done_test_file"
else
    echo "[ERROR] NO pot crear fitxers a done.log"
fi

if mkdir "$BASE/done_test_dir" 2>/dev/null; then
    echo "[INFO] Pot crear directoris a done.log"
    rmdir "$BASE/done_test_dir"
else
    echo "[ERROR] NO pot crear directoris a done.log"
fi

# Borrat

touch "$BASE/done_test_self.log" 2>/dev/null
if rm "$BASE/done_test_self.log" 2>/dev/null; then
    echo "[INFO] Pot esborrar fitxers propis a done.log"
else
    echo "[ERROR] NO pot esborrar fitxers propis a done.log"
fi

touch "$BASE/done_test_other.log" 2>/dev/null
chown root "$BASE/done_test_other.log" 2>/dev/null
if rm "$BASE/done_test_other.log" 2>/dev/null; then
    echo "[INFO] Pot esborrar fitxers d'altres a done.log"
else
    echo "[ERROR] NO pot esborrar fitxers d'altres a done.log"
fi