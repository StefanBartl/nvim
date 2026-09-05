# LAST_CDX_TASKS — Abschlussbericht (P7)

**Laufzeit:** 2026-09-03 bis 2026-09-05. **Umfang:** 32 Personal-Plugin-Repos
plus diese nvim-Config selbst.

| Datei | Rolle |
| --- | --- |
| [LAST_CDX_TASKS.md](LAST_CDX_TASKS.md) | Der Standard selbst: Bestandsaufnahme, Leitprinzipien, Doku-Checkliste, README-Konzept, BINDINGS-Sanierung, die fünf Wiederholungsläufe, Phasenplan |
| [HO_LAST_CDX_TASKS.md](HO_LAST_CDX_TASKS.md) | Das Arbeitsprotokoll — Repo-Ledger mit Commit-Hashes, 36 nummerierte „Überraschungen" (Ü1–Ü36), der komplette BND-04-Ledger |
| [P5_WIEDERHOLUNGSLAEUFE_2026-09-05.md](P5_WIEDERHOLUNGSLAEUFE_2026-09-05.md) | Die fünf Wiederholungsläufe im Detail, inkl. 8.2a |

Dieses Dokument ist der Einstieg — was am Ende dabei herauskam, nicht der
Weg dahin. Der Weg steht in den beiden anderen Dateien.

---

## Was das war

Ein Doku-Standard wurde entworfen (§3–§5 in `LAST_CDX_TASKS.md`) und dann
**vertikal, Repo für Repo**, über alle 32 Personal-Plugins gefahren: jedes
bekam einen vollständigen Durchgang gegen eine 30-Punkte-Checkliste
(`DOC-01`…`DOC-30`), sein README auf 100–250 Zeilen gebracht, deutsche
Dubletten entfernt, `FEATURES/`-Doppelungen aufgelöst, verwaiste Dokumente
verlinkt. Parallel dazu: die `PersonelPlugins/BINDINGS/`-Sammlung (107
Cheatsheet-Dateien, 12.566 Zeilen — eine zweite, driftende Fassung dessen,
was jedes Repo längst selbst dokumentiert) durch eine Live-Quelle ersetzt,
und fünf bereits einmal gelaufene Wiederholungsprüfungen (Duplikate,
Diagnostics, Magic Numbers, Keymap-Parität, Konfigurierbarkeit) erneut
gegen den seither entstandenen Code gehalten.

## Ergebnis nach Phase

| Phase | Ergebnis |
| --- | --- |
| **P0–P2** | Standard steht, sechs Entscheidungen (E1–E6) mit dem Autor geklärt, README-Konzept geschrieben |
| **P3** | `lib.nvim` als Referenz-Implementierung — fünf Doku-Ebenen statt der Standard-Struktur validiert (Bibliotheken brauchen mehr Ebenen als Feature-Plugins) |
| **P4** | **Alle 32 Repos, vollständiger Durchgang.** E1 (Alpha-Disclaimer) 32/32, `DOC-05` (Index-Vollständigkeit) 32/32, 0 tote Links, 0 tote Anker, 0 verwaiste `docs/`-Dateien, gemessen mit dem eigens dafür geschriebenen `scripts/docs_linkcheck.py` |
| **P5** | 8.1 (lib.nvim-Duplikate), 8.3 (Magic Numbers), 8.4 (Keymap-Parität), 8.5 (Konfigurierbarkeit) erneut gefahren; **8.2a** (12 Repos + `lsp.nvim` auf 0 LuaLS-Befunde) nachgezogen. **8.2b** (7 weitere Regel-Familien, ~250 Punkte, reine Handprüfung) bewusst offen — siehe unten |
| **P6** | BINDINGS-Sanierung (`BND-01`…`07`) vollständig. `PersonelPlugins/BINDINGS/` entfernt; `:Bindings` liest jetzt jedes Plugins eigene `docs/BINDINGS.md` direkt, inklusive dieser Config selbst |
| **P7** | Dieser Bericht |

## Die Zahlen, die zählen

