#!/bin/bash

# Fitxer a modificar
JOURNAL_CONF="/etc/systemd/journald.conf"

# Backup del fitxer original
sudo cp "$JOURNAL_CONF" "${JOURNAL_CONF}.bak"
echo "Backup creat a ${JOURNAL_CONF}.bak"

# Funció per actualitzar un valor
update_journal_conf() {
    local key="$1"
    local value="$2"

    # Si la línia està comentada o existeix, reemplaça; si no existeix, l'afegeix
    if grep -q "^#\?$key=" "$JOURNAL_CONF"; then
        sudo sed -i "s|^#\?$key=.*|$key=$value|" "$JOURNAL_CONF"
    else
        echo "$key=$value" >> "$JOURNAL_CONF"
    fi
}

# Modificar valors:

# Espai màxim que poden ocupar els logs persistents en disc
update_journal_conf "SystemMaxUse" "200M"
# Mantenir sempre lliures almenys 1 GB de disc
update_journal_conf "SystemKeepFree" "1G"
# Mida màxima per fitxer de log abans de rotar
update_journal_conf "SystemMaxFileSize" "20M"
# Nombre màxim de fitxers rotats
update_journal_conf "SystemMaxFiles" "5"
# Espai màxim per logs temporals (runtime, en RAM)
update_journal_conf "RuntimeMaxUse" "100M"

echo "Configuracio de journal.conf actualitzada correctament."