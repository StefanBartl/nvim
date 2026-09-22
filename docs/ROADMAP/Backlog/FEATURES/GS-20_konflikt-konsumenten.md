# GS-20 — Konflikt-Konsumenten (`has_conflicts`)

**Repos:** gitsuite.nvim, color_my_ascii.nvim (Konsument von gitsuite),
debugging.nvim, sandbox.nvim · **Nutzen** 3 · **Aufwand** 0,5 · **Risiko**
niedrig · **Welle** 5 · erledigt 2026-09-22.

## Ausgangslage

Der Cross-Feature-Report nannte drei unabhängige Ideen rund um
`gitsuite.features.conflict`: ein Korrektheitsfund (Marker in
Markdown-Fenced-Codeblöcken zählen als echter Konflikt, obwohl sie nur ein
Doku-Beispiel sind) sowie zwei Einzeiler-Konsumenten (`debugging.nvim`s
Buffer-Report, `sandbox.nvim`s Devcontainer-Build-Preflight). Ein viertes,
im Report genanntes Ziel (`dap.nvim`-Konflikt-Guard vor `continue()`) blieb
bewusst geparkt (Nutzen 1, Spielerei).

## Umsetzung, je Repo

- **gitsuite.nvim** (`3b16e2a`):
  - `features/conflict/init.lua`: neue interne `filter_fenced(bufnr,
    regions)`, aufgerufen aus `M.scan()` nach `parser.parse()`. Pcall-weich
    gegen `color_my_ascii.api.fences.block_at(bufnr, region.start_line,
    { include_fence = true })` — eine Region zählt nur dann als gefiltert,
    wenn sowohl Start- als auch Endzeile innerhalb desselben Fence-Blocks
    liegen (`region.end_line <= block.close_row`). Ohne color_my_ascii.nvim
    unverändertes Verhalten (`pcall(require, ...)` schlägt fehl, Regions
    unverändert durchgereicht).
  - `M.list()` bekam einen optionalen zweiten Parameter `on_done(count)`,
    rückwärtskompatibel (einzige vorhandene Aufrufstelle, `:Git conflict
    list`, ruft weiterhin ohne Argument auf). Fails open: fehlt
    insights.nvim, wird `on_done(0)` aufgerufen (kein Blocker für einen
    Preflight-Konsumenten, nur eine Komfortprüfung).
  - Neue Tests in `TESTS/gitsuite/conflict_spec.lua`: drei Fälle für die
    Fence-Filterung (ohne color_my_ascii.nvim, mit gefaktem Modul innerhalb/
    außerhalb eines Blocks) und drei für `list()`s `on_done` (ohne
    insights.nvim, mit gefaktem Modul, `on_done` optional).
- **debugging.nvim** (`ea43eb9`): `actions/reports.lua`s `M.buf()` prüft
  nach `buflib.print_summary()` über eine neue interne `has_conflicts(bufnr)`
  (pcall gegen `gitsuite.features.conflict`) den aktuellen Buffer und warnt
  bei Treffer — erklärt sonst rätselhaftes Verhalten (falsches
  Syntax-Highlighting, LSP-Fehler) durch übersehene Konfliktmarker. Test in
  `TESTS/actions_spec.lua` (drei neue Fälle: abwesend/sauber/Konflikt,
  gegen `package.loaded`/`package.preload` gefakt) — Falle dabei gefunden:
  `buflib.print_summary()` selbst `notify.debug()`t bereits eine
  "Listed buffer: N"-Zeile bei jedem Aufruf, ein `#seen == 0`-Assert wäre
  also unabhängig von diesem Feature fehlgeschlagen; die Tests prüfen
  stattdessen auf den Inhalt der Konflikt-Warnung.
- **sandbox.nvim** (`6b3b505`): `bindings/usrcmds/devcontainer_commands.lua`
  bekam eine neue interne `preflight_conflicts(run_build)`, die `M.build()`
  jetzt umschließt: pcall gegen `gitsuite.features.conflict`, bei Treffer
  `conflict.list(on_done)` mit `count > 0` → `notify.error(...)` und
  Build-Abbruch (die `usecase(...)`, die `workspace_dir` ungeprüft mountet,
  wird gar nicht erst aufgerufen); `count == 0` oder fehlendes gitsuite.nvim
  → `run_build()` wie zuvor. Drei neue Tests in
  `TESTS/sandbox/bindings/usrcmds/commands_misc_spec.lua` (fails open ohne
  gitsuite.nvim, baut bei 0 Konflikten, bricht bei > 0 Konflikten ab und
  `H.build_calls` bleibt leer).

## Nicht umgesetzt — bewusst geparkt

`dap.nvim`-Konflikt-Guard vor `continue()` (Nutzen 1 laut Bewertung, siehe
[Bewusst geparkt](../../personal/All/FINISH/Final_Checks/gitsuite.nvim.md#bewusst-geparkt-oder-verworfen)
in der ursprünglichen Plan-Fassung) — nicht Teil dieser Karte.

## Tests

Alle drei Repos: `stylua --check` und `luacheck` grün. Lokale Suiten grün —
gitsuite.nvim: volle `TESTS/gitsuite/`-Suite (`scripts/test.sh`, keine
Fehlschläge); debugging.nvim: volle Suite (`DEBUGGING_TESTS_OK`);
sandbox.nvim: volle Plenary-Suite (160+7 Tests, `Failed: 0` überall).

## Ergebnis

Alle drei Commits einzeln nach `main` gepusht, CI auf allen drei Repos
grün (`gh run view` bestätigt `completed success` für alle drei Läufe).
Keine `lib.nvim`-Änderung in dieser Karte, also kein `ci-verified`-Wartezeit
nötig (K-6 nicht einschlägig).

## Dokumentation mitgezogen

- gitsuite.nvim: `docs/requirements.md` — zwei neue Zeilen in der
  Optional-Tabelle (`insights.nvim`, das schon vorher `conflict.list()`
  soft-abhängte, aber dort bisher fehlte; `color_my_ascii.nvim`, die neue
  Abhängigkeit dieser Karte).
- debugging.nvim: `docs/installation.md` — gitsuite.nvim zur
  Optional-Liste ergänzt.
- sandbox.nvim: `docs/installation.md` — gitsuite.nvim zur Optional-Liste
  ergänzt.

`docs/around-it.md` (gitsuite.nvim) und `docs/architecture.md`s
Konsumenten-Liste bewusst nicht angefasst — deren Scope ist laut eigenem
Seiten-Zweck auf die im Titel genannten Plugins beschränkt, color_my_ascii/
debugging/sandbox gehören dort nicht rein. Separater Befund dabei
aufgefallen: `docs/around-it.md` behauptet "insights.nvim — no dependency
in either direction", was mit dem tatsächlichen Code (`conflict.list()`
pcallt `insights.conflicts` seit vor dieser Karte) nicht übereinstimmt —
vorbestehende Ungenauigkeit, nicht durch diese Karte verursacht, nicht
hier mitkorrigiert.
