# Handover — RULES.md Checklist-Familien-Sweep

Fortlaufende Arbeit an
[`docs/ROADMAP/personal/All/FINISH/RULES.md`](../personal/All/FINISH/RULES.md):
die 9 Regel-Familien aus `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/`
(`PRINCIPLES.md`, `LUA_NVIM.md`, `PERFORMANCE.md`) werden Familie für Familie
gegen alle 32 Personal-Plugin-Repos geprüft. `RULES.md` selbst ist die
laufende Quelle der Wahrheit für den Stand — diese Datei ist nur der
Einstiegspunkt für eine neue Session.

## Stand bei Übergabe (2026-09-07, zehnte Aktualisierung — PRIN-* fertig)

| Familie | Status |
|---|---|
| `LLS-*` (34) | ✅ fertig |
| `SEC-*` (23) | ✅ fertig |
| `DEP-*` (7) | ✅ fertig |
| `TS-*` (5) | ✅ fertig |
| `ERR-*` (34) | ✅ fertig — 32/32 Repos, 17 echte Bugs gefixt |
| `UI-*` (34) | ✅ fertig — 32/32 Repos, 0 echte Bugs |
| `PRIN-*` (37) | ✅ **fertig** — 32/32 Repos, **1 Fund** (notiert, nicht gefixt) |
| `LUA-*` (45) | ⬜ offen |
| `PERF-*` (57) | ⬜ offen |

## PRIN-* — Abschlussnotiz

**Andere Methodik als `ERR-*`/`UI-*`, auf explizite Nutzeranfrage**: eine
volle Architektur-Review über alle 37 Regeln (SRP, reine Funktionen,
Naming, DI, Fehlerstruktur, Testbarkeit, Doku-Vertrag) statt eines reinen
Bug-Hunts — der Nutzer wollte das explizit so, nicht nur konkrete
Bug-Muster.

**Ergebnis: nur 1 Fund trotz voller Review.** `casedesk.nvim/lua/casedesk/ui.lua`
ist 3433 Zeilen lang und bündelt 50 `function M.*`-Handler für völlig
unabhängige Case-Management-Features (CRUD, OCR, Git-Sync, KI/AI-Abfrage,
Timeline, SLA-Tracking, Terminologie, Link-Check, Export …) —
`PRIN-01`/`02`-Kandidat. **Notiert, nicht refaktoriert**: eine Aufteilung
in Feature-Module wäre eine Architekturentscheidung mit echtem Risiko in
einem aktiv genutzten 45-Datei-Repo, kein Ein-Zeiler im Rahmen eines
Findings-Sweeps — falls das je angegangen wird, ist es eine eigene,
bewusste Aufgabe, keine Nebensache.

**Warum sonst nichts gefunden wurde** (wichtig für `LUA-*`/`PERF-*` als
Erwartungshaltung, nicht als Abkürzung):
1. Der Katalog selbst zitiert schon ~15 der 32 Repos als *positive*
   Beispiele (Erhebung 2026-08-08) — er wurde mindestens teilweise aus der
   Beobachtung dieses Fleets geschrieben.
2. Mehrere PRIN-Regeln (`PRIN-10` kein globaler Zustand, `PRIN-20`/`25`-`27`
   Fehlerbehandlung, `PRIN-40`-`43` Cache-Hygiene) beschreiben exakt die
   Bugklassen, die `ERR-*` gerade erst exhaustiv durchsucht und gefixt hat
   — hier gab es nichts Neues mehr zu finden.
3. Vier Regeln wurden **fleet-weit mechanisch** statt 32× einzeln geprüft:
   `PRIN-10` (Grep nach `_G.`/`_G[`, nur 3 begründete Ausnahmen), `PRIN-35`
   (Naming: 0 camelCase-Ausreißer in allen 32 Repos), `PRIN-50`
   (Datei-Header: kein Repo unter 95 % Abdeckung), `PRIN-51`/`52`
   (dokumentierter Vertrag: folgt automatisch aus der bereits
   abgeschlossenen `LLS-*`-Familie, 0 LuaLS-Diagnostics fleet-weit).
4. Eine **Größte-Datei-Stichprobe** (SRP-Proxy) fand mehrere auffällig
   große Dateien (documentation.nvim 10185 Zeilen, hover.nvim 1970,
   reposcope.nvim 1387, runtime-analysis.nvim 1616) — alle bei genauerem
   Hinsehen gerechtfertigt (eine kohärente Verantwortung trotz Größe, oder
   überwiegend eingebettete Template-Daten statt Logik). Nur casedesk.nvim
   war ein echter Fund.

Volle Details (Repo-für-Repo-Tabelle, alle Fleet-Checks) stehen in
`RULES.md` selbst unter „✅ PRIN-* (37 Regeln) — fertig".

## Nächster Schritt

Laut `RULES.md` §"Vorschlag für die Reihenfolge": **`LUA-*`** (45 Regeln,
allgemeine Lua/Neovim-Idiome jenseits von Deprecations) als Nächstes →
`PERF-*` (57, größte, da sie Verständnis von Aufrufhäufigkeit statt reinem
Pattern-Matching braucht). Keine feste Vorgabe, nur eine Einschätzung nach
Größe.

**Wichtig für den Sitzungsstart von `LUA-*`:** zuerst klären, ob dieselbe
Frage wie bei `PRIN-*` erneut gestellt werden muss (voller Architektur-/
Stil-Review vs. reiner Bug-Hunt) — `LUA_NVIM.md`s "allgemeine Idiome
jenseits von Deprecations" klingt nach einer ähnlichen Mischung aus
konkreten Mustern und Geschmacksfragen wie `PRIN-*`. Den Regelkatalog
zuerst vollständig lesen (inkl. „Belege"-Abschnitte auf Repo-Zitate
prüfen), bevor entschieden wird.

## Standing Rules für diese Arbeit

- Antworten deutsch, Code/Kommentare englisch.
- Docs/README des jeweiligen Plugins mitpflegen, wenn ein echter Fund
  gefixt wird.
- Sofort auf `main` committen/pushen, sobald etwas in einem Repo gefixt
  wurde — nicht sammeln.
- Kein Claude-Co-Autor in Commit-Messages (weder in diesem Repo (nvim-config)
  noch in den einzelnen Plugin-Repos) — siehe Claudes Memory
  `no-coauthor-commits`.
- Diese Handover-Datei bei jedem weiteren Fortschritt aktualisieren, nicht
  nur einmalig anlegen.
- **1 Agent gleichzeitig, mehrere Runden zu je 1**, falls ein Subagent
  gebraucht wird — direktes Lesen in der Unterhaltung ist der Normalfall.
- **Erst grep-/mechanik-basierte Vorprüfung über alle 32 Repos**, bevor ein
  Repo einzeln gelesen wird — hat sich bei `ERR-*`, `UI-*` und `PRIN-*`
  jedes Mal bewährt.
- **Bug vs. Feature-/Stil-Lücke unterscheiden**: nur echte, demonstrierbare
  Defekte fixen. Eine reine Architektur-/Stil-Beobachtung (wie
  casedesk.nvims `ui.lua`) wird dokumentiert, aber nicht automatisch
  refaktoriert — das wäre eine Design-Entscheidung mit Tragweite, die
  einzeln abgestimmt gehört.
- **Bei unklarer Regel-Natur nachfragen**: wenn eine Familie (wie `PRIN-*`)
  strukturell anders ist als die vorherigen (mehr Geschmacksfragen als
  Bugs), den Nutzer fragen, wie eng der Scope gefasst werden soll, statt
  eine Annahme zu treffen — hat sich bei `PRIN-*` bewährt.
