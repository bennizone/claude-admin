# Optional (Empfehlung) — Forgejo als lokales Git für Claude

Eine der besten Erweiterungen aus dem Homelab-Setup: ein **lokaler Git-Server**
(Forgejo — leichtgewichtiger GitHub-Klon), der **Claudes eigenes Spielfeld** ist.
Damit kann die Instanz **selbstständig** Repos anlegen, committen und pushen —
ohne dass du für jede Kleinigkeit ein GitHub-Repo aufmachen musst.

## Warum
- **Autonomie:** Claude legt Repos an, wie es am sinnvollsten ist (pro Projekt,
  pro Experiment), versioniert seine Arbeit und pusht eigenständig — solange alles
  **im lokalen LAN** bleibt.
- **Sicheres Netz statt nur Working-Tree:** Versionierung + Historie + Branches,
  ohne dass etwas das Heimnetz verlässt.
- **Klare Trennung:** lokales Forgejo = autonom; öffentliches GitHub = nur nach
  ausdrücklichem „GO" und nur für das, was wirklich raus soll.

## ⚠️ WICHTIG — Sicherheit
- **NIEMALS ins Internet exposen.** Kein Port-Forwarding, kein öffentliches
  Reverse-Proxy, keine Domain nach außen. Forgejo ist **nur im LAN** erreichbar.
- Erreichbarkeit auf das interne Netz beschränken (Firewall / nur LAN-Interface
  binden). Wenn Remote-Zugriff nötig: über VPN (z. B. WireGuard/Tailscale) ins
  Heimnetz, nicht über offene Ports.
- Zugangsdaten/Tokens nur lokal; nichts davon in öffentliche Repos.

## Aufsetzen
- Am einfachsten via **Proxmox VE Helper-Script** für Forgejo
  (https://community-scripts.github.io/ProxmoxVE/) → eigener kleiner LXC, fertig
  vorkonfiguriert, einfache Updates. Alternativ Docker/Binary nach offizieller
  Forgejo-Doku.
- Danach für die Claude-Instanz: einen User/Token in Forgejo anlegen, SSH-Key der
  Instanz hinterlegen (oder HTTP-Token), `git remote add origin
  http://<forgejo-lan-ip>:3000/<user>/<repo>.git`.

## Git-Policy (bewährt) — in die CLAUDE.md aufnehmen
> **Lokales Forgejo: Auto-Push ok** (Claude pusht selbstständig, wann sinnvoll —
> es bleibt im LAN). **Öffentliches GitHub o. Ä.: nur nach ausdrücklichem GO**
> und nur für bewusst-öffentliches Material. `git push --all` vermeiden.

Diese eine Regel verhindert das Hauptrisiko (versehentlich Privates öffentlich
pushen) und lässt Claude trotzdem lokal voll autonom arbeiten.
