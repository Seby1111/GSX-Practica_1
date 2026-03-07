#!/bin/bash

# Archivo a modificar
JOURNAL_CONF="/etc/systemd/journald.conf"

# Backup del archivo original
sudo cp "$JOURNAL_CONF" "${JOURNAL_CONF}.bak"
echo "Backup creado en ${JOURNAL_CONF}.bak"

# Función para actualizar un valor
update_journal_conf() {
    local key="$1"
    local value="$2"

    # Si la linea está comentada o existe, reemplaza; si no existe, la agrega
    if grep -q "^#\?$key=" "$JOURNAL_CONF"; then
        sudo sed -i "s|^#\?$key=.*|$key=$value|" "$JOURNAL_CONF"
    else
        echo "$key=$value" >> "$JOURNAL_CONF"
    fi
}

# Modificar valores:

# Espacio máximo que pueden ocupar los logs persistentes en disco
update_journal_conf "SystemMaxUse" "200M"
# Mantener siempre libres al menos 1 GB de disco
update_journal_conf "SystemKeepFree" "1G"
# Tamaño máximo por archivo de log antes de rotar
update_journal_conf "SystemMaxFileSize" "20M"
# Número máximo de archivos rotados
update_journal_conf "SystemMaxFiles" "5"
# Espacio máximo para logs temporales (runtime, en RAM)
update_journal_conf "RuntimeMaxUse" "100M"

echo "Configuración de journal.conf actualizada correctamente."