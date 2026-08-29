# Diagnostics -- LSP-Befund über alle Plugins

Ergebnis des Roadmap-Punkts *"`<leader>wq`: alle damit auffindbaren Issues live
durchgehen"* (aus `FINISH/MERGED.md`, Liste A / Live-Testing).

Stand: 2026-08-29. Umfang: 31 `*.nvim`-Repos unter `C:/repos` plus diese
nvim-Config. 32 Workspaces, ~2900 Lua-Dateien.

**Kurzfassung:** 3600 Diagnosen in 742 Dateien -- **alle Severity `Warning`,
kein einziger `Error`**. Etwa die Hälfte davon (1770) liegt in `TESTS/`, nicht
im ausgelieferten Code. Der große Rest zerfällt in sechs Ursachen-Cluster, von
denen vier musterhaft und nicht einzeln zu beheben sind.

---

## Table of content

  - [1. Methode](#1-methode)
  - [2. Gesamtbild pro Repo](#2-gesamtbild-pro-repo)
  - [3. Verteilung nach Regel](#3-verteilung-nach-regel)
  - [4. Die Ursachen-Cluster](#4-die-ursachen-cluster)
    - [A. Fehlender `assert`-Typ in den Tests -- gemessen, nicht geschätzt](#a-fehlender-assert-typ-in-den-tests-gemessen-nicht-geschtzt)
    - [B. `need-check-nil` in Tests -- 925 Stück, mechanisch](#b-need-check-nil-in-tests-925-stck-mechanisch)
    - [C. `missing-fields` (441) -- Modellierungsfehler, kein Aufruffehler](#c-missing-fields-441-modellierungsfehler-kein-aufruffehler)
    - [D. `userdata` statt `TSNode` in documentation.nvim -- 210 Stück](#d-userdata-statt-tsnode-in-documentationnvim-210-stck)
    - [E. `pcall(vim.cmd, ...)` -- 60 Stück über alle Repos](#e-pcallvimcmd-60-stck-ber-alle-repos)
    - [F. `inject-field` (119) -- fast vollständig lib.nvim](#f-inject-field-119-fast-vollstndig-libnvim)
  - [5. Die kleinen, echten Befunde](#5-die-kleinen-echten-befunde)
    - [`deprecated` (23) -- veraltete Neovim-APIs](#deprecated-23-veraltete-neovim-apis)
    - [`missing-parameter` (6) -- Aufruf mit zu wenig Argumenten](#missing-parameter-6-aufruf-mit-zu-wenig-argumenten)
    - [`luadoc-miss-symbol` (7) -- kaputte Annotation, Klammer fehlt](#luadoc-miss-symbol-7-kaputte-annotation-klammer-fehlt)
    - [`duplicate-set-field` (8 in `lua/`)](#duplicate-set-field-8-in-lua)
    - [`duplicate-doc-alias` (5) -- derselbe Typname zweimal definiert](#duplicate-doc-alias-5-derselbe-typname-zweimal-definiert)
    - [`unbalanced-assignments` (1)](#unbalanced-assignments-1)
    - [`invisible` (1)](#invisible-1)
    - [`different-requires` (41) -- ausschließlich nvim-Config](#different-requires-41-ausschlielich-nvim-config)
    - [Weitere Annotationsfehler (144)](#weitere-annotationsfehler-144)
  - [6. stylua](#6-stylua)
  - [7. Nebenbefunde](#7-nebenbefunde)
  - [8. Was daraus folgt](#8-was-daraus-folgt)
  - [9. Anhang: der delegierbare Teil des Roadmap-Punkts](#9-anhang-der-delegierbare-teil-des-roadmap-punkts)

---

## 1. Methode

`<leader>wq` ist `lsp.bindings.actions.diag_to_qflist` ->
`lsp.diagnostics.quickfix.to_qf({open=true})` -> `vim.diagnostic.setqflist()`,
also **alle Diagnosen aller geladenen Buffer**, in der Praxis kombiniert mit
`lsp.core.workspace_diagnostics`, das beim Attach die Repo-Dateien nachlädt.
Das Äquivalent ohne laufende Session ist `lua-language-server --check` pro Repo.

Damit der Befund dem entspricht, was der Editor tatsächlich zeigt, wurde die
Prüf-Config pro Repo aus drei Quellen zusammengesetzt:

1. die `.luarc.json` des Repos (alle 31 haben eine),
2. das, was `lsp.nvim` zur Laufzeit injiziert und *nicht* in der `.luarc.json`
   steht -- `library_profiles.build_runtime_library()` hängt `$VIMRUNTIME/lua`,
   `${3rd}/luv/library` und `${3rd}/busted/library` an (11 der 31 `.luarc.json`
   führen `$VIMRUNTIME/lua` selbst nicht),
3. die Cross-Repo-Typen, die lazydev live nachzieht: für jedes Repo die
   `lua/`-Verzeichnisse aller Repos, die es (transitiv) `require`t.

Punkt 3 wurde gegengeprüft: ein Lauf mit 1+2 allein ergab 4139 Warnungen über
die 31 Repos, mit Punkt 3 dazu 3781. Die Differenz sind Phantom-Befunde --
davon allein ~220 `undefined-doc-name` auf `Lib.*`-, `RA.*`- und
`Documentation.*`-Typen, die es im Editor nie gibt, weil lazydev sie dort
auflöst. Punkt 2 ist nicht separat gemessen, aber ohne ihn hätten 11 der 31
Repos überhaupt keine `vim.*`-Typen.

Kommandozeile pro Repo:

```bash
lua-language-server --check "C:/repos/<repo>" --checklevel=Warning --check_format=json --check_out_path=<out>.json --configpath=<merged>.json
```

Laufzeit gesamt: rund 10 Minuten. LuaLS 3.18.2-dev, Neovim 0.12.2.

**Grenze der Methode.** `--checklevel=Warning` erfasst `Error` + `Warning`.
`Hint`/`Information` (ungenutzte Locals, fehlende Felder in Hover-Doku) sind
bewusst draußen -- die zeigt `<leader>wq` zwar auch, sie sind aber keine
Fehlerklasse. Außerdem indiziert LuaLS Punkt-Verzeichnisse nicht, `.claude/`
und `.git/` bleiben also außen vor (im Scan-Log verifiziert).

---

## 2. Gesamtbild pro Repo

| Repo | gesamt | `lua/` | `TESTS/` | Rest |
|---|---:|---:|---:|---:|
| documentation.nvim | 753 | 326 | 405 | 22 |
| lib.nvim | 532 | 304 | 226 | 2 |
| filetree.nvim | 314 | 142 | 172 | 0 |
| runtime-analysis.nvim | 271 | 50 | 220 | 1 |
| lsp.nvim | 233 | 132 | 100 | 1 |
| nvim-config | 185 | 183 | 0 | 2 |
| spotlight.nvim | 157 | 14 | 143 | 0 |
| mdview.nvim | 115 | 91 | 24 | 0 |
| gopath.nvim | 107 | 63 | 1 | 43 |
| open.nvim | 106 | 8 | 98 | 0 |
| pdfport.nvim | 106 | 80 | 26 | 0 |
| github_stats.nvim | 93 | 27 | 66 | 0 |
| markdown.nvim | 71 | 15 | 56 | 0 |
| sandbox.nvim | 70 | 44 | 26 | 0 |
| diff.nvim | 62 | 12 | 50 | 0 |
| replacer.nvim | 60 | 30 | 30 | 0 |
| images.nvim | 46 | 22 | 23 | 1 |
| fileops.nvim | 40 | 33 | 7 | 0 |
| language.nvim | 40 | 36 | 4 | 0 |
| pickers.nvim | 39 | 32 | 7 | 0 |
| cascade.nvim | 35 | 17 | 18 | 0 |
| insights.nvim | 31 | 26 | 5 | 0 |
| emojis.nvim | 28 | 10 | 18 | 0 |
| sessions.nvim | 23 | 13 | 10 | 0 |
| debugging.nvim | 17 | 6 | 11 | 0 |
| recommender.nvim | 15 | 6 | 9 | 0 |
| dap.nvim | 14 | 7 | 7 | 0 |
| reposcope.nvim | 10 | 5 | 5 | 0 |
| color_my_ascii.nvim | 9 | 8 | 1 | 0 |
| buffer-ctx.nvim | 8 | 6 | 2 | 0 |
| migrate.nvim | 6 | 6 | 0 | 0 |
| cmdlog.nvim | 4 | 4 | 0 | 0 |
| **Summe** | **3600** | **1758** | **1770** | **72** |

Die vier größten Repos stellen 52 Prozent aller Befunde. Sieben Repos liegen im
einstelligen bis niedrigen zweistelligen Bereich und sind praktisch fertig.

---

## 3. Verteilung nach Regel

| Regel | gesamt | davon `lua/` |
|---|---:|---:|
| `need-check-nil` | 1190 | 265 |
| `param-type-mismatch` | 510 | 336 |
| `undefined-field` | 507 | 396 |
| `missing-fields` | 441 | 111 |
| `assign-type-mismatch` | 160 | 122 |
| `duplicate-set-field` | 135 | 8 |
| `redundant-parameter` | 126 | 27 |
| `inject-field` | 120 | 119 |
| `undefined-doc-name` | 55 | 48 |
| `return-type-mismatch` | 52 | 44 |
| `duplicate-doc-field` | 47 | 47 |
| `different-requires` | 41 | 41 |
| `undefined-doc-param` | 37 | 37 |
| `missing-return-value` | 35 | 35 |
| `duplicate-doc-param` | 30 | 30 |
| `cast-local-type` | 26 | 26 |
| `redundant-return-value` | 25 | 14 |
| `deprecated` | 23 | 23 |
| `missing-return` | 17 | 9 |
| `missing-parameter` | 8 | 6 |
| `luadoc-miss-symbol` | 7 | 7 |
| `duplicate-doc-alias` | 5 | 5 |
| `invisible` | 2 | 1 |
| `unbalanced-assignments` | 1 | 1 |

---

## 4. Die Ursachen-Cluster

---

### A. Fehlender `assert`-Typ in den Tests -- gemessen, nicht geschätzt

`assert.are.same(...)`, `assert.is_true(...)`, `assert.is_nil(...)`: LuaLS kennt
den globalen `assert` nur als Lua-Standardfunktion, nicht als luassert. Jedes
Feld daran ist `undefined-field`. `${3rd}/busted/library` -- was `lsp.nvim`
heute anhängt -- deckt das **nicht** ab, `${3rd}/luassert/library` definiert die
Klasse, aber nicht den globalen Namen.

Vier Zeilen genügen:

```lua
---@meta
---@type luassert
assert = assert
```

Als Library-Pfad eingehängt (oder als Datei im Repo mit `---@meta`) fällt
**lsp.nvim von 465 auf 233 Warnungen** -- gemessen, nicht hochgerechnet:
`undefined-field` -272, dafür `redundant-parameter` +40, weil die
LuaLS-Signaturen für luassert enger sind als dessen tatsächliche variadische
API. Über alle Repos: 3966 -> 3600. Der Effekt trifft die Repos ungleich, weil
nicht alle im selben Stil assertieren -- documentation.nvim,
runtime-analysis.nvim und filetree.nvim ändern sich dadurch gar nicht.

Alle Zahlen in diesem Dokument sind **nach** diesem Fix gemessen. Er ist noch
nirgends eingebaut.

---

### B. `need-check-nil` in Tests -- 925 Stück, mechanisch

Das dominante Muster in `TESTS/`: `local ok, mod = pcall(require, "x")` und
danach `mod.foo()` ohne Nil-Prüfung, bzw. `vim.fn.getreg`-Rückgaben direkt
weiterverwendet. In Testcode ist das absichtlich -- schlägt der `require` fehl,
soll der Test krachen. Behebbar entweder durch `assert(mod)` vor der Nutzung
oder durch `diagnostics.disable` für `need-check-nil` in einer
`TESTS/.luarc.json`.

Hotspots: `filetree.nvim/TESTS/units.lua` (31),
`runtime-analysis.nvim/TESTS/telemetry_spec.lua` (52),
`documentation.nvim/TESTS/mcp_spec.lua` (41),
`gopath.nvim/scripts/ci/functional_tests.lua` (34),
`open.nvim/TESTS/usrcmds_spec.lua` (29).

Die restlichen 265 `need-check-nil` liegen in `lua/` und sind **echt** -- das
sind Stellen, an denen ein `string|nil` ungeprüft weitergereicht wird.

---

### C. `missing-fields` (441) -- Modellierungsfehler, kein Aufruffehler

`Missing required fields in type 'Pickers.Config': depth_aliases, find, ...`

Die `@class *.Config`-Klassen deklarieren ihre Felder als Pflicht. Jedes
partielle `setup({...})` verletzt sie damit -- obwohl genau das die vorgesehene
Nutzung ist. `lua/plugins/personal/init.lua` sammelt allein 15 solcher
Warnungen ein, ohne dass am Aufruf irgendetwas falsch wäre.

Betroffen sind unter anderem `Pickers.Config`, `Documentation.Opts`,
`FiletreeConfig`, `OpenNvim.Config`, `PdfPort.Config`, `Dbg.Config`,
`DiffNvim.Config`, `Emojis.Config`, `Spotlight.Config`, `LspNvim.Config`,
`GHStats.SetupOptions`, `LanguageConfig`, `ImagesNvim.Config`.

Der Fix ist überall derselbe und gehört in die Plugins, nicht in die Aufrufer:
die **Opts**-Klasse (was der Nutzer übergibt) von der **Config**-Klasse (was
nach `vim.tbl_deep_extend` herauskommt) trennen, und in der Opts-Variante jedes
Feld als `---@field name? type` führen.

---

### D. `userdata` statt `TSNode` in documentation.nvim -- 210 Stück

`Undefined field 'iter_children'` (92), `'start'` (65), `'end_'` (28), `'type'`
(25). Ursache ist eine einzelne Annotation, wiederholt über alle Sprachmodule:

```lua
---@param node userdata
local function child_of(node, kind)
  for child in node:iter_children() do
```

`userdata` hat keine Felder. `---@param node TSNode` und die 210 Warnungen sind
weg -- Neovim liefert die Meta-Definitionen in
`$VIMRUNTIME/lua/vim/treesitter/_meta/tsnode.lua` mit. Betroffen:
`documentation/core/lang/{ecma,python,csharp,scala,kotlin,swift,rust,cfamily,elixir,dart,...}.lua`.

Das erklärt den Großteil von documentation.nvims 326 `lua/`-Warnungen.

---

### E. `pcall(vim.cmd, ...)` -- 60 Stück über alle Repos

`Cannot assign 'table' to parameter 'fun(...any):...unknown'`. `vim.cmd` ist in
Neovims Meta-Definition eine aufrufbare **Tabelle**, keine Funktion, passt also
nicht auf `pcall`s ersten Parameter. Der Aufruf funktioniert zur Laufzeit
einwandfrei, LuaLS kann es nur nicht ausdrücken.

Fix: `pcall(function() vim.cmd(...) end)`. Häufungen in
`fileops.nvim/lua/fileops/ops/file.lua` (12), `ops/cycle.lua` (6),
`filetree.nvim/lua/filetree/adapter/{netrw,oil}.lua`, `sessions.nvim/core.lua`.

---

### F. `inject-field` (119) -- fast vollständig lib.nvim

`Fields cannot be injected into the reference of 'LibStringsCore' for 'trim'.`

Das Muster: `---@class LibStringsCore` deklariert die Felder, dann folgen
`function S.trim(...)`-Definitionen, die LuaLS als Injektion in eine bereits
geschlossene Klasse liest. Konzentriert in
`lib/lua/tables/{set,core,array,safe,dict,functional}.lua` (~90) und
`lib/lua/strings/core.lua` (21). Ein Muster, ein Fix pro Datei.

---

## 5. Die kleinen, echten Befunde

Diese sind **nicht** musterhaft, sondern einzeln zu prüfen. Zusammen ~90 Stück
-- das ist die Liste, bei der sich Durchgehen am ehesten lohnt.

---

### `deprecated` (23) -- veraltete Neovim-APIs

| API | Ersatz | Fundstellen |
|---|---|---|
| `vim.lsp.stop_client` | `client:stop()` | lsp.nvim: `usercmds/stop.lua:39,43,55,88`, `usercmds/restart.lua:67,99`, `usercmds/recovery.lua:137` |
| `vim.diff` | `vim.text.diff` | diff.nvim: `core/render.lua:26,398,442`, `health.lua:25` |
| `vim.fn.termopen` | `vim.fn.jobstart(..., {term=true})` | debugging.nvim `tools/proc_trace.lua:130`, filetree.nvim `features/system/shell_run/init.lua:58` |
| `vim.api.nvim_buf_get_option` | `nvim_get_option_value` | lib.nvim `buf_win_tab/get_option/init.lua:24` |
| `vim.api.nvim_buf_add_highlight` | `vim.hl.range` / Extmarks | sandbox.nvim `ui/list_view.lua:47` |
| `vim.lsp.get_log_path` | `vim.lsp.log.get_filename()` | lsp.nvim `bindings/usrcmds.lua:405` |

Sechs weitere sind **bewusste Fallbacks** für ältere Neovim-Versionen und
sollten so bleiben -- wer sie "repariert", bricht die Abwärtskompatibilität:
`vim.islist or vim.tbl_islist` (lib.nvim `logger/serialize.lua:72,73`),
`vim.lsp.get_clients or vim.lsp.get_active_clients` (gopath.nvim `health.lua:94`,
language.nvim `spell/providers/lsp.lua:23`), `vim.diagnostic.goto_next/goto_prev`
im Alt-API-Zweig (language.nvim `spell/init.lua:170`).

---

### `missing-parameter` (6) -- Aufruf mit zu wenig Argumenten

- `buffer-ctx.nvim/lua/buffer_ctx/format/column_align.lua:47` (3 erwartet, 2 übergeben)
- `fileops.nvim/lua/fileops/bindings/keymaps.lua:256` (1 erwartet, 0)
- `lsp.nvim/lua/lsp/servers/lua_ls/reload.lua:106` (3 erwartet, 2)
- `lsp.nvim/lua/lsp/usercmds/init.lua:66` (1 erwartet, 0)
- `lsp.nvim/lua/lsp/usercmds/stop.lua:54` und `:83` (1 erwartet, 0)

---

### `luadoc-miss-symbol` (7) -- kaputte Annotation, Klammer fehlt

- `fileops.nvim/lua/fileops/ops/file.lua:628` (`}` erwartet)
- `lib.nvim/lua/lib/nvim/buf_win_tab/@types/resize_guarded.lua:40`
- `lib.nvim/lua/lib/nvim/cross/@types/init.lua:20`
- `lib.nvim/lua/lib/nvim/cross/fs/mutate/@types/init.lua:13`
- `pickers.nvim/lua/pickers/ui/{action_picker.lua:9,dir_nav_picker.lua:15,scope_picker.lua:34}`

Diese sieben sind der einzige Fall, in dem eine Annotation gar nicht geparst
wird -- der dokumentierte Typ existiert dort effektiv nicht.

---

### `duplicate-set-field` (8 in `lua/`)

- `filetree.nvim/lua/filetree/features/infra/watcher_quarantine/init.lua:76` -- `notify`
- `images.nvim/lua/images/debug.lua:86` -- `draw`
- `lib.nvim/lua/lib/nvim/system/proc_trace.lua:144,158` -- `system`, `jobstart`
- `sandbox.nvim/lua/sandbox/bindings/usrcmds/init.lua:74` -- `notify`
- `nvim-config/lua/bindings/mappings/editing.lua:216` -- `paste`
- `nvim-config/lua/config/todo_comments/init.lua:42` -- `nvim_buf_set_extmark`
- `nvim-config/lua/config/ui_open.lua:43` -- `open`

Die in `proc_trace.lua` und `todo_comments` sind vermutlich beabsichtigtes
Monkey-Patching; die übrigen sind zu prüfen.

---

### `duplicate-doc-alias` (5) -- derselbe Typname zweimal definiert

`LogLevel` existiert dreifach: `lib.nvim/lua/lib/nvim/notify/@types/init.lua:9`,
`gopath.nvim/lua/gopath/util/@types/init.lua:28` und
`nvim-config/lua/@types/log.lua:20`. Dazu `LogLevelNumber`
(`nvim-config/lua/@types/log.lua:12`) und `Result`
(`nvim-config/lua/@types/functional.lua:26`) gegen lib.nvim.

Das ist echt und fällt im Editor an, weil lazydev lib.nvim mitlädt: welche
Definition gewinnt, ist nicht bestimmt. Kandidat für "einmal in lib.nvim
definieren, überall referenzieren".

---

### `unbalanced-assignments` (1)

`lib.nvim/lua/lib/nvim/bindings/autocmd/docs.lua:591` -- eine Variable bekommt
still `nil`, weil die rechte Seite zu wenige Werte liefert.

---

### `invisible` (1)

`lsp.nvim/lua/lsp/integrations/trouble.lua:84` greift auf
`vim.treesitter.highlighter._on_win` zu -- privates Upstream-Feld. Bekannt
riskant, aber bewusst; gehört dokumentiert statt behoben.

---

### `different-requires` (41) -- ausschließlich nvim-Config

`The same file is required with different names` -- dieselbe Datei wird einmal
als `require("autocmds.git")` und einmal als `require("autocmds.git.init")`
gezogen. Betroffen u.a. `lua/autocmds/{git,terminals,text}/init.lua`,
`lua/config/neotree/keymaps/init.lua`,
`lua/wkdnvchad/config/statusline/{custom,custom_minimal,normal}.lua`,
`lua/wkdnvchad/mappings/init.lua`. Kosmetisch, aber es führt dazu, dass Module
doppelt im `package.loaded`-Cache landen können.

---

### Weitere Annotationsfehler (144)

`duplicate-doc-field` (47, davon 30 allein in
`lsp.nvim/lua/lsp/@types/vim_lsp.lua`), `undefined-doc-param` (37, d.h. `@param`
auf einen Parameter, den die Funktion nicht hat), `duplicate-doc-param` (30,
u.a. `emojis.nvim/lua/emojis/search.lua:181-185`,
`images.nvim/lua/images/paste.lua`), `missing-return-value` (35, Hotspot
`gopath.nvim/lua/gopath/resolve.lua` mit 11 und
`pdfport.nvim/lua/pdfport/integrations/init.lua` mit 8),
`redundant-return-value` (14), `undefined-doc-name` (48).

Alles Doku-gegen-Code-Abweichungen: niedriges Risiko, hoher Aufräumwert, gut
delegierbar.

---

## 6. stylua

`stylua --check` über alle 31 Repos: **28 sauber**, ursprünglich 4 Dateien in
3 Repos abweichend. Alle vier sind derselbe Fall -- ein einzeiliges
`function() ... end`, das stylua aufklappen will:

- `emojis.nvim/plugin/emojis.lua`, `emojis.nvim/plugin/emojis_autodoc.lua`
- `gopath.nvim/scripts/ci/headless_tests.lua`
- ~~`mdview.nvim/docs/templates/usercmds.lua`~~ -- **erledigt 2026-08-29**

**Erledigt:** `mdview.nvim` formatierte als einziges der 31 Repos mit Tabs
(`indent_type = "Tabs"`, `indent_width = 4`). Auf die Repo-Konvention
`Spaces` / `2` umgestellt und einmal durchformatiert; damit ist auch die
Templatedatei oben abgehakt. Siehe
[`Diagnostics_FINISHED.md`](../../../Diagnostics_FINISHED.md).

Offen bleiben die drei Dateien in emojis.nvim und gopath.nvim.

---

## 7. Nebenbefunde

- ~~**Übrig gebliebener Claude-Worktree in `open.nvim`.**~~ **Erledigt
  2026-08-29:** Worktree und beide Altbranches entfernt, nachdem geprüft war,
  dass ihre zwei Commits inhaltlich schon auf `main` liegen. `.claude/` ist
  dort jetzt gitignored. Siehe
  [`Diagnostics_FINISHED.md`](../../../Diagnostics_FINISHED.md).
- **Zwei Worktrees in dieser Config:**
  `.claude/worktrees/dazzling-chaplygin-5284d5` und `serene-gagarin-e46262`,
  zusammen 1620 Lua-Dateien. Hier ist `.claude/` gitignored, also auch für
  LuaLS unsichtbar -- reiner Plattenplatz.
- **`.claude/` ist in sieben Repos nicht gitignored** (diff, documentation,
  lib, markdown, mdview, recommender, replacer) -- in allen sieben ist das
  Verzeichnis leer, also folgenlos, solange dort kein Worktree entsteht.
  open.nvim war der achte und ist seit 2026-08-29 versorgt.
- **11 von 31 `.luarc.json` führen `$VIMRUNTIME/lua` nicht** und verlassen sich
  darauf, dass `lsp.nvim` es zur Laufzeit injiziert. Für den Editor reicht das;
  jedes CI, das `lua-language-server --check` direkt aufruft, bekommt dort eine
  andere Typwelt als der Editor. Betrifft buffer-ctx, color_my_ascii,
  documentation, emojis, fileops, github_stats, gopath, insights, lib,
  replacer, runtime-analysis, sandbox, sessions.

---

## 8. Was daraus folgt

Nach Aufwand-zu-Wirkung geordnet:

1. **`assert`-Meta einbauen** -- vier Zeilen, gemessene 366 Warnungen weniger,
   und es macht die Testdateien überhaupt erst typgeprüft. Sinnvollerweise in
   lib.nvim, damit alle Repos denselben Pfad einhängen.
2. **`TSNode` statt `userdata` in documentation.nvim** -- eine Annotation pro
   Sprachmodul, ~210 Warnungen.
3. **Opts/Config trennen** (Cluster C) -- ~440 Warnungen, aber echte API-Arbeit
   pro Plugin, kein Suchen-und-Ersetzen.
4. **Die ~90 kleinen Befunde aus Abschnitt 5** -- der Teil, bei dem Durchgehen
   tatsächlich Fehler findet statt Rauschen. Hier liegen die einzigen
   Kandidaten für echte Laufzeitfehler (`missing-parameter`,
   `unbalanced-assignments`, `luadoc-miss-symbol`).
5. **`need-check-nil` in Tests** (925) -- Entscheidung nötig: unterdrücken oder
   auszementieren. Nicht beides.
6. **`inject-field` in lib.nvim** (119) und der `pcall(vim.cmd, ...)`-Fix (60)
   -- beides mechanisch.
7. ~~**stylua**~~ -- die Tabs-Entscheidung für mdview ist gefallen (angeglichen,
   2026-08-29), es bleiben drei Dateien in emojis.nvim und gopath.nvim.

Punkt 1, 2, 6 und 7 sind zusammen ~750 Warnungen und rein mechanisch. Punkt 4
ist der inhaltlich interessante Teil.

---

## 9. Anhang: der delegierbare Teil des Roadmap-Punkts

Der ursprüngliche Eintrag trug den Zusatz *"Das Refactoring der `wq`-Logik nach
`lib.nvim.ui` selbst ist delegierbar"*. Rekonstruktion, was gemeint war:

`lib.nvim/lua/lib/nvim/ui/` enthält `hl`, `kit`, `nerd_font`, `statusline` --
**kein** Quickfix-/Loclist-Modul. Gleichzeitig bauen 20 Dateien in 14 Repos ihre
`setqflist`/`setloclist`-Senke jeweils selbst: `spotlight/qf.lua`,
`replacer/export.lua`, `markdown/core/{refs,link_diagnostics}.lua`,
`documentation/bindings/usrcmds/*.lua` (11 Dateien),
`filetree/{features/search/grep_in_dir,util/refs_picker}`,
`insights/conflicts/init.lua`, `language/spell/ui/list.lua`,
`diff/core/{directory,render}.lua`, `emojis/{actions,search}.lua`,
`debugging/autocmds/sources.lua`, `runtime-analysis/bindings/usrcmds.lua` --
und, am ausgereiftesten, `lsp.nvim/lua/lsp/diagnostics/{quickfix,loclist}.lua`.

Der delegierbare Teil ist also: die Listen-Senke aus `lsp.nvim` nach
`lib.nvim.ui` heben (Kandidat `lib.nvim.ui.qf`), damit es eine gemeinsame
Implementierung gibt statt 14 Eigenbauten -- und die vorhandenen Aufrufer
darauf umstellen. Das ist unabhängig von diesem Diagnostics-Befund und noch
offen.

---

