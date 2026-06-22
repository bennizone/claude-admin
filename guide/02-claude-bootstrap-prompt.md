# Teil B — Selbst-Bootstrap (Schritt 4+)

Ab hier richtet **Claude sich selbst** ein. Du gibst der frisch eingeloggten
Session (Ende von Teil A) den Prompt unten. Voraussetzung: dieses Kit liegt auf
dem LXC (per `git clone` deines GitHub-Repos oder kopiert).

```bash
# falls noch nicht da — als der neue User:
git clone <DEIN-GITHUB-REPO> ~/starter-kit-src
# der Kit-Pfad ist dann z.B. ~/starter-kit-src/.../starter-kit
```

---

## Der Bootstrap-Prompt (copy-paste an die Session)

> Kopiere alles im Block an Claude. Ersetze den Kit-Pfad, falls nötig.

```text
Du sollst dich selbst als persistente Instanz einrichten. Das Starter-Kit liegt
unter: ~/starter-kit-src   (passe den Pfad an, falls anders).

Frag mich zuerst kurz nach diesen 4 Dingen (mit sinnvollen Defaults):
  1. INSTANZ-NAME (kurz, lowercase, z.B. "denker") — wird tmux-Session + Service-Name.
  2. MODELL ("sonnet" / "opus" / Default leer = Account-Default).
  3. ARBEITSORDNER (WORKDIR, Default: dieses Home-Verzeichnis).
  4. STEUERUNG: "ssh" (nur SSH+tmux) oder "remote" (claude.ai-Fernsteuerung).
     Bei Unsicherheit -> "ssh".

Dann richte ALLES Folgende ein. Arbeite sorgfältig, zeig mir vor `systemctl enable`
kurz, was du tust:

A) ~/bin anlegen, in PATH sicherstellen. Kopiere aus dem Kit nach ~/bin und mach
   sie ausführbar:
     - scripts/selfclear      -> ~/bin/selfclear
     - scripts/selfcompact    -> ~/bin/selfcompact
     - scripts/handoff-reset  -> ~/bin/handoff-reset
   Diese Skripte leiten ihre tmux-Session aus $CLAUDE_CONFIG_DIR ab. WICHTIG:
   dieses Setup nutzt EINE Instanz mit DEFAULT-Config-Dir (~/.claude), d.h. die
   Ableitung "basename CLAUDE_CONFIG_DIR" greift nicht. Passe die drei Skripte so
   an, dass sie die Session aus einer Env-Var SESSION_NAME (oder hartkodiert auf
   den INSTANZ-NAMEN) nehmen. (Siehe Kommentar in den Skripten.)

B) Launch-Wrapper aus scripts/claude-instance.sh.template erzeugen als
   ~/bin/claude-<INSTANZ>.sh — ersetze die Platzhalter (SESSION, WORKDIR, MODELL,
   STEUERUNG). Bei STEUERUNG=ssh die --remote-control-Zeile auskommentiert lassen,
   bei "remote" einkommentieren (inkl. --remote-control-session-name-prefix).

C) systemd --user Unit aus scripts/claude-instance.service.template erzeugen als
   ~/.config/systemd/user/claude-<INSTANZ>.service. ExecStart zeigt auf den Wrapper.

D) CLAUDE.md: kopiere ../CLAUDE.md.template nach <WORKDIR>/CLAUDE.md (die
   Arbeitsregeln). Falls dort schon eine CLAUDE.md ist, NICHT überschreiben —
   zeig mir den Diff und frag.

E) Aktivieren:
     systemctl --user daemon-reload
     systemctl --user enable --now claude-<INSTANZ>
   Dann verifizieren: `tmux has-session -t <INSTANZ>` und
   `systemctl --user status claude-<INSTANZ>` (sollte active/running sein).

F) WICHTIG zum Schluss: dieser Service startet eine ZWEITE Claude-Session in tmux.
   Du (die aktuelle interaktive Session) bist davon getrennt. Erklär mir, wie ich
   die persistente Session erreiche: `tmux attach -t <INSTANZ>` (detach mit Ctrl-b d).
   Sag mir, dass ich DICH (diese Session) jetzt schließen kann — ab dann ist die
   tmux/systemd-Session die persistente.

Nach jedem Schritt kurz bestätigen, was passiert ist. Bei irreversiblem (Dateien
überschreiben) vorher fragen.
```

---

## Was dieser Prompt bewirkt (Kurz-Erklärung)

- **`~/bin/selfclear` / `selfcompact`** — schicken `/clear` bzw. `/compact` an die
  eigene tmux-Session. Nützlich, um den Kontext frisch zu machen, ohne SSH→tmux→tippen.
- **`~/bin/handoff-reset`** — der Kern des **Handoff-Protokolls**: die Instanz
  schreibt vor dem Reset einen Handoff auf Platte, ein *detachter* Helfer überlebt
  das `/clear` und sagt der frischen Session „lies den Handoff und mach weiter".
  → Kontext-Reset **ohne** den Arbeitsfaden zu verlieren. (Siehe
  [`../optional/handoff.md`](../optional/handoff.md) für das volle Protokoll.)
- **Launch-Wrapper + systemd** — Persistenz: `--continue` setzt die letzte Session
  fort, `Restart=always` + Linger überstehen Reboot.
- **`CLAUDE.md`** — die Arbeitsregeln, die Claude bei jeder Session als Kontext lädt.

## Verifikation (was „fertig" heißt)
```bash
systemctl --user status claude-<INSTANZ>    # active (running)
tmux ls                                      # zeigt die <INSTANZ>-Session
tmux attach -t <INSTANZ>                      # du landest in der persistenten Claude-Session
# Ctrl-b d zum Lösen. Reboot-Test: `sudo reboot`, danach kommt sie von allein hoch.
```
