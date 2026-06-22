# Optional — Projekt-Template (`project.md` als lebendes Handbuch)

Sobald du mit Claude an mehreren Dingen arbeitest, lohnt pro Projekt eine
`project.md`: das **lebende Handbuch**, das Claude bei jeder Session liest und das
dauerhaftes Projekt-Wissen festhält (Scope, Zuständigkeit, Regeln, Abhängigkeiten,
Stand). Hält den Faden über Sessions hinweg — und verhindert, dass Claude ins
falsche Verzeichnis greift oder den Scope überschreitet.

> Nutzung: Kopiere die Vorlage unten nach `<projekt>/project.md`, fülle sie aus.
> Session-Chronik kommt separat in eine `SESSION-LOG.md`. Das hat sich in der
> Homelab-Flotte bewährt; hier credential-frei genericisiert.

---

## Vorlage (kopieren & ausfüllen)

```markdown
# {{PROJEKT_NAME}} — project.md

> Lebendes Handbuch dieses Projekts. Alles, was dauerhaft gilt, gehört hierher.
> Session-Chronik → SESSION-LOG.md.

## Header

| Feld | Wert |
|---|---|
| **Status** | planned / bootstrapping / running / paused / sunset |
| **Expected cwd** | /pfad/zum/projekt |
| **Host** | z.B. LXC <id> (<ip>) |
| **Typ** | Single-LXC / Multi-LXC / VM / Bare-Metal / VPS / Hosted |
| **Angelegt** | YYYY-MM-DD |
| **Letzte Aktualisierung** | YYYY-MM-DD |

## Session Schritt 0: cwd-Self-Check
**Bevor du irgendetwas tust:** `pwd` ausführen und mit `Expected cwd` vergleichen.
Weicht es ab → STOPP, melden, nicht weiterarbeiten. (Falsches cwd = relative Pfade
ins Leere, falsche Grep-Treffer, Commits im falschen Repo.)

## Scope
**Was ist das Projekt?** 1–3 Sätze, verständlich für jemanden, der das Setup nie
gesehen hat. Nur der Zweck, keine Historie.
**Welche Lücke schließt es?** Welche Alternative gab es, warum verworfen?

## Zuständigkeit
**Besitzt:**
- …
**Besitzt ausdrücklich NICHT:**
- …
(Die NICHT-Liste ist wichtiger — sie verhindert Übergriff auf andere Projekte.)

## Dos
- Regeln, die in diesem Projekt immer gelten (über die globale CLAUDE.md hinaus)
- Projekt-spezifische Sicherheits-/Betriebsvorschriften, Smoke-Check-Erwartungen

## Don'ts
- Was hier explizit tabu ist (z.B. "kein Docker", "nicht während Arbeitszeit neustarten")

## Dependencies
**Upstream (braucht das Projekt):** andere Komponenten, externe Services,
Credentials (nur VERWEISEN, nie Werte hier!), Netzwerk-Voraussetzungen.
**Downstream (konsumiert das Projekt):** wer nutzt es, was bricht bei Ausfall?

## Session-Grenzen und Eskalation
**Wann die Session stoppt und fragt:**
- Globale Regeln (Installationen, Neustarts, Löschungen, Config-/Firewall-/
  Credential-Änderungen)
- Projekt-spezifisch: …
**Schreibrechte:** Diese Session schreibt in den eigenen Projekt-Ordner. Alles
darüber hinaus nur als expliziter Akt mit Zustimmung pro Commit.

## Aktueller Stand
Was läuft, was noch nicht, wo im Lifecycle. Zielgröße 10–30 Zeilen — wird's länger,
in decisions/ oder playbooks/ auslagern.

## Offene Entscheidungen
- **Thema:** Frage
  - Option A — Pro/Contra
  - Option B — Pro/Contra
  - Bias: …

## Referenzen
- Upstream-Doku, related Issues, ähnliche Projekte, relevante Tutorials

**Template-Version:** 1.0
```

---

## Warum das hilft
- **cwd-Self-Check** — der billigste Bug-Schutz überhaupt; eine Zeile, schließt den
  „im-falschen-Verzeichnis"-Blind-Spot.
- **Zuständigkeit (besonders das NICHT)** — hält Claude im Scope, gerade wenn du
  mehrere Projekte/Hosts hast.
- **Eskalations-Grenzen** — kodifiziert, wann Claude stoppt und fragt (passt zu den
  Kern-Regeln aus der `CLAUDE.md`).
- **Lebendes Dokument** — bei Änderungen sagst du Claude „pflege project.md nach";
  so altert es nicht weg.
