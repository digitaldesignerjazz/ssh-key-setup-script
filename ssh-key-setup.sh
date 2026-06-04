#!/bin/bash
#
# ssh-key-setup.sh
# Sauberes Bash-Skript zur Erzeugung eines starken 4096-Bit RSA SSH-Schlüssels
# und direkten Kopieren auf einen Remote-Server.
#
# Autor: Sven Esslinger
# Version: 1.0
# Lizenz: MIT
#
# Verwendung:
#   ./ssh-key-setup.sh                    # Verwendet Standard-Server
#   ./ssh-key-setup.sh user@mein-server.de   # Mit eigenem Server
#

set -euo pipefail

# === KONFIGURATION ===
KEY_NAME="id_rsa_esslinger"
KEY_PATH="$HOME/.ssh/${KEY_NAME}"
COMMENT="sven@esslinger.company"
DEFAULT_SERVER="sven@www.start-portal.com"

# Server als erstes Argument oder Default
SERVER="${1:-$DEFAULT_SERVER}"

echo "=== SSH Key Setup - 4096 Bit RSA ==="
echo "Zielserver: ${SERVER}"
echo

# Prüfen, ob der Schlüssel bereits existiert
if [[ -f "${KEY_PATH}" ]]; then
    echo "⚠️  Ein Schlüssel mit diesem Namen existiert bereits."
    read -rp "Überschreiben? (j/N) " confirm
    if [[ ! "$confirm" =~ ^[Jj]$ ]]; then
        echo "Abgebrochen."
        exit 0
    fi
    rm -f "${KEY_PATH}" "${KEY_PATH}.pub"
fi

# Neuen 4096-Bit RSA Schlüssel erzeugen
echo "→ Erzeuge starken 4096-Bit RSA Schlüssel..."
ssh-keygen -t rsa -b 4096 -C "${COMMENT}" -f "${KEY_PATH}" -N ""

echo "✔️  Schlüssel erfolgreich erstellt."
echo "   Private Key: ${KEY_PATH}"
echo "   Public Key:  ${KEY_PATH}.pub"
echo

# Schlüssel zum ssh-agent hinzufügen (falls verfügbar)
if command -v ssh-add &> /dev/null; then
    echo "→ Füge Schlüssel zum SSH-Agent hinzu..."
    ssh-add "${KEY_PATH}" 2>/dev/null || echo "   (ssh-agent nicht aktiv oder Schlüssel bereits hinzugefügt)"
fi

echo

# Public Key auf den Server kopieren
echo "→ Kopiere Public Key auf den Server..."
if command -v ssh-copy-id &> /dev/null; then
    ssh-copy-id -i "${KEY_PATH}.pub" "${SERVER}"
else
    echo "ssh-copy-id nicht gefunden. Führe stattdessen manuell aus:"
    echo "ssh ${SERVER} \"mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys\" < ${KEY_PATH}.pub"
fi

echo
echo "✔️  Fertig!"
echo "Du kannst dich jetzt passwortlos verbinden mit:"
echo "  ssh -i ${KEY_PATH} ${SERVER}"
echo