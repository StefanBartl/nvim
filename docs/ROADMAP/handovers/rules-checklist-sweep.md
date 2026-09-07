# Handover — RULES.md Checklist-Familien-Sweep

Fortlaufende Arbeit an
[`docs/ROADMAP/personal/All/FINISH/RULES.md`](../personal/All/FINISH/RULES.md):
die 9 Regel-Familien aus `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/`
(`PRINCIPLES.md`, `LUA_NVIM.md`, `PERFORMANCE.md`) wurden Familie für
Familie gegen alle 32 Personal-Plugin-Repos geprüft. `RULES.md` selbst
bleibt die Quelle der Wahrheit; diese Datei ist der Einstiegspunkt für
eine neue Session.

## Stand: alle 9 Familien fertig (2026-09-07)

| Familie | Status |
|---|---|
| `LLS-*` (34) | ✅ fertig |
| `SEC-*` (23) | ✅ fertig |
| `DEP-*` (7) | ✅ fertig |
| `TS-*` (5) | ✅ fertig |
| `ERR-*` (34) | ✅ fertig — 32/32 Repos, 17 echte Bugs gefixt |
| `UI-*` (34) | ✅ fertig — 32/32 Repos, 0 echte Bugs |
| `PRIN-*` (37) | ✅ fertig — 32/32 Repos, 1 Fund (notiert, nicht gefixt) |
| `LUA-*` (45) | ✅ fertig — 4 Repos gefixt |
| `PERF-*` (62, korrigiert von 57) | ✅ **fertig** — 2 Repos gefixt, 2 Funde notiert |