- **32/32** Repos mit vollem Durchgang, **0** offene Doku-Findings danach.
- **31** Plugin-BINDINGS-Sheets gegen die jeweils aktuelle Repo-Doku
  gegengeprüft (`diff.nvim` hatte nie eines) — **6 echte Funde**, 25 bereits
  aktuell. Größter Einzelfund: `lsp.nvim`s eigene Autocmd-Doku behauptete
  „the complete inventory" zu sein, war es aber nicht — 33 Autocmds über 25
  Augroups fehlten komplett im Repo und stehen jetzt in dessen
  `docs/autocmds.md`.
- **107 Dateien, 12.566 Zeilen** Cheatsheet-Duplikat entfernt (`BND-04`/`05`).
- **13 Repos** (12 + `lsp.nvim`) auf 0 LuaLS-Befunde gebracht — 5 echte
  Ein-Zeiler-Funde, 7 bereits sauber, 1 (`markdown.nvim`) als
  Scan-Tool-Messartefakt verifiziert statt blind „behoben".

## Die Funde, die über den Standard hinausgehen

Die eigentliche Rechtfertigung für einen Durchgang wie diesen ist nie die
Doku-Kosmetik allein, sondern was er nebenbei findet. Auswahl, mit Beleg in
`HO_LAST_CDX_TASKS.md`:

- **Ein echter Live-Regressionsfund am eigenen Werkzeug:** `:Bindings
  search` hatte durch `BND-04`s eigenes Löschen der Plugin-Sheets bereits
  die Fähigkeit verloren, in irgendeinem der 31 Personal-Plugins etwas zu
  finden — der ungescopte Suchpfad las nur die zwei alten Baumwurzeln, nie
  die dritte Quelle. Gefunden beim Verifizieren von `BND-05`, nicht vorher
  bemerkt. Behoben, headless verifiziert.
- **`:Lsp` unterdrückt nvim-lspconfigs eigene Commands.** `lspconfig`s
  eigenes `plugin/lspconfig.lua` bricht ab, sobald `:lsp` (case-insensitiv)
  existiert — eine Kulanzprüfung, die niemand dokumentiert hatte, bis der
  Usercmd-Namensraum-Check sie fand. Steht jetzt in
  `docs/NOTES/CrossPlugin/Usercmds-Overview.md`.
- **Ein Nachlaufwerk aus der `hover.nvim`-Extraktion.** Drei Plugins
  (`documentation.nvim`, `insights.nvim`, `reposcope.nvim`) boten eine
  weiche `hover.nvim`-Integration an, deren Config-Feld nie deklariert war
  — LuaLS meldete es zurecht, drei Ein-Zeiler behoben es (P5 §8.2a).
- **Zwei echte Werkzeug-Bugs, gefunden beim Einsatz der eigenen Werkzeuge:**
  ein Windows-Crash in `docs_linkcheck.py` bei laufwerksübergreifenden
  Links, und zwei echte Markdown-Tabellenbrüche (einer in der eigenen
  Handover-Datei), gefunden vom brandneuen `docs_tablecheck.py` — das selbst
  erst in dieser Sitzung committet wurde, obwohl es schon fertig auf der
  Platte lag.
- **Ordnungsgemäß dokumentierte Nicht-Befunde** in P5: `:Bindings check`
  fand 0 Keymap↔Usercmd-Lücken über jetzt 30 Plugins (letzter Stand: 29),
  und `param-type-mismatch`s Messrauschen wurde als solches erkannt statt
  als Regression gemeldet.

## Was bewusst offen bleibt

**8.2b** — die sieben/acht Regel-Familien jenseits der 34 LuaLS-Regeln
(`PRIN-*`, `LUA-*`, `ERR-*`, `SEC-*`, `UI-*`, `TS-*`, `DEP-*`, `PERF-*`,
zusammen ~250 Einzelpunkte) sind reine Handprüfung gegen Quelltext. Ein
Pilot an `buffer-ctx.nvim` (siehe `P5_WIEDERHOLUNGSLAEUFE_2026-09-05.md`)
hat den Aufwand gemessen statt geschätzt: **eine vollständige Prüfung ist
gegen alle 32 Repos ein mehrtägiges bis mehrwöchiges Vorhaben**, deutlich
außerhalb eines einzelnen Wiederholungslauf-Termins. Empfehlung des Piloten:
wellenweise nach Regel-Familie (`SEC-*` zuerst), nicht repoweise.

