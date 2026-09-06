# Handover — RULES.md Checklist-Familien-Sweep

Fortlaufende Arbeit an
[`docs/ROADMAP/personal/All/FINISH/RULES.md`](../personal/All/FINISH/RULES.md):
die 9 Regel-Familien aus `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/`
(`PRINCIPLES.md`, `LUA_NVIM.md`, `PERFORMANCE.md`) werden Familie für Familie
gegen alle 32 Personal-Plugin-Repos geprüft. `RULES.md` selbst ist die
laufende Quelle der Wahrheit für den Stand — diese Datei ist nur der
Einstiegspunkt für eine neue Session.

## Stand bei Übergabe (2026-09-06, zweite Aktualisierung)

| Familie | Status |
|---|---|
| `LLS-*` (34) | ✅ fertig |
| `SEC-*` (23) | ✅ fertig |
| `DEP-*` (7) | ✅ fertig |
| `TS-*` (5) | ✅ fertig — 0 Befunde, komplett N/A (kein Repo hat eigene Query-Dateien) |
| `ERR-*` (34) | 🔶 **in Arbeit** — 4/32 Repos gelesen (buffer-ctx.nvim, cascade.nvim, casedesk.nvim, cmdlog.nvim), 2 echte Bugs gefixt+gepusht, 2 fleet-weite Mechanik-Checks über alle 32 Repos gelaufen |
| `PRIN-*` (37) | ⬜ offen |
| `UI-*` (34) | ⬜ offen |
| `LUA-*` (45) | ⬜ offen |
| `PERF-*` (57) | ⬜ offen |

## Nächster Schritt

`ERR-*` weiterführen mit **color_my_ascii.nvim** (nächstes in der
32-Repo-Liste, alphabetisch nach `cmdlog.nvim`) — volle Liste der noch
ungelesenen 28 Repos steht in `RULES.md` §"ERR-* — in Arbeit" →
"Noch offen". Checkliste pro Repo, die sich bewährt hat (siehe RULES.md für
Details):

- `table.sort`-Comparatoren lesen (die exakte `cond and A>B or C<D`-Falle ist
  fleet-weit bereits per Grep ausgeschlossen — **nicht erneut grep'en**,
  s. RULES.md).
- `X.read(...) or {...Stub...}` vor einem nachfolgenden `write()` — ebenfalls
  fleet-weit per Grep ausgeschlossen außer in casedesk.nvim (dort gefixt).
- `notify()`-Platzierung: nur als Beobachtung notieren (ERR-04), nicht als
  Fix erzwingen, sofern kein echtes Fehlverhalten daraus folgt.
- Config-Merge (`tbl_deep_extend`/`deepcopy`) und Einzelwert-Validierung
  (ERR-22: degradiert ein ungültiger Wert auf Default statt ganz
  abzubrechen?).
- `vim.defer_fn`/`vim.schedule`-Callbacks: validieren sie Buffer-/Fenster-
  Handles beim Ausführen neu (ERR-32/33), nicht nur beim Erfassen?
- Nur **echte, demonstrierbare Bugs** fixen (falsches Ergebnis,
  Datenverlust, Absturz) — reine Layering-Abweichungen notieren, nicht
  refaktorieren (das wäre ein Architektur-Umbau, kein Ein-Zeiler-Fix).

Danach laut `RULES.md` §"Vorschlag für die Reihenfolge": `UI-*` (34,
mittelgroß) → `PRIN-*` (37) → `LUA-*` (45) → `PERF-*` (57, größte). Keine
feste Vorgabe, nur eine Einschätzung nach Größe — bei Bedarf umsortieren.

Methodik: direkt in der Unterhaltung lesen statt Subagent (Live-Fortschritt),
**1 Agent/Repo pro Durchgang, falls doch ein Subagent nötig wird, nicht
mehrere parallel** (Session-Limit, siehe Claudes Memory
`feedback_agent_limits_and_language`).

## Standing Rules für diese Arbeit

- Antworten deutsch, Code/Kommentare englisch.
- Docs/README des jeweiligen Plugins mitpflegen, wenn ein echter Fund gefixt
  wird.
- Sofort auf `main` committen/pushen, sobald etwas in einem Repo gefixt
  wurde — nicht sammeln.
- Kein Claude-Co-Autor in Commit-Messages dieses Repos (nvim-config) — siehe
  Claudes Memory `no-coauthor-commits`.
- Diese Handover-Datei bei jedem weiteren Fortschritt aktualisieren, nicht
  nur einmalig anlegen.
