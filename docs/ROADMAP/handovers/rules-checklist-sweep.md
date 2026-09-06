# Handover — RULES.md Checklist-Familien-Sweep

Fortlaufende Arbeit an
[`docs/ROADMAP/personal/All/FINISH/RULES.md`](../personal/All/FINISH/RULES.md):
die 9 Regel-Familien aus `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/`
(`PRINCIPLES.md`, `LUA_NVIM.md`, `PERFORMANCE.md`) werden Familie für Familie
gegen alle 32 Personal-Plugin-Repos geprüft. `RULES.md` selbst ist die
laufende Quelle der Wahrheit für den Stand — diese Datei ist nur der
Einstiegspunkt für eine neue Session.

## Stand bei Übergabe (2026-09-06, vierte Aktualisierung)

| Familie | Status |
|---|---|
| `LLS-*` (34) | ✅ fertig |
| `SEC-*` (23) | ✅ fertig |
| `DEP-*` (7) | ✅ fertig |
| `TS-*` (5) | ✅ fertig |
| `ERR-*` (34) | 🔶 **in Arbeit** — 23/32 Repos gelesen, 13 echte Bugs gefixt+gepusht |
| `PRIN-*` (37) | ⬜ offen |
| `UI-*` (34) | ⬜ offen |
| `LUA-*` (45) | ⬜ offen |
| `PERF-*` (57) | ⬜ offen |

Diese Session hat drei Agent-Ergebnisse aus einer vorherigen Sitzung
nachgetragen, die fertig waren, aber nie in `RULES.md` verbucht wurden:
**markdown.nvim** (`rg`-Scanfehler wurde als „keine Treffer" behandelt, Datei
konnte unter bestehenden Links weggelöscht werden), **mdview.nvim** (async
`resync()`-Callback griff auf ungültigen Buffer nach `:bwipeout` zu),
**open.nvim** (`and/or`-Falle im Keyword-Resolver: `nil`-Rückgabe der
Resolver-Funktion wurde zu einem stringifizierten Funktionswert als
Fantasie-Pfad). Alle drei bereits committed+gepusht auf ihren jeweiligen
`main`, jetzt auch in `RULES.md` §ERR-* dokumentiert.

## Nächster Schritt

`ERR-*` weiterführen mit den verbleibenden **9 Repos**: pdfport.nvim,
pickers.nvim, recommender.nvim, replacer.nvim, reposcope.nvim,
runtime-analysis.nvim, sandbox.nvim, sessions.nvim, spotlight.nvim
(alphabetisch, keine feste Reihenfolge nötig). Checkliste pro Repo, die sich
bewährt hat (Details in RULES.md §ERR-*):

- `table.sort`-Comparatoren: die `cond and A>B or C<D`-Falle ist **fleet-weit
  bereits per Grep ausgeschlossen** (inkl. Methodenaufruf-Varianten wie
  `a:lower()<b:lower()`) — **nicht erneut grep'en**.
- `X.read(...) or {...Stub...}` vor einem nachfolgenden `write()` — ebenfalls
  fleet-weit per Grep ausgeschlossen außer in casedesk.nvim (dort gefixt).
- Die häufigste reale Bugklasse in diesem Fleet ist **nicht** die
  and/or-Falle, sondern die **ERR-10/11/51/53-Familie**: geteilter Zustand
  (Config-Default, Cache, Sidecar-Datei) wird per Referenz statt Kopie
  geteilt, oder „fehlt"/„kaputt" wird nicht unterschieden und ein *späterer*
  Codepfad mutiert/überschreibt ihn — bei jedem Repo gezielt danach suchen.
- **ERR-52 (curated Listen indexweise gemergt) betrifft nur eigene,
  handgeschriebene Merge-Funktionen** — reiner `vim.tbl_deep_extend`-Gebrauch
  ersetzt nicht-leere Listen bereits vollständig, muss nicht mehr geprüft
  werden (verifiziert gegen echtes Neovim-0.12-Verhalten, siehe
  images.nvim-Durchgang in RULES.md).
- `vim.defer_fn`/`vim.schedule`-Callbacks: validieren sie Buffer-/Fenster-
  Handles beim Ausführen neu (ERR-32/33), nicht nur beim Erfassen? (Genau der
  Bugtyp, der gerade in mdview.nvim gefunden wurde.)
- Config-Merge (`tbl_deep_extend`/`deepcopy`) und Einzelwert-Validierung
  (ERR-22: degradiert ein ungültiger Wert auf Default statt ganz
  abzubrechen?).
- Nur **echte, demonstrierbare Bugs** fixen (falsches Ergebnis,
  Datenverlust, Absturz) — reine Layering-Abweichungen (z. B. `notify()` in
  einem „core"-Modul) notieren, nicht refaktorieren.
- Bei einem gefixten Bug: Regressionstest so wählen, dass er den Bug auch
  wirklich fängt (stash/reapply-Verifikation gegen den Pre-Fix-Code, wie in
  allen bisherigen Funden dieser Familie durchgezogen).

Danach laut `RULES.md` §"Vorschlag für die Reihenfolge": `UI-*` (34,
mittelgroß) → `PRIN-*` (37) → `LUA-*` (45) → `PERF-*` (57, größte). Keine
feste Vorgabe, nur eine Einschätzung nach Größe — bei Bedarf umsortieren.

**Methodik/Agenten-Limit für diese Session:** direkt in der Unterhaltung
lesen (Live-Fortschritt) ist der Normalfall. Falls doch ein Subagent
gebraucht wird: **maximal 1 Agent gleichzeitig, bei Bedarf mehrere Runden zu
je 1 Agent** — das ist die aktuelle, verschärfte Vorgabe für diese Session
(unabhängig davon, dass eine frühere Sitzung auf explizite Anweisung einmal
3 parallele Agenten für Repo 11–20 genutzt hat, siehe RULES.md §ERR-*).

## Standing Rules für diese Arbeit

- Antworten deutsch, Code/Kommentare englisch.
- Docs/README des jeweiligen Plugins mitpflegen, wenn ein echter Fund gefixt
  wird.
- Sofort auf `main` committen/pushen, sobald etwas in einem Repo gefixt
  wurde — nicht sammeln.
- Kein Claude-Co-Autor in Commit-Messages (weder in diesem Repo (nvim-config)
  noch in den einzelnen Plugin-Repos) — siehe Claudes Memory
  `no-coauthor-commits`.
- Diese Handover-Datei bei jedem weiteren Fortschritt aktualisieren, nicht
  nur einmalig anlegen.
