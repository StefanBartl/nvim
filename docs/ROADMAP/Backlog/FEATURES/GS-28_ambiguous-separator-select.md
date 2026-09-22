# GS-28 — Mehrdeutigen Konflikt per Trennerwahl auflösen

**Repos:** gitsuite.nvim · **Nutzen** 2 · **Aufwand** 0,25 · **Risiko**
niedrig · **Welle** 5 · Abhängigkeit `GS-07` (bereits vorher erledigt) ·
erledigt 2026-09-22.

## Ausgangslage

Eine ambiguë Konfliktregion (z. B. eine Markdown-Setext-Überschrift, die
selbst wie `=======` aussieht) ließ `choose()` bisher nur mit einer
Fehlermeldung refusen — auch wenn es mehrere klare Kandidaten für den
echten Trenner gibt, entscheidet nie der Nutzer, nur der Parser (der zu
Recht nie rät).

## Umsetzung

- **gitsuite.nvim** (`ca228ac`): `parser.lua`s ambiguë `Region` trägt jetzt
  zusätzlich `base_first` (nur gesetzt, wenn der Base-Marker selbst
  eindeutig ist — separate Ambiguität von der Trenner-Ambiguität).
  `conflict/init.lua`s `M.choose(keep)`: bei einer ambiguën Region mit
  **mehr als einem** Trenner-Kandidaten fragt `vim.ui.select` (Zeile-davor/
  Zeile-danach-Vorschau je Kandidat), welcher `=======` real ist;
  `reconstruct_from_separator()` baut daraus eine konkrete Region, die
  dann durch dieselbe `resolve_concrete()`-Pipeline läuft wie jede normale
  Auflösung (inkl. TOCTOU-Recheck). Bei **genau einem** Kandidaten (die
  Ambiguität liegt dann am Base-Marker, nicht am Trenner — eine
  Trennerwahl könnte daran nichts ändern) bleibt das alte Verweigern-Verhalten
  unverändert.

## Nachtrag: CI-Hang durch einen pre-existing Test (`b8cdd0e`)

Ein bereits vorhandener Real-Git-Integrationstest (`conflict_git_spec.lua`,
"merge: a conflict that CONTAINS the underline is reported as ambiguous")
rief `choose()` gegen eine echte, mehrdeutige (3 Kandidaten) Region auf,
ohne `vim.ui.select` zu stubben — vor `GS-28` harmlos (sofortiges Verweigern),
nach `GS-28` ein echter, blockierender `vim.ui.select`-Prompt ohne
Headless-Auto-Dismiss. Alle drei CI-Betriebssysteme hingen bis zum
SIGTERM-Timeout. Gefunden über die fehlgeschlagene CI, nicht vorab —
behoben durch Stubben von `vim.ui.select` (Cancel, Buffer bleibt
unangetastet) im selben Muster wie jeder andere ambiguë-Region-Test.
**Lehre für künftige Karten:** ein Verhaltenswechsel an `choose()`
verlangt eine vollständige Suche nach *jedem* unstubbed Aufrufer im ganzen
Testbaum, nicht nur in der offensichtlichsten Testdatei.

## Tests

`TESTS/gitsuite/conflict_spec.lua`: die bisherige "choose() refuses"-Test
komplett umgeschrieben in vier neue Fälle (Auswahl bietet beide Kandidaten
an und löst entsprechend auf; eine andere Wahl löst anders auf; ein
abgebrochener Prompt lässt den Puffer unangetastet; der reine
Base-Ambiguität-Fall — ein Kandidat — verweigert weiterhin ohne Prompt).
`TESTS/gitsuite/conflict_parser_spec.lua`: `base_first` auf der ambiguën
Region jetzt explizit geprüft (diff3-Fall: gesetzt; merge-Fall: `nil`).
`TESTS/gitsuite/conflict_git_spec.lua`: siehe Nachtrag oben. `stylua`/
`luacheck` grün, volle gitsuite-Suite grün (inkl. der 27 Real-Git-Fälle in
`conflict_git_spec.lua`, mit Timeout lokal verifiziert, kein Hängen mehr).

## Ergebnis

Erster Push (`ca228ac`) CI-rot auf allen drei Systemen (siehe Nachtrag oben).
Fix-Push (`b8cdd0e`) CI grün auf allen drei Systemen (`gh run view
35762556320` bestätigt `completed success`).

## Dokumentation mitgezogen

`doc/gitsuite.txt`s `*gitsuite-conflict*`-Abschnitt (beschreibt jetzt die
Trennerwahl statt nur "refuse with a message").
