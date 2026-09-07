# Handover — RULES.md Checklist-Familien-Sweep

Fortlaufende Arbeit an
[`docs/ROADMAP/personal/All/FINISH/RULES.md`](../personal/All/FINISH/RULES.md):
die 9 Regel-Familien aus `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/`
(`PRINCIPLES.md`, `LUA_NVIM.md`, `PERFORMANCE.md`) werden Familie für Familie
gegen alle 32 Personal-Plugin-Repos geprüft. `RULES.md` selbst ist die
laufende Quelle der Wahrheit für den Stand — diese Datei ist nur der
Einstiegspunkt für eine neue Session.

## Stand bei Übergabe (2026-09-07, zwölfte Aktualisierung — nur noch PERF-* offen)

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
| `PERF-*` (57) | ⬜ **einzige verbleibende Familie** |

**8 von 9 Familien sind jetzt fertig.** Nur `PERF-*` (57 Regeln,
Performance-Patterns) steht noch aus — die im Voraus als vermutlich
aufwendigste eingeschätzte Familie, da Hotpath-Beurteilung Verständnis von
Aufrufhäufigkeit statt reinem Pattern-Matching braucht.

## LUA-* — Abschlussnotiz

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

**Alle übrigen Regeln** entweder fleet-weit mechanisch bestätigt
(`LUA-04` Env-Var-Zugriff, `LUA-42`..`47` weitere Metatable-Muster,
`LUA-50`/`52`/`54`/`55` Naming/Kommentare/Emojis/Swap, `LUA-80`
Config-Dateistruktur) oder durch bereits abgeschlossene Arbeit abgedeckt
(`LUA-53` durch den CDX-Kommentar-Sweep vom 2026-09-06, `LUA-60`..`71`
durch die `LLS-*`-Familie, `LUA-10`..`16` durch `ERR-32`/`33`/`34`,
`LUA-30`/`33` durch `PRIN-10`/`13`). Ein kleiner Rest
(`LUA-01`..`03`/`05`, `31`/`34`, `81`/`83`) wurde bewusst nicht einzeln
nachgejagt — Begründung je Regel steht in `RULES.md` unter „Nicht einzeln
nachgejagt".

Zwei im Katalog selbst vermerkte Lücken (`LUA-01` fileops.nvim, `LUA-04`
pickers.nvim) waren beide schon am 2026-09-06 gefixt, nur der Katalog-Text
noch nicht aktualisiert — verifiziert, nicht erneut angefasst.

## Nächster Schritt: PERF-*

Neue Session sollte zuerst `PERFORMANCE.md` lesen (noch nicht geöffnet in
dieser Sweep-Serie) und prüfen, ob — wie bei `UI-*`/`PRIN-*` — Teile davon
schon aus Beobachtung dieses Fleets entstanden sind (Belege-Abschnitte mit
Repo-Zitaten). Gegeben, wie das bei jeder bisherigen Familie ausging (0 bis
sehr wenige Funde, meist schon dokumentiert), ist die Erwartung ähnlich —
aber das ist eine Erwartung, keine Abkürzung: jede Regel verdient einen
echten Blick.

Da `PERF-*` explizit als „größte und teuerste" Familie eingeschätzt wurde
(Hotpath-Beurteilung statt reinem Pattern-Matching), lohnt sich hier
besonders, zuerst die mechanisch prüfbaren Teilregeln zu identifizieren
(z. B. `pcall`-Vermeidung im Hotpath, `vim.fn.*`-Aufrufhäufigkeit,
Debounce-Nutzung, Cache-Trefferquoten) und die genuinen
Hotpath-Ermessensfragen (die tatsächlich Kontext über Aufrufhäufigkeit
brauchen) gezielt auf die UI-lastigen/oft aufgerufenen Repos zu
konzentrieren (Statusline-Komponenten, Autocmd-Handler, Picker-Rendering).

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
