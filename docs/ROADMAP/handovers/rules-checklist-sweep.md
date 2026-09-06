# Handover — RULES.md Checklist-Familien-Sweep

Fortlaufende Arbeit an
[`docs/ROADMAP/personal/All/FINISH/RULES.md`](../personal/All/FINISH/RULES.md):
die 9 Regel-Familien aus `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/`
(`PRINCIPLES.md`, `LUA_NVIM.md`, `PERFORMANCE.md`) werden Familie für Familie
gegen alle 32 Personal-Plugin-Repos geprüft. `RULES.md` selbst ist die
laufende Quelle der Wahrheit für den Stand — diese Datei ist nur der
Einstiegspunkt für eine neue Session.

## Stand bei Übergabe (2026-09-06, dritte Aktualisierung)

| Familie | Status |
|---|---|
| `LLS-*` (34) | ✅ fertig |
| `SEC-*` (23) | ✅ fertig |
| `DEP-*` (7) | ✅ fertig |
| `TS-*` (5) | ✅ fertig — 0 Befunde, komplett N/A (kein Repo hat eigene Query-Dateien) |
| `ERR-*` (34) | 🔶 **in Arbeit** — 11/32 Repos gelesen, 3 echte Bugs gefixt+gepusht, 2 fleet-weite Mechanik-Checks über alle 32 Repos gelaufen |
| `PRIN-*` (37) | ⬜ offen |
| `UI-*` (34) | ⬜ offen |
| `LUA-*` (45) | ⬜ offen |
| `PERF-*` (57) | ⬜ offen |

Gelesene 11: buffer-ctx.nvim (Bug), cascade.nvim (sauber), casedesk.nvim
(Bug), cmdlog.nvim (sauber), color_my_ascii.nvim (sauber), dap.nvim (sauber),
debugging.nvim (sauber), diff.nvim (sauber), emojis.nvim (sauber),
fileops.nvim (Bug, 2 Stellen), filetree.nvim (sauber, 124 Dateien —
Checklist + Stichproben statt Volllesung, siehe RULES.md).

## Nächster Schritt

`ERR-*` weiterführen mit **github_stats.nvim** (nächstes in der
32-Repo-Liste, alphabetisch nach `filetree.nvim`; `documentation.nvim` steht
zwar davor, ist aber mit ~60 Dateien der größte Brocken der Familie — bei
Bedarf zurückstellen und zuerst die kleineren abarbeiten). Volle Liste der
noch ungelesenen 21 Repos steht in `RULES.md` §"ERR-* — in Arbeit" →
"Noch offen". `lib.nvim` verdient dabei besondere Aufmerksamkeit für ERR-34
(Symlink-Zyklus-Schutz in `fs.collect_recursive`) — mehrere Konsumenten
delegieren dorthin, ein Fund dort wirkt fleet-weit. Checkliste pro Repo, die
sich bewährt hat (siehe RULES.md für Details):

- `table.sort`-Comparatoren lesen (die `cond and A>B or C<D`-Falle ist
  fleet-weit bereits per Grep ausgeschlossen, **inklusive
  Methodenaufruf-Varianten wie `a:lower()<b:lower()`** — **nicht erneut
  grep'en**, s. RULES.md; die erste, engere Regex-Fassung hatte genau diese
  Variante beim ersten Durchgang übersehen, siehe „Lehre" in RULES.md).
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
- Bei einem gefixten Bug: Regressionstest so wählen, dass er den Bug auch
  wirklich fängt — ein Test kann trotz korrekt nachgestelltem Bug grün
  bleiben, wenn die Assertion die falsche Reihenfolge nicht von der
  richtigen unterscheidet (siehe fileops.nvim-Fix: der erste Testentwurf mit
  nur 2 Dateien/1 Hop bestand versehentlich auch gegen den kaputten Code;
  Windows/NTFS liefert Verzeichnislistungen zudem oft schon alphabetisch
  vorsortiert, was den Bug beim lokalen Testen zusätzlich verdeckt haben
  kann — mit dem Bug tatsächlich reproduzieren/verifizieren, nicht nur
  gegen den Fix grün laufen lassen).
- Bei einem sehr großen Repo (filetree.nvim: 124 Dateien) ist ein
  file-für-file-Read nicht verhältnismäßig — Checkliste (Grep für
  `table.sort`-Comparatoren, `defer_fn`/`schedule`, `O_CREAT`/`EEXIST`,
  Config-Merge) plus gezielte Stichproben in den offensichtlichen
  Risikobereichen (Batch-Operationen, Datei-Schreibpfade, rekursive Walks)
  reicht, sofern die Stichproben nichts Auffälliges zeigen. Das ist eine
  bewusste Abwägung, kein übersprungener Schritt — in RULES.md so vermerkt.

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
