# Handoff-Protokoll — Selbst-Reset mit Kontinuität

Zweck: eine persistente Instanz sauber frisch starten, **ohne den Arbeitsfaden zu
verlieren** — ersetzt das manuelle `SSH → tmux → /clear`. Funktioniert auch dort,
wo `/`-Slash-Befehle über die Fernsteuerung nicht durchgehen (Remote-Bug seit
CC 2.1.160).

## Mechanik

`/clear` resettet den Kontext *in-place* (gleicher Prozess, leerer Kopf; laufende
Hintergrund-Arbeit bleibt). Das Problem: sobald `/clear` feuert, ist der Kontext
weg — die Instanz kann den Handoff nicht mehr selbst „reinwerfen". Zwei Dinge
überleben das Clear und bilden die Brücke:

1. **Der Handoff als Datei auf Platte** (`~/.claude/handoffs/LATEST.md`).
2. **Ein detachter Helfer** (`~/bin/handoff-reset`, via `setsid`) — kein Kind der
   Session, überlebt also den Clear und treibt den Wiedereinstieg.

```
handoff (Wort)  → Instanz schreibt LATEST.md, zeigt Zusammenfassung, STOPP
go (Wort)       → Instanz startet Detach-Helfer, beendet Turn
                  Helfer: sleep → tmux send-keys "/clear" → sleep
                        → tmux send-keys "Lies …/LATEST.md und fahre dort fort."
frische Session → liest LATEST.md → macht weiter
```

Trigger sind **Klartext-Wörter** („handoff", „go"), NICHT `/slash`.

## go-Befehl

```bash
setsid ~/bin/handoff-reset "<INSTANZ>" "$HOME/.claude/handoffs/LATEST.md" \
  </dev/null >/dev/null 2>&1 &
```

`handoff-reset <tmux-session> <handoff-file> [pre=6] [post=6] [settle=2]` prüft
Existenz von Session und Datei, dann zweistufiges `send-keys` mit Pausen (die
Pausen verhindern, dass Claude Codes Paste-Erkennung das Enter schluckt).

## Pflicht-Inhalt eines Handoffs

- Aktueller Thread / Aufgabe, Live-Stand, getroffene Entscheidungen.
- Nächste Schritte, offene Entscheidungs-Gates, relevante Pfade/IDs.
- **Laufende Hintergrund-Tasks** (Bash `run_in_background`, Monitore, Poll-Loops):
  was sie tun + **EXAKTE Reaktivierungs-Befehle**. `/clear` killt session-gebundene
  Tasks; detachte Remote-Arbeit läuft weiter, aber der Watcher muss in der frischen
  Session neu armiert werden.

## Voraussetzungen
- Launch-Wrapper startet mit `--continue` (+ Fallback ohne) → übersteht Reboot.
- `~/bin/handoff-reset` ausführbar; `~/.claude/handoffs/` existiert (oder die
  Instanz legt es beim Schreiben an).
- Trigger-Anker in der `CLAUDE.md` (siehe CLAUDE.md.template), damit die Instanz
  weiß, was „handoff"/„go" bedeuten.
