# Handover — RULES.md Checklist-Familien-Sweep

Fortlaufende Arbeit an
[`docs/ROADMAP/personal/All/FINISH/RULES.md`](../personal/All/FINISH/RULES.md):
die 9 Regel-Familien aus `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/`
(`PRINCIPLES.md`, `LUA_NVIM.md`, `PERFORMANCE.md`) werden Familie für Familie
gegen alle 32 Personal-Plugin-Repos geprüft. `RULES.md` selbst ist die
laufende Quelle der Wahrheit für den Stand — diese Datei ist nur der
Einstiegspunkt für eine neue Session.

## Stand bei Übergabe (2026-09-07, dreizehnte Aktualisierung — PERF-* läuft)

| Familie | Status |
|---|---|
| `LLS-*` (34) | ✅ fertig |
| `SEC-*` (23) | ✅ fertig |
| `DEP-*` (7) | ✅ fertig |
| `TS-*` (5) | ✅ fertig |
| `ERR-*` (34) | ✅ fertig — 32/32 Repos, 17 echte Bugs gefixt |
| `UI-*` (34) | ✅ fertig — 32/32 Repos, 0 echte Bugs |
| `PRIN-*` (37) | ✅ fertig — 32/32 Repos, 1 Fund (notiert, nicht gefixt) |
| `LUA-*` (45) | ✅ **fertig** — 32/32 Repos, 4 Repos gefixt |
| `PERF-*` (62, korrigiert von 57) | 🔶 **läuft** — 1 Repo gefixt (documentation.nvim), Rest offen |

**8 von 9 Familien fertig, `PERF-*` (die letzte) läuft.** Regelzahl von 57
auf **62** korrigiert (`RULES.md` hatte nur eine frühe Schätzung stehen, nie
mit dem tatsächlichen Katalog abgeglichen — kein Tabellenformat-Artefakt wie
bei `LUA-67`/`68`, die 62 sind real: `PERF-01`…`16`, `20`…`27`, `40`…`53`,
`60`…`65`, `70`…`75`, `80`…`91`).

## PERF-* — bisheriger Fortschritt

**`PERF-07`** (🔴 KRITISCH, `next()`-Löschen während Iteration): fleet-weit
geprüft, **0 echte Verstöße** — der einzige Treffer war eine Glossar-Prosa-
Erklärung in `documentation.nvim`, kein Code.

**`PERF-47`** (Cache-`clear()`/`reset()` muss in-place mutieren, nicht per
`x = {}` neu zuweisen — sonst sieht jeder externe Halter der alten Referenz
die Leerung nie): 28 `clear`/`reset`/`clear_all`-Fundstellen fleet-weit per
`awk` extrahiert und einzeln geprüft, ob die neu zugewiesene Tabelle extern
per Referenz gehalten wird. 26/28 sind private Modul-Upvalues (sicher). Zwei
mit exponierter Tabelle (`mdview.nvim` `core/breadcrumbs.lua` `M.entries`,
`bindings/autocmds/buffer_switch.lua` `M._opened`) geprüft — ungefährlich,
kein Aufrufer hält je eine `local`-Referenz über die Zeit.

**Ein echter Fund:** `documentation.nvim`s
`lua/documentation/editor/browse/trail.lua`. `M.list(root)` gibt laut
eigenem Docstring bewusst die *live* Tabelle zurück (gehalten als
`st.pins = trail.list(st.root)` in `browse/init.lua`), aber `M.clear()` und
`M.hydrate()` machten `pins[root] = {}`/`pins[root] = list` — eine
Neuzuweisung, die den eigenen Vertrag brach. Aktuell latent (kein Aufrufer
hält aktuell über einen `clear`/`hydrate`-Aufruf hinweg eine stale
Referenz), aber ein echter Doku-Vertragsbruch, gefixt: beide mutieren jetzt
in-place. Regressionstest `TESTS/browse_trail_spec.lua` ergänzt, vorher
gegen den alten Code als fehlschlagend verifiziert (stash/reapply), volle
Suite grün, luacheck/stylua clean. Commit `179f16d` auf `documentation.nvim`
`main`, gepusht.

## Nächster Schritt: PERF-* fortsetzen

Noch offen: `PERF-01`…`06`/`08`…`16` (restliche allgemeine Idiome),
`PERF-20`…`27` (Speicherlayout), restliche `PERF-40`…`53` (Cache-Regeln
jenseits von `47`), `PERF-60`…`65` (Debouncing), `PERF-70`…`75` (begrenzte
Nebenläufigkeit/Scans), `PERF-80`…`91` (Async-Scheduling/Chunking/
Progress). Letztere drei Blöcke sind die Ermessens-lastigsten (Hotpath-
Beurteilung statt reinem Pattern-Matching) — lohnt sich, die
UI-lastigen/oft aufgerufenen Repos gezielt anzusehen (Statusline-
Komponenten, Autocmd-Handler, Picker-Rendering), statt alle 32 gleich
gründlich.

