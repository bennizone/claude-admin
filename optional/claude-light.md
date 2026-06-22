# Optional — `claude-light`: die Claude-Code-CLI mit einem günstigen Modell

`claude-light` startet **dieselbe Claude-Code-CLI**, aber gegen den
**Anthropic-kompatiblen Endpoint von MiniMax** — du bekommst also die gewohnte
Oberfläche/Tools, nur läuft sie auf einem billigen Modell (MiniMax-M3). Ideal für
**Massen-/Billig-Tasks** (viele kleine Auswertungen, lange Reviews, Boilerplate),
ohne dein teures Claude-Kontingent zu verbrennen.

> **Voraussetzung: ein MiniMax-Plan** (API-Key). Ohne den ist das hier nicht nutzbar
> — dann diesen Baustein überspringen.

> 💡 Hintergrund: Wir haben mit verschiedenen „günstigen Wegen" experimentiert.
> **`claude -p`** (headless) und **ein winziges lokales Modell** sind bei uns wieder
> RAUS (`claude -p` wird künftig anders abgerechnet; das Mini-Modell brachte nicht den
> gewünschten Effekt). **`claude-light` (MiniMax) hat sich dagegen bewährt** — daher
> ist das hier die empfohlene „Sparvariante".

## Das Skript (`~/bin/claude-light`)
```bash
#!/bin/bash
# claude-light — Claude Code CLI gegen den MiniMax-Anthropic-Endpoint.
# Setzt MiniMax-Env nur für DIESEN Aufruf; deine normale settings.json bleibt unberührt.
#
# Usage:
#   claude-light -p "prompt"      # non-interactive (für Skripte/Delegation)
#   claude-light                  # interaktive TUI auf dem günstigen Modell
set -e

# API-Key aus einer Env-Datei lesen (chmod 600). Lege sie selbst an:
#   echo 'MINIMAX_API_KEY=dein-key' > ~/.config/minimax.env && chmod 600 ~/.config/minimax.env
ENV_FILE="$HOME/.config/minimax.env"
[ -f "$ENV_FILE" ] || { echo "ERROR: $ENV_FILE fehlt" >&2; exit 1; }
MINIMAX_KEY=$(grep '^MINIMAX_API_KEY=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '"'"'")
[ -n "$MINIMAX_KEY" ] || { echo "ERROR: MINIMAX_API_KEY leer" >&2; exit 1; }

MODEL="${CLAUDE_LIGHT_MODEL:-MiniMax-M3}"

exec env \
    ANTHROPIC_BASE_URL="https://api.minimax.io/anthropic" \
    ANTHROPIC_AUTH_TOKEN="$MINIMAX_KEY" \
    ANTHROPIC_MODEL="$MODEL" \
    ANTHROPIC_SMALL_FAST_MODEL="$MODEL" \
    ANTHROPIC_DEFAULT_SONNET_MODEL="$MODEL" \
    ANTHROPIC_DEFAULT_OPUS_MODEL="$MODEL" \
    ANTHROPIC_DEFAULT_HAIKU_MODEL="$MODEL" \
    MINIMAX_API_KEY="$MINIMAX_KEY" \
    API_TIMEOUT_MS="3000000" \
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1" \
    claude "$@"
```

## Anwendungsmuster
- **Delegation aus der Haupt-Session:** die teure Instanz lässt Billig-Arbeit von
  `claude-light -p "<auftrag>"` erledigen und bewertet nur das Ergebnis.
- **Heartbeat-Engine:** wenn du zeitgesteuerte Bedingungen in Natürlichsprache
  bewerten lässt (siehe `heartbeat.md`), ist `claude-light` die günstige Eval-Engine.
- **Optionale Web-Suche:** MiniMax bringt eigene MCP-Tools (z. B. `web_search`) mit;
  die kannst du per `--mcp-config` einbinden (siehe MiniMax-Doku).

## Hinweis
Das ist ein anderer Anbieter/Modell — Datenschutz & Qualität entsprechend einordnen.
Für sensible/wichtige Arbeit das echte Claude-Modell nehmen; `claude-light` für
Volumen und Wegwerf-Tasks.
