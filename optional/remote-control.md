# Optional — Web-Fernsteuerung (`--remote-control`)

Statt (oder zusätzlich zu) SSH+tmux kannst du eine Instanz über **claude.ai** im
Browser steuern. Ob dein Account-Tier das kann, hängt vom Abo ab — probier es aus.

## Aktivieren

Im Launch-Wrapper (`claude-instance.sh`) die RC-Zeile einkommentieren:

```bash
RC="--remote-control <INSTANZ> --remote-control-session-name-prefix <INSTANZ>"
```

`<INSTANZ>` ist der Name, unter dem die Session in der Web-Oberfläche auftaucht.

## ⚠️ Der Session-ID-Kollisions-Quirk (zwei Instanzen, ein User)

**Problem (real getroffen):** Die Remote-Control-Session-URL/-ID wird **pro Linux-
User** abgeleitet, nicht pro Config-Dir oder Host. Startest du **zwei** RC-Instanzen
unter **demselben Linux-User**, teilen sie sich dieselbe RC-Session — und **kicken
sich gegenseitig** (mal ist die eine erreichbar, mal die andere).

Verifiziert: zwei Instanzen unter *verschiedenen* Usern koexistieren problemlos;
zwei unter *demselben* User kollidieren.

**Zwei Lösungen:**

1. **Sauberste: je eigener Linux-User pro RC-Instanz.** Ein User = eine
   fernsteuerbare Instanz. (MQTT-/SSH-only-Worker ohne RC dürfen sich einen User teilen.)

2. **Wenn es unbedingt ein User sein muss:** gib jeder Instanz einen eigenen
   **`--remote-control-session-name-prefix`**. Das entkoppelt die RC-Session-IDs,
   sodass beide unter einem User koexistieren:
   ```bash
   # Instanz 1:
   RC="--remote-control inst1 --remote-control-session-name-prefix inst1"
   # Instanz 2 (gleicher User):
   RC="--remote-control inst2 --remote-control-session-name-prefix inst2"
   ```
   So laufen bei der Homelab-Flotte zwei Denker (`hadmin1`, `hadmin2`) unter *einem*
   User `hadmin`, ohne sich zu beißen.

   Bei getrennten Instanzen unter einem User zusätzlich je eigenes
   **`CLAUDE_CONFIG_DIR`** setzen (z. B. `~/.claude-inst1`, `~/.claude-inst2`) —
   sonst teilen sie Login/State. Die Env-Vars **INLINE** in den tmux-Befehl
   (`ENVV="...."`), NICHT vorher exportieren: ein laufender tmux-Server erbt die
   Env nicht von der Launcher-Shell.

## Weitere RC-Stolpersteine
- **Slash-Befehle (`/clear`, `/compact`) gehen über RC seit CC 2.1.160 nicht
  zuverlässig durch** → genau dafür gibt es `selfclear`/`selfcompact`/`handoff`
  (die feuern via `tmux send-keys` lokal, nicht über RC).
- **Kein `DISABLE_TELEMETRY`** setzen — das bricht RC.
- `--continue` **pinnt das Modell vom ersten Start**. Modellwechsel nur über einen
  frischen Start (alte `~/.claude*/projects` leeren).