## LUA-* — Abschlussnotiz (letzte fertige Familie vor PERF-*)

**Wichtigster Fund: `LUA-40`/`41` (Metatables/Weak-Tables), fleet-weit
geprüft, 4 Repos gefixt.** `__mode = "k"` (schwache Schlüssel) wirkt in Lua
**nur** auf Tabellen/Funktionen/Userdata/Threads, niemals auf Zahlen. Zwei
Caches (lib.nvim `buffer/context/init.lua`, gopath.nvim `alias_index.lua`
+ `binding_index.lua`) waren mit `bufnr` (einer Zahl) als Schlüssel gebaut
und behaupteten in ihrer eigenen Dokumentation, tote Einträge würden
automatisch garbage-collected — das stimmte strukturell nie, beide Caches
wuchsen unbegrenzt über die gesamte Session. Beide gefixt: ein aktiver
`BufDelete`/`BufWipeout`-Autocmd übernimmt jetzt die echte Bereinigung.
lib.nvim mit vollem Regressionstest (`8b176be`, stash/reapply-verifiziert);
gopath.nvim hat kein Testframework, headless von Hand verifiziert
(`bd10baf`). Zwei weitere Repos (color_my_ascii.nvim `6577e66`,
filetree.nvim `0c92620`) hatten dieselbe irreführende Doku, aber bereits
funktionierende aktive Cleanup-Pfade — nur Doku korrigiert, keine
Verhaltensänderung.

## Standing Rules für diese Arbeit

- Antworten deutsch, Code/Kommentare englisch.
- Docs/README des jeweiligen Plugins mitpflegen, wenn ein echter Fund
  gefixt wird.
- Sofort auf `main` committen/pushen, sobald etwas in einem Repo gefixt
  wurde — nicht sammeln. **Vor dem Push immer `git fetch` + `git log
  HEAD..origin/main` prüfen** — CI-Bots (z. B. `docs(map): regenerate
  module map [skip ci]`) pushen zwischendurch auf dieselben Repos; ein
  simpler `git rebase origin/main` reicht dafür, kein Grund zum Stutzen.
- Kein Claude-Co-Autor in Commit-Messages (weder in diesem Repo (nvim-config)
  noch in den einzelnen Plugin-Repos) — siehe Claudes Memory
  `no-coauthor-commits`.
- Diese Handover-Datei bei jedem weiteren Fortschritt aktualisieren, nicht
  nur einmalig anlegen.
- **1 Agent gleichzeitig, mehrere Runden zu je 1**, falls ein Subagent
  gebraucht wird — direktes Lesen in der Unterhaltung ist der Normalfall.
- **Erst grep-/mechanik-basierte Vorprüfung über alle 32 Repos**, bevor ein
  Repo einzeln gelesen wird — hat bei jeder bisherigen Familie funktioniert.
- **Grep-Reichweite genau kalibrieren**: ein zu weiter Grep (z. B. jedes
  `vim.env.*` statt spezifisch `vim.env.REPOS_DIR`) erzeugt Rauschen, das
  mehr Zeit zum Aussortieren kostet als ein präziserer zweiter Versuch
  gebraucht hätte — lieber die Regel genau lesen, bevor das Suchmuster
  gebaut wird.
- **Nicht jedes Repo hat ein automatisiertes Testframework** — gopath.nvim
  hat nur manuelle, interaktive Test-Fixtures. Bei fehlendem Framework:
  headless von Hand verifizieren statt eines Regressionstests, im Commit
  transparent machen.
- **Ein Fund ohne Verhaltensänderung ist trotzdem einen Fix wert**, wenn
  die Dokumentation eine falsche Garantie behauptet — irreführende
  Kommentare/Docstrings über Speicher-Sicherheit sind ein Wartungsrisiko
  für die Zukunft, auch wenn heute kein echter Bug vorliegt.
- **Bei "Tabelle wird neu zugewiesen statt in-place gemutiert" (PERF-47-
  Muster) zählt nur, ob die Tabelle extern per Referenz gehalten wird** —
  ein privates Modul-Upvalue ist immer sicher (alle Zugriffe teilen sich
  denselben Upvalue-Slot), ein exponiertes `M.feld` ist nur riskant, wenn
  irgendein Aufrufer es tatsächlich in eine `local`-Variable kopiert statt
  bei jedem Zugriff frisch über `M.feld[...]` zu indizieren. Immer den
  Docstring der Getter-Funktion lesen — der verrät oft explizit, ob "live
  reference" ein bewusster Vertrag ist (wie bei `trail.lua`s `M.list`).
