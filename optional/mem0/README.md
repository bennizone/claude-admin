# Optional — Langzeitgedächtnis mit mem0

**Brauchst du das für den Einstieg? Nein.** `CLAUDE.md` + `handoff` tragen weit.
Nimm mem0 erst, wenn du willst, dass sich die Instanz über Sessions hinweg an
*Fakten* erinnert (Entscheidungen, Zugänge, Präferenzen, Projektstand) — auch nach
`/clear` und ohne dass du sie ihr erneut erzählst.

Dieses Dokument ist **kein** Copy-Paste-Installer, sondern die **Erfahrungs- und
Fehler-Sammlung** aus unserem produktiven mem0-Setup — die teuren Lehren, die du
sonst selbst durchleiden müsstest. Die Server-Installation (Self-hosted mem0 +
Vektor-DB + Embedder) folgt der offiziellen mem0-Doku; hier steht, was DARÜBER
HINAUS wichtig ist.

## Architektur, die sich bewährt hat
- **Ein Server, mehrere Clients.** Ein self-hosted mem0-Server (HTTP-API), pro
  Claude-Instanz ein „Client". Trennung der Gedächtnis-Pools über `user_id`
  (= „Pool"). API-Key je Client in `~/.mem0-key` (chmod 600).
- **LLM für Extraktion + Embedder getrennt wählbar.** Bei uns: ein günstiges,
  schnelles LLM für die Fakt-Extraktion + ein guter mehrsprachiger Embedder
  (bge-m3, 1024d, via Ollama) + pgvector als Vektor-DB. Wähle den Embedder nach
  deiner Sprache — bge-m3 ist gut für Deutsch.
- **EINE Hook-Logik, Config pro Client.** Die Hook-Skripte sind identisch über
  alle Clients; nur Pool/Speaker stehen im `env` der jeweiligen `settings.json`.
  → Hooks NIE pro Client editieren (das war unsere Drift-Ursache); eine kanonische
  Quelle, von dort ausrollen.

## Die zwei Hooks
- **`inject.sh`** (`UserPromptSubmit`): Recall aus mem0, injiziert einen
  `<memory>`-Block in den Prompt — mit **Datums-Prefix `[YYYY-MM-DD]`** je Fakt.
- **`extract.sh`** (`PreCompact` + `SessionEnd`): schreibt neue Transkript-Turns
  nach mem0 (idempotent per Offset, im Hintergrund).

## ⭐ Die teuer erkauften Lehren

### 1. Der Default-Extraktor ist für technische Arbeit ungeeignet
mem0s Default ist ein „Personal Information Organizer" — der wirft technische Fakten
weg und merkt sich Belangloses. **Lösung:** den Extraktions-Prompt ersetzen über den
Server-Key **`custom_instructions`** (NICHT `custom_fact_extraction_prompt` — der war
auf unserem Server wirkungslos). Inhalt: Zweck-Erklärung + **Relevanz-Selbstbefragung**
(„merkenswert? in 5 Tagen noch relevant? dauerhaft vs. flüchtig?") + Few-Shot-Beispiele
inkl. Negativbeispiel `{"facts":[]}`. Das war der **größte Hebel** gegen Rauschen.
(Beispiel-Prompt: siehe unsere `custom_instructions.txt` im Fleet-Repo.)

### 2. ⚠️ NIEMALS die volle Config zurück-POSTen (Daten-Verlust-Falle)
Beim Setzen der `custom_instructions`: **nur** `{"custom_instructions": "..."}` POSTen
(mem0 deep-merged). **Niemals** die volle Config von `GET /configure` zurück-POSTen —
die liefert Secrets als `"[redacted]"`, und das einzufrieren **zerschoss bei uns das
Postgres-Passwort des Vektor-Stores** → alle Memory-Ops brachen mit
`password authentication failed`. Ein Partial-POST nur des einen Keys ist sicher.

### 3. Recall ist relevanz-basiert, NICHT recency-basiert
mem0 liefert die *semantisch ähnlichsten* Memories — veraltete Fakten, die thematisch
passen, scoren hoch und bleiben „ewig oben". Gegenmittel:
- **Server-seitiger `threshold`** (Score-Cutoff) — aber kalibriere ihn an deinem
  Embedder/deiner Sprache. Bei bge-m3-Deutsch lag das Score-Band bei 0,30–0,62, also
  filterte 0,4 fast nichts; wir nahmen 0,45. Ein Client-seitiger Cutoff half nicht.
- **`top_k` runter** (wir: 10→6) gegen Rausch-Flut.
- **Datums-Prefix** im injizierten Block, damit der Assistent veraltete Anker selbst
  als alt erkennt.
- Der eigentliche Hebel bleibt aber der **Write-Filter (#1)** + gelegentliches
  **Ausmisten** alter Memories.

### 4. Auto-Extract verliert Tool-Outputs
Die automatische Extraktion sieht primär die Konversation, nicht deine Tool-Ergebnisse.
Eigene Findings landen nur im Gedächtnis, wenn sie **explizit** als Fakt formuliert
(oder via manuellem `add` geschrieben) werden. → wichtige Erkenntnisse aktiv festhalten.

### 5. Reconciliation gehört zum Handoff
Weil Recall relevanz- statt recency-basiert ist, veralten Fakten leise. Mach den
**Handoff zum Abgleich-Punkt**: stale Memories löschen (mit Backup), aktuellen Stand
als kurze Prosa neu schreiben. Ein kleines Helfer-Tool (`review <themen>` → Liste mit
IDs+Datum+Score → `del <id>` → `add "<stand>"`) nimmt dir die API-Mechanik ab; das
Urteil (stale/keep) triffst du. Achtung: das GET-Listing cappt oft ~20 Einträge —
den vollen Pool siehst du nur über Suche/Review.

## Referenz-Implementierung
Die kanonischen Skripte (inject/extract/transcript-Parser/MCP-Server/reconcile +
`custom_instructions.txt` + `deploy.sh` + `set_custom_instructions.sh`) liegen im
Homelab-Fleet-Repo unter `docs/claude-fleet/mem0/`. Frag Benni/sonnet danach, wenn
du es konkret aufsetzen willst — dann adaptieren wir sie auf deinen Server (deine
IP/Pool/Embedder) gemeinsam.