**Der komplette Sweep (281 Einzelregeln, alle 32 Repos) ist damit
abgeschlossen.** Volles Fazit mit Bilanz über alle 9 Familien:
[`RULES.md` → „Fazit: alle 9 Regel-Familien durchlaufen"](../personal/All/FINISH/RULES.md#fazit-alle-9-regel-familien-durchlaufen).

## PERF-* — Abschlussnotiz (letzte Familie)

**Zwei echte Bugs gefixt:**
- `documentation.nvim/lua/documentation/editor/browse/trail.lua`
  (`PERF-47`): `M.clear`/`M.hydrate` rissen den eigenen „live reference"-
  Vertrag von `M.list()` (den `browse/init.lua` als `st.pins` hält) durch
  Neuzuweisung statt In-Place-Mutation. Commit `179f16d`, Regressionstest
  `TESTS/browse_trail_spec.lua` (stash/reapply-verifiziert).
- `gopath.nvim/lua/gopath/truncated/cache.lua` (`PERF-62`/`82`, dieselbe
  Regel zweimal im Katalog): `start_periodic_refresh()` hielt seinen
  `uv`-Timer nur als lokale Variable, ungeschützt gegen wiederholte
  `setup()`-Aufrufe — jeder Config-Reload ließ einen weiteren, nie
  stoppbaren Hintergrund-Timer laufen. Commit `2dfca71`, headless
  verifiziert (kein Testframework in diesem Repo: 4 `setup()`-Aufrufe
  hinterließen vorher 4 aktive Timer, nachher 1).

**Zwei Funde notiert, bewusst nicht gefixt (Architekturentscheidung):**
- `reposcope.nvim/lua/reposcope/cache/readme_cache.lua` (`PERF-46`):
  Cache-Key ignoriert den aktiven Provider (GitHub/GitLab/Codeberg) —
  Providerwechsel kann falschen README-Inhalt für denselben `owner/repo`-
  String liefern. ≥10 Call-Sites betroffen, Datenmodell (`Favorite`)
  trägt aktuell kein `provider`-Feld — kein Ein-Datei-Fix.
- Frecency-Logik doppelt implementiert (`pickers.nvim/smart/frecency.lua`,
  `emojis.nvim/overlay/frecency.lua`, `PERF-52`) statt zentral in
  `lib.nvim` — reale, aber nicht angegangene Extraktion.

**Fleet-weit mechanisch geprüft, 0 weitere Funde:** `PERF-07` (kritisches
`next()`-Löschmuster), `PERF-43` (`stdpath("cache")`), `PERF-70`…`73`
(begrenzte Nebenläufigkeit, kanonisch in `gopath.nvim` verifiziert),
`PERF-80` (18 Timer-Callbacks auf `vim.schedule`-Wrapping geprüft).

**Nachtrag (auf "ziehe perf durch" hin, zweite, tiefere Runde):** alle
verbleibenden Katalogzitate für `PERF-81`…`86` tatsächlich gelesen statt
nur übernommen (`github_stats.nvim/background.lua` für 81/82,
`pickers.nvim/smart/search.lua` für 84, `filetree.nvim`s `cwd_mode` für
85, `runtime-analysis.nvim/history.lua` für 86) — fünf exakt wie
beschrieben bestätigt, eines (`PERF-86`) mit seither verbesserter
Implementierung (der zitierte `MAX_ENTRIES`-Konstante wich einer
konfigurierbaren Funktion, Verhalten weiterhin korrekt). `PERF-83`
(Token-Cancel) vollständig gelesen statt nur der zuerst zitierten
Zeilen — echtes Zähler-Token-Muster bestätigt (`pending_token`,
`is_current()`), nicht nur ein killbarer Handle. Zusätzlich das komplette
Cache-Inventar der Fleet gelesen (`hover.nvim`, `insights.nvim`,
`language.nvim`, `pdfport.nvim`, `reposcope.nvim/repository_cache.lua` —
neun Cache-Implementierungen über neun Repos einzeln verifiziert für
`PERF-41`/`42`/`46`/`47`): 0 neue Funde, aber jetzt tatsächlich geprüft
statt nur durch Katalog-Beispiele plausibel gemacht.

**Katalog-Pflege-Nebenfunde** (nicht selbst korrigiert, Katalog liegt
außerhalb dieses Repos): zwei tote Zitate auf das per `db42bc9` entfernte
`pickers.nvim`-Feature `selected_index` (`PERF-48`, `PERF-63`), ein Zitat
auf eine bereits unter `LUA-40` gefixte Stelle (`color_my_ascii.nvim`,
`PERF-48`), und die Regelzahl selbst (57 → 62, nie korrigierte frühe
Schätzung).

## Größte Lektionen aus der gesamten Sweep-Serie

- **Cache-/State-Lifecycle-Code ist die ergiebigste Fundquelle.** Falsche
  Weak-Table-Annahmen (`LUA-40`/`41`), Referenz- statt In-Place-Mutation
  bei `clear()`/`reset()` (`PERF-47`, dieselbe Klasse mehrfach unter
  `ERR-*`), ungeschützte Wiederholungsaufrufe bei Timern (`PERF-62`/`82`)
  — drei verschiedene Regelnummern, dieselbe Bug-Familie.
- **Ermessens-Regeln ohne scharfes Pass/Fail-Kriterium verdienen keinen
  Vollaudit.** Ob ein Katalog explizit Messung vor Optimierung verlangt
  (`PERF-01`…`27`) oder schlicht eine Stilfrage ohne Gegenbeispiel ist
  (`LUA-31`/`34`/`81`/`83`) — ein Grep-Sweep über 32 Repos ohne
  Hotpath-Kontext erzeugt nur Rauschen, keine Funde.
- **Grep-Reichweite genau kalibrieren.** Ein zu weiter Grep (jedes
  `vim.env.*`, jedes `:stop(`/`:close(` ohne die `pcall(x.stop, x)`-
  Variante) erzeugt falsche Nullfunde oder Rauschen — immer die Regel
  genau lesen, bevor das Suchmuster gebaut wird, und ein Negativfund per
  vollständiger Lektüre der betroffenen Datei bestätigen, nicht nur per
  Grep-Fenstergröße.
- **Ein Fund ohne aktuelles Fehlverhalten ist trotzdem einen Fix wert**,
  wenn die eigene Dokumentation eine falsche Garantie behauptet (z. B.
  `trail.lua`s `M.clear`/`M.hydrate` — aktuell nicht getriggert, aber ein
  echter Vertragsbruch).
- **Große, cross-cutting Funde (≥5 Call-Sites, fehlendes Datenmodell-
  Feld) werden notiert, nicht im Rule-Sweep selbst gefixt** — gleiche
  Kalibrierung wie `PRIN-01` (casedesk.nvim UI-Monolith): eine echte
  Architekturentscheidung ist kein Ein-Datei-Fix.
- **Katalog-Zitate verfallen** — mehrfach zeigte ein Beleg auf bereits
  entfernten oder in einer früheren Familie bereits gefixten Code. Beim
  nächsten vollständigen Durchlauf lohnt sich ein Abgleich der
  `Belege/plugins/*.md`-Zitate gegen den aktuellen Fleet-Zustand als
  eigener, schneller Vorlauf.

## Standing Rules für diese Art Arbeit (bleiben gültig für künftige Sweeps)

- Antworten deutsch, Code/Kommentare englisch.
- Docs/README des jeweiligen Plugins mitpflegen, wenn ein echter Fund
  gefixt wird.
- Sofort auf `main` committen/pushen, sobald etwas in einem Repo gefixt
  wurde — nicht sammeln. **Vor dem Push immer `git fetch` + `git log
  HEAD..origin/main` prüfen** — CI-Bots (z. B. `docs(map): regenerate
  module map [skip ci]`) pushen zwischendurch auf dieselben Repos; ein
  simpler `git rebase origin/main` reicht dafür.
- Kein Claude-Co-Autor in Commit-Messages (weder in diesem Repo (nvim-config)
  noch in den einzelnen Plugin-Repos) — siehe Claudes Memory
  `no-coauthor-commits`.
- **1 Agent gleichzeitig, mehrere Runden zu je 1**, falls ein Subagent
  gebraucht wird — direktes Lesen in der Unterhaltung ist der Normalfall.
- **Erst grep-/mechanik-basierte Vorprüfung über alle 32 Repos**, bevor ein
  Repo einzeln gelesen wird.
- **Nicht jedes Repo hat ein automatisiertes Testframework** — gopath.nvim
  hat nur manuelle, interaktive Test-Fixtures. Bei fehlendem Framework:
  headless von Hand verifizieren statt eines Regressionstests, im Commit
  transparent machen.
- **Bei "Tabelle wird neu zugewiesen statt in-place gemutiert"-Mustern
  zählt nur, ob die Tabelle extern per Referenz gehalten wird** — ein
  privates Modul-Upvalue ist immer sicher, ein exponiertes `M.feld` nur
  riskant, wenn ein Aufrufer es tatsächlich in eine `local`-Variable
  kopiert statt bei jedem Zugriff frisch zu indizieren.