**Zwischenstand 2026-09-05 (Abend):** die `SEC-*`-Welle (24 Regeln) ist auf
Autorenwunsch gestartet und läuft über **26 von 32 Repos** (alphabetisch;
Runden 1–7 zu 3 parallelen Agenten, danach ein Repo pro Durchgang). **17
Repos hatten mindestens einen echten Fund**, alle behoben, committet und auf
`main` gepusht — darunter zwei reale Schwachstellen statt Kosmetik: ein
GitHub-Token, das über einen Shell-String im Prozess-Argv sichtbar war
(`github_stats.nvim`), und eine echte Command-Injection über den
Clipboard-Zielpfad unter Linux (`images.nvim`). Details je Repo:
[P5_WIEDERHOLUNGSLAEUFE_2026-09-05.md §„8.2b — SEC-* Welle"](P5_WIEDERHOLUNGSLAEUFE_2026-09-05.md#82b--sec--welle-zwischenstand-2026-09-05-abend).
Runde 8 (`mdview`/`open`/`pdfport` parallel) riss am Sitzungslimit ab, bevor
etwas geschrieben wurde — kein Verlust, aber Anlass für die Umstellung auf
ein Repo pro Durchgang. Offen bleiben die restlichen 5 Repos für `SEC-*`
sowie die übrigen sieben Regel-Familien für alle 32. Laut Standard
**blockiert das nichts** — es ist der bewusst letzte Punkt der gesamten
Liste, keine vergessene Aufgabe.

**Die drei Autocmds-Beobachtungen** in
`docs/NOTES/CrossPlugin/Autocmds-Observations.md` sind ausdrücklich
**untriaged**: hand-gefundene Cross-Plugin-Timing-Einsichten (die
`BufWritePre`-Reihenfolge-Abhängigkeit über vier Plugins, markdown.nvims
Dreifach-Debounce, die Explorer-Singleton-Koordination), für die noch nicht
entschieden ist, ob sie in ein Plugin-Repo oder eine WKDBook-Notiz gehören.

## Was aus diesem Durchgang gelernt wurde

Vier Muster kamen wiederholt vor, oft genug, um es festzuhalten:

1. **Eine Bestandsaufnahme ist eine Messung mit Datum.** Zwischen ihr und der
   eigenen Welle liegt in einem aktiven Repo oft ein Tag Arbeit — `hover.nvim`
   war laut Standard das Ausreißer-Repo mit 1123 Zeilen README; gemessen am
   Tag der Welle waren es 191, weil ein eigenständiger Commit das schon
   erledigt hatte. Am Anfang der eigenen Welle neu messen, nicht die alte
   Zahl übernehmen.
2. **Ein Befundzähler, dem man nicht traut, kostet mehr als er spart.**
   Naive Link-Checks bestanden zu 80 % aus Rauschen (zitierte Beispiel-Links,
   gitignorierte Bäume); erst nach Filterung auf git-getrackte Dateien und
   Code-Block-Ausschluss wurde die Zahl belastbar.
3. **Sheets altern schneller als der Code, den sie beschreiben.** Jedes
   der sechs echten BND-04-Funde war ein Fall, in dem das Repo bereits
   weiter war als seine eigene Doku — nie umgekehrt.
4. **Ein Regressionstest für das eigene Werkzeug fehlt am ehesten dort, wo
   man ihn am wenigsten erwartet.** Der `:Bindings search`-Regressionsfund
   entstand durch die eigene vorangegangene Aufräumarbeit — Grund, nach jeder
   größeren Löschaktion die Werkzeuge zu verifizieren, die über den
   gelöschten Bestand liefen, nicht nur den Bestand selbst.

## Wo die Arbeit weiterlebt

- Jedes der 32 Repos trägt seine eigene `docs/BINDINGS.md` jetzt als
  alleinige Quelle — `git log --grep "fix(luals)"`/`docs(bindings)` in jedem
  Repo zeigt die Einzelcommits.
- Diese Config selbst hat eine neue [`docs/BINDINGS.md`](../../../../../../BINDINGS.md)
  im gleichen Format.
- `docs/NOTES/CrossPlugin/` ist die neue, dauerhafte Heimat für
  Cross-Plugin-Analysen, die kein einzelnes Repo für sich beanspruchen kann.
- `scripts/luals-scan/` und `scripts/docs_linkcheck.py`/`docs_tablecheck.py`
  sind wiederverwendbare Werkzeuge für den nächsten Durchgang dieser Art.
