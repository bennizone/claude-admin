#!/usr/bin/env bash
# provision-lxc-user.sh — lege auf einem (weiteren) LXC/Host einen passwordless-sudo
# Admin-User mit deinem SSH-Public-Key an. Danach erreichst du den Host per SSH und
# kannst ihn mit Claude fernadministrieren (so wie die Homelab-Flotte ihre Hosts).
#
# AUSFÜHREN ALS ROOT AUF DEM ZIEL-HOST. Drei bequeme Wege:
#
#   # (a) direkt auf dem Ziel (root-Shell):
#   USERNAME=cadmin PUBKEY="ssh-ed25519 AAAA... du@box" bash provision-lxc-user.sh
#
#   # (b) von Proxmox-Host in einen Container (kein SSH nötig):
#   pct exec <VMID> -- bash -c "USERNAME=cadmin PUBKEY='ssh-ed25519 AAAA...' bash -s" < provision-lxc-user.sh
#
#   # (c) per SSH als root auf den Ziel-Host pushen:
#   ssh root@ziel "USERNAME=cadmin PUBKEY='$(cat ~/.ssh/id_ed25519.pub)' bash -s" < provision-lxc-user.sh
#
# Variablen:
#   USERNAME  (Default: cadmin)   — anzulegender Admin-User
#   PUBKEY    (Pflicht)           — dein SSH-Public-Key (eine Zeile)
#   SHELL_BIN (Default: /bin/bash)
set -euo pipefail

USERNAME="${USERNAME:-cadmin}"
SHELL_BIN="${SHELL_BIN:-/bin/bash}"
PUBKEY="${PUBKEY:-}"

[ "$(id -u)" -eq 0 ] || { echo "FEHLER: muss als root laufen." >&2; exit 1; }
[ -n "$PUBKEY" ]       || { echo "FEHLER: PUBKEY ist Pflicht (dein SSH-Public-Key)." >&2; exit 1; }
case "$PUBKEY" in ssh-*|ecdsa-*) : ;; *) echo "FEHLER: PUBKEY sieht nicht nach einem SSH-Key aus." >&2; exit 1;; esac

echo ">> User '$USERNAME' anlegen (falls nicht vorhanden)"
if ! id "$USERNAME" >/dev/null 2>&1; then
  useradd -m -s "$SHELL_BIN" "$USERNAME"
else
  echo "   existiert bereits — überspringe useradd"
fi

echo ">> passwordless sudo"
printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$USERNAME" > "/etc/sudoers.d/$USERNAME"
chmod 440 "/etc/sudoers.d/$USERNAME"
visudo -c >/dev/null || { echo "FEHLER: sudoers-Syntax kaputt — Datei wird entfernt." >&2; rm -f "/etc/sudoers.d/$USERNAME"; exit 1; }

echo ">> SSH-Key installieren"
HOME_DIR="$(getent passwd "$USERNAME" | cut -d: -f6)"
install -d -m 700 -o "$USERNAME" -g "$USERNAME" "$HOME_DIR/.ssh"
AUTH="$HOME_DIR/.ssh/authorized_keys"
touch "$AUTH"
# idempotent: Key nur hinzufügen, wenn noch nicht drin
if ! grep -qF "$PUBKEY" "$AUTH" 2>/dev/null; then
  printf '%s\n' "$PUBKEY" >> "$AUTH"
  echo "   Key hinzugefügt"
else
  echo "   Key bereits vorhanden"
fi
chown "$USERNAME:$USERNAME" "$AUTH"
chmod 600 "$AUTH"

echo ">> systemd-linger (damit spätere --user-Services überleben)"
loginctl enable-linger "$USERNAME" 2>/dev/null || echo "   (loginctl nicht verfügbar — überspringe; nur nötig, wenn dieser Host selbst eine Instanz hostet)"

echo
echo "FERTIG. Test von deiner Admin-Box aus:"
echo "   ssh $USERNAME@<diese-host-ip>"
echo "   ssh $USERNAME@<diese-host-ip> sudo whoami    # -> root"
