# Optional (fortgeschritten) — Heartbeat: zeitgesteuertes Wecken

Ein **Cron-Ersatz mit Session-Persistenz**: ein kleiner Dienst, der im Minutentakt
prüft, ob „etwas fällig ist", und dann eine Claude-Instanz **über den Bus weckt**
(z. B. „erinnere Benni um 17:30 ans Auto", „check stündlich die Mails", oder als
Watchdog „warne, wenn die Platte zu 90 % voll ist").

> **Dependency:** Heartbeat schickt seine Trigger über MQTT → **erst
> [`claude2mqtt.md`](claude2mqtt.md) + Broker aufsetzen.**
>
> 💬 **Ehrlich:** Unser Heartbeat ist *historisch gewachsen* und mächtig
> (Multi-Tenant, Hub-Spoke über mehrere Hosts, LLM-bewertete Bedingungen). Das
> Folgende ist die **vereinfachte Einzel-Instanz-Variante** — der Kern, ohne den
> Flotten-Overbau. Willst du die Vollversion, frag Benni nach dem Design-Memo.

## Warum nicht einfach cron?
Normaler cron kann „führe Befehl X aus". Heartbeat kann „**wecke die laufende
Claude-Session** und gib ihr eine Aufgabe im Kontext" — die Session reagiert mit
ihrem vollen Wissen (Tools, mem0, CLAUDE.md), nicht als zustandsloses Skript.
Plus: Idempotenz (verpasste Trigger werden sauber nachgeholt, nicht doppelt) und
Zustands-Bedingungen.

## Architektur (vereinfacht)
```
systemd --user timer (jede Minute)
        │
        ▼
   run-tick  ──reads──>  tasks.db (SQLite: was ist fällig?)
        │
        ├─ fällig & reine Zeit?  ──> mosquitto_pub claude/<inst>/inbox/wake/<kind>
        │                              └─> die Claude-Instanz wacht auf & handelt
        └─ schon gefeuert?       ──> skip (Idempotenz via fires-Tabelle)
```

Bestandteile:
- **`tasks.db`** (SQLite) — die Aufgaben (id, schedule, mode, kind, payload, enabled).
- **`fires`-Tabelle** — was wann gefeuert hat (für Idempotenz + Audit).
- **`run-tick`** (Bash) — wird jede Minute vom systemd-Timer aufgerufen: fällige
  Tasks holen, über den Bus feuern, als gefeuert markieren.
- **systemd `--user` Timer** (`OnCalendar=*:*:00`) — der Minutentakt.

## Minimal-Setup (eine Instanz, eigener heartbeat-User)
```bash
# als root
useradd -r -m -d /srv/heartbeat -s /bin/bash heartbeat
loginctl enable-linger heartbeat
mkdir -p /srv/heartbeat/{bin,log}
chown -R heartbeat:heartbeat /srv/heartbeat

# MQTT-Creds für den heartbeat-User (eigener Broker-User + ACL-write auf inbox)
install -m600 /dev/stdin /etc/heartbeat/mqtt.env <<'EOF'
HEARTBEAT_MQTT_BROKER=<BROKER_LAN_IP>
HEARTBEAT_MQTT_PORT=1883
HEARTBEAT_MQTT_USER=heartbeat
HEARTBEAT_MQTT_PASS=<PASS>
EOF
```

**Timer + Service** (`~heartbeat/.config/systemd/user/`):
```ini
# heartbeat-tick.timer
[Timer]
OnCalendar=*:*:00
AccuracySec=1s
[Install]
WantedBy=timers.target
```
```ini
# heartbeat-tick.service
[Service]
Type=oneshot
EnvironmentFile=/etc/heartbeat/mqtt.env
ExecStart=/srv/heartbeat/bin/run-tick
[Install]
WantedBy=default.target
```
`systemctl --user enable --now heartbeat-tick.timer`

## Schedule-Formate (bewährt)
| Format | Bedeutung |
|---|---|
| `once:2026-05-08T17:30` | einmalig zur Minute (verpasst → genau 1× nachgeholt) |
| `every:1h` | jede volle Stunde |
| `every:5m@7:00-22:00` | alle 5 Min im Zeitfenster |
| `0 8 * * *` | klassischer Cron-Ausdruck |

## Eine Aufgabe anlegen
Ein kleiner `add-task`-Helper schreibt eine Zeile in `tasks.db`:
```bash
sudo -u heartbeat /srv/heartbeat/bin/add-task \
  --task-id auto-abholen-2026-05-08 \
  --schedule "once:2026-05-08T17:30" \
  --mode wake \
  --kind reminder \
  --payload "Auto abholen — sonst Blockiergebühr! Sag es mir."
```
Beim nächsten passenden Tick feuert Heartbeat
`claude/<inst>/inbox/wake/reminder` mit dem Payload → die laufende Claude-Session
wacht auf und handelt.

## Was die Vollversion zusätzlich kann (nur als Ausblick)
- **Mehrere Tenants/Empfänger** pro Aufgabe (ein Reminder an mehrere Instanzen).
- **Zustands-Bedingungen** (`state_condition: ha/zone/benni=home` → nur feuern,
  wenn jemand daheim ist).
- **LLM-bewertete Bedingungen** (Natürlichsprache: „feuere, wenn der Trainingslauf
  fertig oder abgestürzt ist") via günstigem Modell.
- **Watchdogs** (Platte/RAM/Dienste überwachen, eskalieren).
- **Hub-Spoke** (ein Heartbeat-Host triggert Aufgaben auf anderen Hosts via SSH).
- **Auto-disable** nach N Fehlern + Benachrichtigung.

Wenn dich das reizt: das ist genau das „historisch Gewachsene" — frag Benni/sonnet,
dann adaptieren wir die Vollversion auf dein Setup.

## 💡 Idee: Watchdogs (lohnt sich!)
Sobald Heartbeat (+ Bus) steht, sind **Watchdogs** der vielleicht nützlichste
Anwendungsfall: regelmäßige Selbst-Checks deiner Infrastruktur, die dich nur bei
Problemen wecken — z. B. „Platte ≥ 90 % voll", „Dienst X nicht erreichbar", „RAM/Swap
am Limit", „Backup heute Nacht nicht gelaufen". Statt eines stummen cron-Eintrags
weckt der Watchdog die **Claude-Session**, die das Problem dann gleich einordnen (und
oft beheben) kann.

> Ehrlicherweise ist das auch bei *uns* noch eine Baustelle mit Lücken — gutes
> gemeinsames nächstes Thema. Es hängt an Heartbeat → das hängt an claude2mqtt.
> Fang mit ein, zwei einfachen Checks an (Platte, ein kritischer Dienst) und bau aus.
