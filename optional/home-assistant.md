# Optional — Home Assistant an Claude anbinden (MCP)

Wenn du Home Assistant betreibst und willst, dass Claude deine Smart-Home-Entities
sehen/steuern kann, hängst du HA per **MCP-Server** an Claude Code.

## Empfehlung: `ha-mcp` (nicht der HA-eigene)
👉 **https://github.com/homeassistant-ai/ha-mcp**

Dieser Community-MCP-Server ist **besser als der in Home Assistant eingebaute
MCP-Server** — mehr Funktionsumfang, sauberere Tools, aktiver gepflegt. Nimm den.

## Setup (grob)
1. `ha-mcp` nach dessen README aufsetzen (Docker/Python), Verbindung zu deiner
   HA-Instanz über einen **Long-Lived Access Token** (in HA: Profil → Sicherheit).
2. Den Server in Claude Code als MCP-Server eintragen (in `settings.json` bzw. per
   `.mcp.json`), dann hat Claude Tools wie „Entities listen / Zustand lesen / Service
   aufrufen".

## ⚠️ Sicherheit / Vorsicht
- Der Token gibt Claude **Schreibzugriff** auf dein Smart Home (Lichter, Schlösser,
  Heizung …). Überleg dir, **wie viel Zugriff** du geben willst — du kannst in HA
  einen eigenen Nutzer mit eingeschränkten Rechten für den Token anlegen.
- **Regel für die `CLAUDE.md`** (bewährt): *Vor jeder verändernden HA-Aktion erst ein
  Backup/Snapshot triggern* — und kritische Aktoren (Türschlösser, Alarm) nur nach
  ausdrücklicher Bestätigung schalten.
- HA selbst gehört (wie alles andere) **nicht offen ins Internet** — nur LAN/VPN.
