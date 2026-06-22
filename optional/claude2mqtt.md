# Optional (fortgeschritten) — claude2mqtt: der Nachrichten-Bus

Ein Claude-Code-**Channel-Plugin**, das eine persistente Instanz an einen
**MQTT-Broker** hängt. Damit können Instanzen asynchron miteinander reden
(Claude↔Claude), externe Systeme können Claude anstupsen (z. B. Home Assistant →
Claude), und der **Heartbeat-Scheduler** (siehe `heartbeat.md`) kann Instanzen zu
definierten Zeiten wecken. **claude2mqtt ist die Basis-Dependency für Heartbeat.**

> Das ist die Stufe „von einer Instanz zur kleinen Flotte". Brauchst du nur *eine*
> Instanz und keine zeitgesteuerten Reminder? Dann ist das hier optional.
> ⚠️ **LAN-only** — der Broker gehört nie ins offene Internet (siehe Sicherheit).

## Bestandteile
1. **Ein MQTT-Broker** (wir nutzen **Mosquitto**) — der zentrale Vermittler.
2. **Das Plugin** `claude2mqtt` — pro Claude-Instanz installiert, verbindet sie mit
   dem Broker und stellt MCP-Tools zum Senden/Empfangen bereit.
3. **Eine Config-Datei** pro Instanz (`mqtt-settings`) mit Broker-Adresse + Login.

> Der Plugin-Code ist Bennis eigenes Projekt (TypeScript/Bun, liegt in seinem
> lokalen Forgejo). Wenn du es aufsetzen willst: frag Benni nach dem Repo — er
> teilt es. Unten steht, wie Installation & Broker konzeptionell laufen.

## Broker aufsetzen (Mosquitto)
Am einfachsten ein eigener kleiner LXC (Proxmox-Helper-Script für Mosquitto).
Dann pro Instanz einen User + ACL:

```bash
# User + Passwort
mosquitto_passwd -b /etc/mosquitto/passwd <INSTANCE> <PASS>
# ⚠️ Die passwd-Datei bleibt mosquitto:mosquitto — NIE zu root chownen (killt den Broker).

# ACL pro Instanz in /etc/mosquitto/aclfile:
user <INSTANCE>
topic readwrite claude/<INSTANCE>/#
topic write     claude/+/inbox/#
topic write     claude/+/rpc/#
topic read      claude/+/event/#
topic read      claude/+/status
topic read      claude/+/meta

systemctl reload mosquitto
```

## Instanz-Config (`mqtt-settings`, chmod 600)
```bash
CLAUDE2MQTT_INSTANCE=<INSTANCE>     # wie sich die Instanz am Bus nennt (lowercase!)
CLAUDE2MQTT_BROKER=<BROKER_LAN_IP>  # z.B. 192.168.x.x — LAN, nie öffentlich
CLAUDE2MQTT_PORT=1883
CLAUDE2MQTT_USER=<INSTANCE>
CLAUDE2MQTT_PASS=<PASS>
CLAUDE2MQTT_TLS=false               # LAN-only
```
Weitere Instanzen unter *einem* Linux-User: je eigene `mqtt-settings-<inst>` +
`CLAUDE2MQTT_ENV_FILE` darauf zeigen lassen (INLINE im tmux-Befehl, siehe
remote-control.md — gleiche Env-Falle).

## Plugin installieren
```bash
git clone <FORGEJO>/claude2mqtt.git ~/claude2mqtt
CLAUDE_CONFIG_DIR=~/.claude claude marketplace add ~/claude2mqtt
CLAUDE_CONFIG_DIR=~/.claude claude plugin install claude2mqtt@claude2mqtt
```
> ⚠️ `claude plugin install` ist **Pflicht** — settings.json *deklariert* das Plugin
> nur; ohne Install kommt „plugin not installed".
> ⚠️ Braucht **bun** als echtes systemweites Binary (`/usr/local/bin/bun`), nicht als
> User-Symlink mit zu engen Rechten — sonst lädt das Plugin nicht.

Dann im Launch-Wrapper (`claude-instance.sh`) die Flags ergänzen:
```bash
FLAGS="$RC --permission-mode bypassPermissions --channels plugin:claude2mqtt@claude2mqtt"
```

## Topic-Schema (so redet der Bus)
| Topic | Richtung | Bedeutung |
|---|---|---|
| `claude/<inst>/inbox/<mode>/<kind>` | IN | Nachrichten an die Instanz; mode = `silent`/`notify`/`wake` |
| `claude/<inst>/status` | OUT (retained) | `alive` / `offline` |
| `claude/<inst>/meta` | OUT (retained) | Version/Protokoll |
| `claude/<inst>/event/<kind>` | OUT (broadcast) | Events, die alle lesen dürfen |
| `claude/<inst>/rpc/<corr>` | BI | RPC-Antwort-Topic (Request/Reply) |

**Modi:** `silent` = nur Kontext, keine Antwort nötig · `notify` = bei Relevanz
reagieren · `wake` = jetzt reagieren (zeitkritisch).

## MCP-Tools, die das Plugin gibt
- **`mqtt_publish(topic, payload)`** — an ein Topic senden (Peer-Inbox, eigenen
  Status, Broadcast).
- **`mqtt_request(peer, payload)`** — **synchrones RPC**: an einen Peer fragen und
  blockieren, bis die Antwort kommt (~30 s Timeout). Für „frag Instanz X und nutz
  die Antwort".
- **`mqtt_query(topic)`** — eine *retained* Message lesen (Zustands-Topics).

## Kommunikations-Regeln (bewährt, LLM-zu-LLM)
- **Stabile Instanz-IDs** (lowercase!), nie selbst-vergebene Alias-Namen, in Topics
  und Signaturen. MQTT ist case-sensitive → mixed-case kostet Auffindbarkeit.
- **Knapp, sachlich, faktenbasiert** — keine Prosa, keine Höflichkeitsfloskeln.
- **Discovery per Wildcard** (`claude/+/status`) statt Namen raten.
- Bei `reply_to` in einer Nachricht (RPC) → Antwort ans exakte `reply_to`-Topic.

## ⚠️ Sicherheit
- **Broker nie ins Internet exposen.** Kein Port-Forward auf 1883. Nur LAN; Remote
  nur über VPN.
- TLS aus ist nur ok, weil's im vertrauten LAN bleibt. Sobald der Broker über
  unsichere Netze erreichbar wäre: TLS + starke Passwörter Pflicht.
