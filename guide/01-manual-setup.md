# Teil A — Manuelles Setup (Schritt 1–3)

Das hier macht ein **Mensch** als `root` auf dem LXC. Danach übernimmt Claude
selbst (Teil B). Dauert ~10 Minuten.

> Platzhalter: ersetze `CLAUDEUSER` durch den gewünschten Login-Namen
> (z. B. `cadmin`, `claude`, `hadmin` …). Halte ihn kurz und lowercase.

> 💡 **Tipp — LXC anlegen:** Wenn du den Container noch nicht hast, sind die
> community **Proxmox VE Helper-Scripts** (https://community-scripts.github.io/ProxmoxVE/)
> der bequemste Weg — sauber vorkonfigurierte LXCs und **deutlich einfachere
> Updates** später. Für Dienste wie Forgejo (siehe optional/forgejo.md) gibt es
> dort fertige Installer-Scripts.

---

## Schritt 1 — User mit passwordless sudo anlegen

```bash
# als root auf dem LXC
USERNAME=cadmin          # <-- anpassen

# User + Home + Shell
useradd -m -s /bin/bash "$USERNAME"

# (optional) Passwort setzen, falls du dich auch direkt einloggen willst
# passwd "$USERNAME"

# passwordless sudo (eigene Datei in sudoers.d, nicht /etc/sudoers editieren!)
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME
chmod 440 /etc/sudoers.d/$USERNAME
visudo -c                # Syntax prüfen — MUSS "parsed OK" sagen

# systemd --user ohne aktiven Login erlauben (sonst stirbt die Instanz beim Logout)
loginctl enable-linger "$USERNAME"

# Dedizierter Arbeitsordner (NICHT das Home-Verzeichnis! siehe Kasten unten)
WORKDIR=/opt/claude        # <-- frei wählbar, aber nicht /home/$USERNAME
mkdir -p "$WORKDIR"
chown "$USERNAME:$USERNAME" "$WORKDIR"
```

> ⚠️ **Claude NIE im Home-Verzeichnis (`/home/$USERNAME`) laufen lassen.** Claude
> Code stuft das Home als sensibel ein und fragt **bei jedem Start** nach
> Verzeichnis-Trust — das blockiert den unbeaufsichtigten systemd-Autostart. Nutze
> einen **dedizierten Ordner** (oben `/opt/claude`) als WORKDIR. Dort wird der
> Trust einmal bestätigt und persistiert. (Der einmalige Auth-Login in Schritt 3
> darf im Home passieren — nur die *persistente* Instanz braucht den eigenen Ordner.)

**Warum `sudoers.d` statt `/etc/sudoers`:** isolierte Datei, ein kaputter Eintrag
sperrt dich nicht aus dem ganzen sudo-System. `visudo -c` validiert *alle*
sudoers-Dateien — immer ausführen, bevor du die Session schließt.

**Warum `enable-linger`:** ohne das beendet systemd alle `--user`-Services, sobald
sich der User ausloggt. Mit Linger läuft der systemd-User-Manager dauerhaft → die
Claude-Instanz überlebt und startet beim Reboot automatisch.

---

## Schritt 2 — Node.js + Claude Code installieren

Claude Code braucht Node ≥ 18. Je nach Distro:

**Debian / Ubuntu (häufigster Proxmox-LXC):**
```bash
# NodeSource 20 — das Distro-apt-node ist oft zu alt (18.19)
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
```

**Arch / CachyOS:**
```bash
# OHNE -Sy, um Partial-Upgrade-Bruch zu vermeiden
pacman -S --needed --noconfirm nodejs npm
```

**Dann Claude Code system-weit (als root):**
```bash
npm install -g @anthropic-ai/claude-code
which claude          # -> /usr/bin/claude oder /usr/local/bin/claude
claude --version
```

> System-weit (`-g` als root) heißt: alle User auf der Box teilen *dasselbe*
> claude-Binary. Sauberer als pro-User-Installs.

---

## Schritt 3 — Einloggen (Account-Auth)

Jetzt als der neue User, **interaktiv** (das ist der eine Schritt, der einen
Menschen + Browser braucht):

```bash
# als root:
su - cadmin            # <-- dein USERNAME

# als cadmin:
claude
```

Beim ersten Start:
1. **Login** — Claude zeigt einen Device-Flow-Link. Im Browser öffnen, mit deinem
   Claude-Account (Pro/Max) bestätigen, den Code zurück in die Konsole.
2. **Onboarding** — Theme, Trust-Folder-Frage etc. durchklicken.
3. Du landest im interaktiven Claude-Prompt.

**Das war der manuelle Teil.** Diese Session ist eingeloggt und arbeitsbereit,
aber noch **nicht persistent** (schließt du das Terminal, ist sie weg).

➡️ **Weiter mit Teil B:** Gib *dieser* Session jetzt den Bootstrap-Prompt aus
[`02-claude-bootstrap-prompt.md`](02-claude-bootstrap-prompt.md). Claude richtet
dann Persistenz (systemd/tmux), die Selbst-Reset-Skripte und die `CLAUDE.md`
selbst ein.

---

### Notizen / Stolpersteine
- **Trust-Folder-Prompt** kann auch bei `bypassPermissions` 1× erscheinen → einmal
  bestätigen, danach persistiert er.
- Kommt „command not found: claude" für den neuen User: prüfe, ob `npm`-global-bin
  im PATH ist (`npm config get prefix` → meist `/usr` oder `/usr/local`).
- Auf sehr neuen Node-Versionen (Arch, 26.x) läuft claude-code sauber — keine Sorge.
