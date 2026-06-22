# Claude-Code Starter-Kit — persistente, selbst-bootstrappende Instanz auf einem LXC

Ein abgespeckter, **credential-freier** Grundbaustein, um Claude Code als
*persistente* Instanz auf einem LXC (oder jeder Linux-Box) laufen zu lassen —
so wie die Homelab-Flotte, nur ohne den Flotten-Überbau (MQTT-Bus, mem0,
Heartbeat sind hier **optional** bzw. weggelassen).

> Validiertes Vorbild: das Fleet-Bootstrap-Playbook. Hier auf das Wesentliche
> reduziert: **ein** User, **eine** persistente Session, Selbst-Reset mit
> Kontinuität, bewährte Arbeitsregeln, Remote-Admin weiterer LXCs.

## Was du am Ende hast
- Einen eigenen Linux-User mit passwordless sudo, Claude Code installiert & eingeloggt.
- Eine **persistente** Claude-Session (systemd → tmux), die LXC-Reboots übersteht
  und sich per `--continue` selbst fortsetzt.
- **`selfclear` / `selfcompact` / `handoff`** — die Instanz kann sich selbst
  zurücksetzen, ohne den Arbeitsfaden zu verlieren.
- Eine `CLAUDE.md` mit den **bewährten Arbeitsregeln** (löschen nur nach Rückfrage,
  bei Volatilem recherchieren, nicht raten sondern in Code/Config nachsehen …).
- Einen **Oneliner**, um auf *weiteren* LXCs denselben Admin-User + SSH-Key
  auszurollen → danach Remote-Administration per SSH wie im Homelab.

## Die drei Teile

| Teil | Datei | Wer macht's |
|---|---|---|
| **A — Manuelles Setup** (Schritt 1–3) | [`guide/01-manual-setup.md`](guide/01-manual-setup.md) | Mensch am LXC |
| **B — Selbst-Bootstrap** (Schritt 4+) | [`guide/02-claude-bootstrap-prompt.md`](guide/02-claude-bootstrap-prompt.md) | Claude selbst |
| **C — Weitere LXCs anbinden** | [`scripts/provision-lxc-user.sh`](scripts/provision-lxc-user.sh) | Oneliner |

**Kernidee:** Schritt 1–3 (User anlegen, Claude installieren, einloggen) braucht
einen Menschen. **Ab Schritt 4 übernimmt Claude sich selbst** — du gibst der
frisch eingeloggten Session den Bootstrap-Prompt aus Teil B, und sie richtet
Persistenz, die Selbst-Reset-Skripte und die `CLAUDE.md` eigenständig ein.

## Zwei Entscheidungen vorab (frag dich / frag Claude)

1. **Wie steuerst du die Instanz?**
   - **SSH + tmux** (Standard, simpel, Pro-tauglich): du SSHst auf den LXC und
     `tmux attach`. Reicht für fast alles.
   - **Web-Fernsteuerung** (`--remote-control`, claude.ai): die Instanz über den
     Browser steuern. Setzt voraus, dass dein Account-Tier das kann. Details +
     der **Session-ID-Kollisions-Fix** (wenn du *zwei* Instanzen unter *einem*
     User willst): [`optional/remote-control.md`](optional/remote-control.md).

2. **Brauchst du ein Langzeitgedächtnis (mem0)?**
   - Für den Einstieg **nein**. Die `CLAUDE.md` + `handoff` reichen weit.
   - Wenn später „die Instanz soll sich über Sessions hinweg an Fakten erinnern":
     [`optional/mem0/README.md`](optional/mem0/README.md) — inkl. unserer hart
     erkauften Tuning-/Bug-Lehren.

## Empfehlenswerte Erweiterungen (optional)
- **Forgejo — lokales Git als „Claudes baby"** → [`optional/forgejo.md`](optional/forgejo.md).
  Eigener LAN-Git-Server, auf dem Claude selbstständig Repos anlegt und pusht.
  ⚠️ **Nie ins Internet exposen** — nur LAN. Sehr empfehlenswert.
- **mem0 — Langzeitgedächtnis** → [`optional/mem0/README.md`](optional/mem0/README.md).
- **Web-Fernsteuerung** → [`optional/remote-control.md`](optional/remote-control.md).
- **claude2mqtt — Nachrichten-Bus** (Instanzen reden miteinander; Basis für Heartbeat)
  → [`optional/claude2mqtt.md`](optional/claude2mqtt.md). ⚠️ LAN-only.
- **Heartbeat — zeitgesteuertes Wecken** (Cron-Ersatz, der die Session weckt; inkl.
  Watchdog-Idee) → [`optional/heartbeat.md`](optional/heartbeat.md). Braucht claude2mqtt.
- **Inventar — erzähl Claude, was du hast** (+ Zugriff bewusst staffeln)
  → [`optional/inventory.md`](optional/inventory.md). Leichtgewichtig, guter Start.
- **Projekt-Template** (`project.md` als lebendes Handbuch pro Projekt)
  → [`optional/project-template.md`](optional/project-template.md). Hält den Faden + Scope.
- **Home Assistant anbinden** (empfohlener MCP: `ha-mcp`, besser als der HA-eigene)
  → [`optional/home-assistant.md`](optional/home-assistant.md).
- **`claude-light` — günstiges Modell als Worker** (MiniMax; spart Kontingent)
  → [`optional/claude-light.md`](optional/claude-light.md). Braucht MiniMax-Plan.
- **Proxmox VE Helper-Scripts** (https://community-scripts.github.io/ProxmoxVE/) für
  LXCs (Claude-Host, Forgejo …) — sauberes Anlegen + **einfachere Updates**.

## Quickstart
```bash
# 1. Auf dem LXC (als root): User + sudo + Node + Claude + dedizierter WORKDIR — guide/01
#    (WICHTIG: Claude NICHT im Home laufen lassen — sonst Trust-Prompt bei jedem Start)
# 2. Als neuer User einloggen, `claude` starten, Account-Login durchziehen
# 3. Repo klonen + dieser frischen Session den Prompt aus guide/02 geben → sie bootstrapt sich
#    git clone https://github.com/bennizone/claude-admin.git ~/claude-admin
```

Reihenfolge strikt: **erst** Teil A (Mensch), **dann** Teil B (Claude). Teil C
und die Optionals jederzeit danach.
