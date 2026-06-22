# Optional — Inventar: erzähl Claude, was du hast

Claude hilft dir umso besser, je mehr es über dein Setup weiß: welche Hosts/LXCs es
gibt, was darauf läuft, welche IPs/Ports/Zugänge, welche Dienste. Lege dafür ein
**Inventar** an, das Claude als Kontext lesen kann — und entscheide bewusst, **wie
viel Zugriff** du Claude gibst.

## Schritt 1 — erfassen, was wo ist
Eine simple Markdown-Datei (z. B. `inventory.md` im Arbeitsordner) reicht für den
Anfang. Pro Host/Dienst eine Zeile:

```markdown
# Inventar

## Hosts / LXCs
| Name        | IP            | Rolle                  | Zugang            |
|-------------|---------------|------------------------|-------------------|
| proxmox     | 192.168.1.2   | Virtualisierung        | SSH root (Key)    |
| claude-lxc  | 192.168.1.10  | Claude-Instanz         | SSH cadmin (Key)  |
| ha          | 192.168.1.20  | Home Assistant         | Web + Token       |
| nas         | 192.168.1.30  | Storage / Backup       | SSH + SMB         |

## Dienste
- Reverse-Proxy: Caddy auf claude-lxc:443
- Git: Forgejo auf git-lxc:3000 (nur LAN)
- ...
```

Tipp: Claude kann dir das **selbst zusammentragen** — sag ihm „geh meine Hosts durch
(ich gebe dir die Liste / die SSH-Zugänge) und bau mir daraus ein inventory.md". Dann
lebt es als Datei und wird bei jeder Session mitgelesen (am besten aus der `CLAUDE.md`
darauf verweisen).

## Schritt 2 — Zugriff bewusst wählen (wichtig)
Du musst Claude **nicht** sofort vollen Zugriff auf alles geben. Staffelung:

1. **Nur Wissen, kein Zugriff:** das Inventar als reine Doku — Claude *weiß* Bescheid,
   kann aber nichts anfassen. Guter, vorsichtiger Start.
2. **Read-only-Zugänge:** SSH-User mit eingeschränkten Rechten, API-Token nur lesend.
   Claude kann Zustände prüfen/diagnostizieren, aber nichts ändern.
3. **Voller Admin** (so wie im „großen" Homelab): passwordless-sudo-User überall
   (siehe `scripts/provision-lxc-user.sh`). Maximaler Komfort, maximales Vertrauen
   nötig — schrittweise hineinwachsen, nicht am ersten Tag.

> Es ist völlig legitim, **vorsichtig** anzufangen (Variante 1/2) und Claude erst mehr
> Zugriff zu geben, wenn du ein Gefühl dafür hast. Die `CLAUDE.md`-Regeln (löschen nur
> nach Rückfrage, nichts Destruktives ohne Bestätigung) sind die Leitplanke — aber
> Vertrauen wächst, es muss nicht vorausgesetzt werden.

## Schritt 3 — aktuell halten
Wenn sich was ändert (neuer Host, Dienst umgezogen), sag es Claude → es pflegt das
Inventar nach. Mit mem0 (optional) merkt sich Claude die wichtigsten Anker zusätzlich
über Sessions hinweg.
