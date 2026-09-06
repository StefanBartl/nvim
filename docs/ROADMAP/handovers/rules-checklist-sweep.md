# Handover — RULES.md Checklist-Familien-Sweep

Fortlaufende Arbeit an
[`docs/ROADMAP/personal/All/FINISH/RULES.md`](../personal/All/FINISH/RULES.md):
die 9 Regel-Familien aus `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/`
(`PRINCIPLES.md`, `LUA_NVIM.md`, `PERFORMANCE.md`) werden Familie für Familie
gegen alle 32 Personal-Plugin-Repos geprüft. `RULES.md` selbst ist die
laufende Quelle der Wahrheit für den Stand — diese Datei ist nur der
Einstiegspunkt für eine neue Session.

## Stand bei Übergabe (2026-09-07, siebte Aktualisierung — ERR-* fertig)

| Familie | Status |
|---|---|
| `LLS-*` (34) | ✅ fertig |
| `SEC-*` (23) | ✅ fertig |
| `DEP-*` (7) | ✅ fertig |
| `TS-*` (5) | ✅ fertig |
| `ERR-*` (34) | ✅ **fertig** — 32/32 Repos, 17 echte Bugs gefixt+gepusht |
| `PRIN-*` (37) | ⬜ offen |
| `UI-*` (34) | ⬜ offen |
| `LUA-*` (45) | ⬜ offen |
| `PERF-*` (57) | ⬜ offen |

`ERR-*` ist mit dieser Sitzung komplett durch. Seit der letzten Übergabe
gelesen: pdfport.nvim, pickers.nvim (70 Dateien), recommender.nvim (alle 0
Funde), replacer.nvim (`history.lua`-Fund), reposcope.nvim (**106
Dateien/12350 LOC**, `favorites_state.lua`-Fund), runtime-analysis.nvim (0
Funde, 46 Dateien), sandbox.nvim (**233 Dateien/11773 LOC**,
`follow_logs.lua`-Fund in allen 3 Container-Engines), sessions.nvim (0
Funde), spotlight.nvim (Fund an der Wurzel in `lib.nvim` gefixt).

**Wichtigster Einzelfund dieser Runde:** dieselbe Bugklasse — `M.load()`
kollabiert „Datei fehlt" und „Datei kaputt" auf denselben leeren
Rückgabewert, ein nachfolgendes `M.add()`/`M.toggle()`/`M.set_exception()`
schreibt danach die GANZE Datei neu — trat **vier Mal** auf
(documentation.nvim, replacer.nvim, reposcope.nvim, dann strukturell in
`lib.nvim.cache.disk`, das `lib.nvim.store.project` und darüber
spotlight.nvim trägt). Die vierte Instanz wurde **an der Wurzel in
`lib.nvim` gefixt** (Commit `10acff1`, Backup nach `.corrupt`) statt nur im
einzelnen Plugin — schützt damit jeden aktuellen und künftigen Konsumenten
von `lib.nvim.store.project` fleet-weit.

**Kalibrierung, wann diese Musterklasse einen Fix wert ist** (wichtig für
die restlichen Familien): kuratierte, nicht-regenerierbare Nutzerdaten
(Favoriten, Historie, Pins, Bookmarks) → fixen. Ein reines Cache-/
Frecency-/Häufigkeits-Signal, das sich durch weitere Nutzung von selbst neu
aufbaut → bewusst NICHT fixen (pdfport.nvim `util/cache.lua`, reposcope.nvim
`state/query_stats.lua`, runtime-analysis.nvim `telemetry/store.lua` +
`history.lua` — bei letzteren beiden sogar schon im Code selbst als
bewusst verlusttolerant dokumentiert).

## Nächster Schritt

`ERR-*` ist fertig. Laut `RULES.md` §"Vorschlag für die Reihenfolge" als
nächstes: **`UI-*`** (34 Regeln, UI-Konventionen: Float-Größen,
Highlight-Gruppen, Statuszeilen-Verhalten, Tastenkonflikte) → `PRIN-*` (37)
→ `LUA-*` (45) → `PERF-*` (57, größte, da sie am meisten Kontext pro Fund
braucht). Keine feste Vorgabe, nur eine Einschätzung nach Größe — bei
Bedarf umsortieren.

Für `UI-*` sind noch keine repo-spezifischen Vorarbeiten gemacht — bei
Sitzungsstart zuerst den Regelkatalog (`LUA_NVIM.md`, `UI-*`-Abschnitt)
lesen und dieselbe Methodik wie bei `ERR-*` anwenden:

- Direkt in der Unterhaltung lesen (Live-Fortschritt) ist der Normalfall.
  Bei Bedarf Subagent: **maximal 1 gleichzeitig, mehrere Runden zu je 1**
  (aktuelle Vorgabe dieser Session).
- **Mechanisch prüfbare Teilregeln zuerst per Grep über alle 32 Repos** auf
  einmal scannen (feste API-Namen, Pattern-Matches), bevor ein Repo einzeln
  angefasst wird.
- Bei großen Repos (pickers.nvim 70, reposcope.nvim 106, sandbox.nvim 233
  Dateien): Checkliste + gezielte Stichproben statt Volllesung — bei
  Repos mit mehreren strukturell identischen Adaptern (sandbox.nvim:
  docker/nerdctl/podman; reposcope.nvim: github/gitlab/codeberg) lohnt sich
  ein `diff` zwischen den Kopien, um Drift/vergessene Fixes zu finden (hat
  in dieser Runde nichts Neues ergeben, aber die Methode selbst hat sich
  bewährt — z. B. beim gezielten Ausschluss der `needs_api`-Abweichung in
  reposcope.nvim als bewusste, dokumentierte Entscheidung statt Bug).
- Nur **echte, demonstrierbare Bugs** fixen (falsches Ergebnis,
  Datenverlust, Absturz) — reine Layering-/Stilabweichungen notieren, nicht
  refaktorieren.
- Bei einem gefixten Bug: Regressionstest so wählen, dass er den Bug auch
  wirklich fängt, stash/reapply-Verifikation gegen den Pre-Fix-Code
  durchziehen (in jedem Fund dieser Sitzung so gemacht, inkl. dem
  lib.nvim-Fix).
- **Vor einem Fix in `lib.nvim` selbst** (shared dependency, siehe
  Claudes Memory `lib-nvim-dependency`): den vollen `lib.nvim`-Testlauf
  fahren (`nvim --headless -u NONE -c "set rtp+=." -l TESTS/run.lua`,
  Erfolg endet mit `LIB_TESTS_OK`), nicht nur den einen betroffenen Spec —
  ein Fix dort wirkt fleet-weit, ein Regressions-Risiko dort auch.

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
