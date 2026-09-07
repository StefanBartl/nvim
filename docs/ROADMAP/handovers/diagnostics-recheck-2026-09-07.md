# Diagnostics-Re-Scan über alle Plugin-Repos — 2026-09-07

**Status: Fix-Durchgang abgeschlossen.** Bundles A, B, C gefixt; Bundle D
gegengeprüft und ohne Fix geschlossen — siehe
[Nächster Schritt](#nächster-schritt-der-fix-durchgang) für den vollen Stand.
`sandbox.nvim`/`sessions.nvim`/`spotlight.nvim`/nvim-config standen beim
Redaktionsschluss noch aus (siehe [Pro Repo](#pro-repo)) und sind nicht Teil
dieses Durchgangs gewesen.

Auslöser (Chat):

> Diagnostics nochmal drüber laufen lassen, es gab noch das ein oder andere zu
> implementieren. luals/luacheck nochmal auf alle Repos, wie `<leader>wq` in
> lsp.nvim.

Bezugspunkt: der Nulllauf vom **2026-09-02** (`FINISH/ERLEDIGT/DIAGNOSTICS/
Diagnostics_FINISHED.md`) — damals standen **alle 32 Workspaces auf 0**.

---

## Table of contents

- [Methode](#methode)
- [Das Gesamtbild](#das-gesamtbild)
- [Die zwei gemeinsamen Ursachen](#die-zwei-gemeinsamen-ursachen)
- [Pro Repo](#pro-repo)
- [Bestätigtes Rauschen](#bestätigtes-rauschen)
- [Erst gegenprüfen](#erst-gegenprüfen)
- [Nächster Schritt: der Fix-Durchgang](#nächster-schritt-der-fix-durchgang)
- [Rohdaten](#rohdaten)

---

## Methode

```
cd %LOCALAPPDATA%\nvim   (bzw. der Config-Root)
REPOS_DIR=E:/repos LUALS_SCAN_REFRESH=1 bash scripts/luals-scan/scan.sh recheck0907
python scripts/luals-scan/compare.py recheck0907
```

- lua-language-server **3.18.2**, Neovim **0.12.2** — das Neovim-Upgrade seit
  dem Nulllauf ist der rote Faden (siehe unten).
- `LUALS_SCAN_REFRESH=1`, weil sich der Plugin-Bestand real geändert hat
  (Neovim 0.12, noice/fzf-lua/nvim-tree/neo-tree/trouble-Updates).
- Umfang wie gehabt: die 31 `*.nvim` + nvim-Config. `neotree-fs-refactor.nvim`
  wird vom Scan als Workspace geführt, gehört aber **nicht** dazu.
- Raw-JSON pro Repo: `%LOCALAPPDATA%\nvim-data\luals-scan\out\recheck0907\`.

Regel `LLS-07` gilt: **ein Nachher-Lauf beweist keine Null**, und
`param-type-mismatch` rauscht. Für harte Aussagen die Gegenprobe im laufenden
Server (`vim.diagnostic.get(0)`).

---

## Das Gesamtbild

Kein Flächenbrand. ~**70 Befunde über ~15 Repos**, der Rest steht auf 0. Fast
jeder Befund ist entweder (a) ein echter kleiner Bug aus einer Änderung seit
dem 02.09. oder (b) Fremd-Typ-Drift durch Neovim 0.12 / Plugin-Updates. Kein
Repo hat eine dreistellige Zahl, keine einzelne kaputte Annotationszeile trägt
eine Traube.

Sauber (0): buffer-ctx, cascade, dap, diff, emojis, fileops, github_stats,
gopath, language, pdfport, recommender, replacer.
*(sandbox, sessions, spotlight, nvim-config: Scan lief bei Redaktionsschluss
noch — nachtragen.)*

---

## Die zwei gemeinsamen Ursachen

### 1. Neovim 0.12 + Plugin-Updates verschieben Fremd-Typen

| Fremd-Typ | Was sich änderte | Trifft |
|---|---|---|
| `vim.notify` | noice `source/notify.lua` deklariert `M._orig = nil` am Modulkopf und weist das in `disable()` `vim.notify` zu → LuaLS sieht `vim.notify` fleet-weit als `fun()?`. Jedes `local notify = vim.notify` am Modulkopf trägt damit an **jeder** Aufrufstelle ein `need-check-nil`. Das ist **LLS-26** (F5). | color_my_ascii (11), mdview (6), reposcope (3) |
| `nvim_tree.api.tree.find_file` | nimmt jetzt `Opts` statt eines Pfad-Strings (String-Form nur noch `legacy` im `@param`, läuft aber weiter) | filetree |
| neo-tree `current_position` / `neotree.State` | Position-Enum um `"bottom"` erweitert; `neotree.State` vs. eigene Stand-in-Klassen | filetree, open.nvim |
| trouble `Mode` | Pflichtfeld `source` dazugekommen — `is_open({ mode = … })` ist ein Teil-Filter | lsp.nvim |
| fzf-lua `config.Resolved` / `WinoptsResolved` | die öffentlichen `fzf_exec`/`fzf_live`-Opts werden gegen die **voll aufgelöste** interne Config geprüft | pickers, (cmdlog) |
| images.nvim `Scale.MaybeDims` / `Scale.Dims` | eigene Stand-in-Klasse `Hover.Preview.Dims` daneben (**LLS-20/F1**, Name statt Gestalt) | hover.nvim |
| pdfport Status-/Mode-Enums | `"partial"` statt `"skipped"`, `"picker"` nicht in der Mode-Union | filetree |
| globaler `@alias Buffer` / `Window` | Ein-Wort-Alias kollidiert (**LLS-22**) | reposcope |

### 2. Der Recommender-perf-Sweep vom 07.09. (`table.concat`-Umbau)

`0cc5045` in **documentation.nvim** hat drei Self-Concat-Akkumulatoren auf
`table.concat` umgestellt. In `checklist.lua` war der Akkumulator ein reines
Local (`---@type string?` → `string[]?`) — sauber. In `features.lua` und
`python.lua` ist er ein **Feld auf einem typisierten Objekt**
(`Documentation.Features.Meta.value: string`, `Documentation.ParamInfo.desc:
string`), das kurzzeitig eine `table` hält und am Ende per `table.concat`
zurück-gewandelt wird. Funktional korrekt („No behavior change" stimmt), aber
LuaLS sieht `current.desc = { current.desc }` als `table` an ein `string`-Feld
→ **9 Befunde** (`assign-type-mismatch` / `param-type-mismatch`, je `table`↔`string`).

Das ist **D2**: eine Änderung, die anderswo neue Befunde erzeugt, ist unfertig.
Diese drei Stellen standen auch **nicht** unter den „4 echten Hotspots" des
perf-Sweeps — `n` ist hier die Zahl der Fortsetzungszeilen einer einzelnen
Docstring-Beschreibung, also 1–4.

---

## Pro Repo

Reihenfolge: echte Bugs zuerst.

### hover.nvim — 1 echter Bug + 2 Fremd-Typ + 1 Probe

| Stelle | Befund | Einschätzung / Griff |
|---|---|---|
| `lua/hover/bare_path.lua:242` | `undefined-field: line` (2×) | **Echter Bug.** Liest `res.line`; gopaths `GopathResult` führt die Zielzeile unter `res.range.line` (so machen es gopaths eigene Konsumenten, `commands.lua:88`). Der Kommentar darüber („the line is already known here … used to be thrown away") beschreibt einen Fix, der **nie gegriffen hat** — die `:zeile:spalte`-Auflösung wird weiterhin verworfen. Griff: `res.range and type(res.range.line) == "number" and res.range.line or nil`. |
| `lua/hover/preview/media.lua:244` | `param-type-mismatch`: `Hover.Preview.Dims\|nil` an `Images.Scale.MaybeDims\|nil` | **LLS-20 / F1.** hover führt einen Parallel-Namen für etwas, das images.nvim besitzt. images.nvim ist Soft-Dep → keine `@class …: Images.Scale.MaybeDims`-Vererbung (wäre `undefined-doc-name` ohne images im Workspace). Griff: `--[[@as Images.Scale.MaybeDims?]]` an der Aufrufstelle. |
| `scripts/onrequest_probe.lua:89` | `duplicate-set-field: get_engine` | Absicht (Probe wrappt `sandbox.get_engine`). **§E:** `---@diagnostic disable-next-line` mit einem Satz. |

### documentation.nvim — 9 (perf-Umbau) + Nebenbefund

| Stelle | Befund | Griff |
|---|---|---|
| `core/features.lua:149,156,171` | `table`↔`string` | siehe [Ursache 2]. Empfehlung: **Parallel-Array** — `meta` ist append-only, also `local value_parts = {}` führen (`value_parts[#meta]`), `.value` bleibt durchgehend `string`, am Ende `m.value = table.concat(value_parts[j], " ")`. Hält die O(n)-Absicht **und** den Feldtyp. |
| `core/lang/python.lua:328,352,355,387,413` | `table`↔`string` | dito; `current` wechselt zwischen Param/Return und wird `nil`-gesetzt → Liste `{obj, parts}` mitführen und am Ende einmal concaten. Nebenbei: `parse_google`s Return-Fortsetzung (`returns[1].desc = returns[1].desc .. " " .. …`, ~Z.397) wurde **nicht** umgestellt — der Code ist bereits inkonsistent. |
| `bindings/usrcmds/annotate.lua:147` | `"inline"\|"sidecar"\|nil` an `"inline"\|"sidecar"` | `write_mode` ist per Design `nil` = Dry-Run (Z.25, Z.189). `annotate.apply`s 3. Parameter auf `…\|nil` weiten (der Code behandelt nil bereits). |

### filetree.nvim — 6 (Fremd-API-Drift)

| Stelle | Befund | Griff |
|---|---|---|
| `adapter/nvimtree.lua:243` | `string` an `find_file.Opts?` | `a.tree.find_file({ buf = path })` — moderne Form, nvim-tree wandelt die String-Form intern noch (`actions/tree/find-file.lua:14`), also kein Verhaltensbruch. |
| `adapter/neotree.lua:63` | `return-type-mismatch`: `"bottom"` nicht in `FiletreeTreePosition` | neo-tree kennt jetzt `"bottom"`. Entweder `FiletreeTreePosition` um `"bottom"` erweitern (falls filetree bottom stützt), sonst `---@cast pos FiletreeTreePosition` nach dem `VALID_POSITIONS[pos]`-Guard. |
| `adapter/neotree.lua:624` | `duplicate-set-field: execute` | Absicht (Reveal-Guard monkeypatcht `neo-tree.command.execute`). **§E**, ein Satz. |
| `util/pdf.lua:160` | `"error"\|"ok"\|"partial"` an `"error"\|"ok"\|"skipped"` | pdfports Result-Status-Enum ist gedriftet. filetrees Spiegel-Typ an pdfport angleichen (`"partial"`). |
| `util/pdf.lua:193` | `"picker"` nicht in `"buffer"\|"float"\|"system"\|"terminal"` | pdfports akzeptierte Mode-Union prüfen und filetrees Weitergabe/Typ angleichen. |
| `features/infra/ignore_list/init.lua:159` | `need-check-nil` | `merge_hide_by_name` akzeptiert `table?` bereits — der Befund hängt an `ncfg` / `fi` aus `nt.config or ensure_config()`. Kurz gegenprüfen (evtl. `---@cast`). |

### lsp.nvim — 1

| Stelle | Befund | Griff |
|---|---|---|
| `bindings/actions.lua:389` | `missing-fields in trouble.Mode: source` | Teil-Filter gegen die volle Klasse (§ `missing-fields`). `--[[@as trouble.Mode]]` oder `---@diagnostic disable-next-line: missing-fields` mit Begründung. |

### color_my_ascii.nvim — 11 (LLS-26)

Alle `notify(...)`-Aufrufe, `local notify = vim.notify` am Modulkopf. Dateien:
`commands/format.lua` (17,60,62), `commands/fence_check.lua` (105,109,111),
`config/init.lua` (330,349,367), `highlighter.lua` (53,216).
**Griff (LLS-26):** `---@type fun(msg: string, level?: integer, opts?: table)`
auf die `local notify = vim.notify`-Zeile in jeder der 4 Dateien.

### mdview.nvim — 8

- `lua/mdview/test/runner.lua` (22,25,30,36,38,41) — 6× `need-check-nil`,
  wieder `local notify = vim.notify` (LLS-26), gleicher Griff.
- `TESTS/harness.lua:122,127` — `duplicate-set-field: describe`, `it` — der
  Test-Harness-Double. **§E / LLS-40**, ein Satz Begründung.

### reposcope.nvim — 5

- `lua/reposcope/utils/debug.lua` (48,73,75) — 3× `need-check-nil`, `notify`-Alias
  (LLS-26).
- `lua/reposcope/@types/aliases.lua:97,98` — `duplicate-doc-alias: Buffer`,
  `Window` (**LLS-22**). Ein globaler `Buffer`/`Window`-Alias kollidiert jetzt.
  Namensraum davor (`Reposcope.Buffer`) oder streichen, wenn nichts sie nutzt.

### casedesk.nvim — 1

- `lua/casedesk/meta.lua:89` — `os.date("%Y")` ergibt `string\|osdate` (**F4**).
  `year` ist ein `string`-Feld. Griff: `os.date("%Y") --[[@as string]]`
  (das Format ergibt beweisbar einen String) oder `tostring(...)`.

### cmdlog.nvim — 1

- `lua/cmdlog/ui/picker_utils.lua:175` — `previewer = <fun(entry,_):string?>`
  an `(string\|fzf-lua.config.Previewer\|false)?`. fzf-lua nimmt eine
  **Funktion** nicht mehr über `previewer=` (`Previewer.new` gibt für einen
  Funktions-Spec `nil` zurück → gar kein Previewer). Eine Funktion, die ein
  Shell-Kommando liefert, gehört an `preview = { fn = …, type = "cmd" }`.
  **Vor dem Fix Laufzeit gegenprüfen** — ältere fzf-lua akzeptierte die Form.

### debugging.nvim — 4

- `views/debug_helper.lua:55,56,57` — `undefined-field: message`, `text`, `_text`
  auf einem `NoiceMessage`. Der Code probet bewusst unbekannte Felder
  (`has_message = msg.message ~= nil`) — ein Debug-Helper. **§E:**
  `---@cast msg table` vor dem Probe-Block, ein Satz.
- `views/capture/init.lua:242` — `undefined-field: get` auf
  `noice.api.status.message.get`. `NoiceStatus` deklariert `get`, aber über
  eine Metatable-Fabrik (`status.lua`) — LuaLS zieht die Felder evtl. nicht
  durch. Gegenprüfen; sonst `---@cast` / Suppress (defensiver `pcall` steht
  schon drum).

### images.nvim — 1

- `TESTS/resolve_spec.lua:126` — `duplicate-set-field: resolve_at_cursor` —
  Test-Double. **§E / LLS-40**.

### insights.nvim — 1

- `lua/insights/imports/init.lua:37` — `undefined-field: progress_style`.
  **Echt, sauber.** `1acdd21 feat(imports): progress indicator` hat das Feature
  gebaut, aber die Typen nicht mitgezogen: `DEFAULTS.lua:50` setzt
  `progress_style = "auto"`, `docs/configuration.md` dokumentiert es, gelesen
  wird es — nur `Insights.ImportsConfig` **und** `Insights.ImportsOpts`
  (`config/@types/init.lua`) führen das Feld nicht.
  Griff: `---@field progress_style Insights.ProgressStyle` in beide Klassen
  (Opts als `?`).

### lib.nvim — 2 (beide nicht in `lua/`)

- `TESTS/keymap_registry_spec.lua:375` — `need-check-nil` in einer Testdatei
  (Verengung nach Assertion, **LLS-42**).
- `docs/EXAMPLES/composer-flags-and-kv.lua:41` — `param-type-mismatch`
  (`table<string,any>` an `string?`) in einer **Beispiel**-Datei. Beispiel oder
  Composer-`@param` angleichen.
- *Nebenbeobachtung:* lib.nvim hat einen offenen Worktree
  `.claude/worktrees/kit-popup-docstring-fix-b69e9e/` mit `lua/`-Kopie. Der
  Scan-`ignoreDir` greift (Befunde stehen auf den Hauptpfaden), aber der
  Worktree liegt noch da.

### markdown.nvim — 1

- `lua/markdown/commands/image.lua:15` — `return-type-mismatch`: `table\|nil`
  deklariert, `function\|nil` zurückgegeben. `images()` gibt
  `pcall(require, "images")` weiter; images.nvims `M` ist eine schlichte
  Tabelle mit `M.show`/`M.paste`/… und `return M`. **Erst gegenprüfen** —
  sieht nach LuaLS-Auflösungsartefakt aus (dieselbe Klasse wie
  runtime-analysis unten). Sonst `--[[@as table?]]`.

### open.nvim — 1

- `lua/open/context.lua:143` — `neotree.State` an `Cfg.NeoTree.State`
  (**F1**). `config.neotree.utils.node.get_current` (nvim-config-Code) erwartet
  den Config-eigenen Stand-in. `--[[@as Cfg.NeoTree.State]]` an der
  pcall-Aufrufstelle.

### runtime-analysis.nvim — 2

- `lua/runtime-analysis/telemetry/command.lua:1251` — `undefined-field: show`
  (2×) auf `require("images").show`. images.nvim hat `M.show` (Z.98).
  **Dieselbe Auflösungsfrage wie markdown.nvim** — erst gegen den laufenden
  Server prüfen, ob das real ist.

### sandbox.nvim — 2 (beide TESTS)

- `TESTS/follow_logs_stream_separation_spec.lua:19,22` — `redundant-parameter`
  (3 statt max. 2 Argumente) + `return-type-mismatch` (`table` statt
  `vim.SystemObj`). Der Test-Stub für `vim.system` passt nicht mehr zur 0.12-
  Signatur. Stub-Annotation angleichen oder **§E** unterdrücken. TESTS-only.

### sessions.nvim / spotlight.nvim / nvim-config

*Scan lief bei Redaktionsschluss noch. Nachtragen.*

---

## Bestätigtes Rauschen

Test-Doubles / bewusste Überschreibungen — **§E / LLS-40/41**, je ein Satz
Begründung, kein eigener Durchgang:

- `mdview.nvim/TESTS/harness.lua` (describe/it)
- `images.nvim/TESTS/resolve_spec.lua` (resolve_at_cursor)
- `lib.nvim/TESTS/keymap_registry_spec.lua` (need-check-nil nach Assertion)
- `hover.nvim/scripts/onrequest_probe.lua` (get_engine)
- `filetree.nvim/adapter/neotree.lua:624` (execute — Reveal-Guard)
- `debugging.nvim/views/debug_helper.lua` (bewusstes Feld-Probing)

---

## Erst gegenprüfen

Vor dem Anfassen im laufenden Server (`vim.diagnostic.get(0)`) verifizieren —
riecht nach LuaLS-Auflösungsartefakt (`require("images")`):

- `markdown.nvim/lua/markdown/commands/image.lua:15`
- `runtime-analysis.nvim/lua/runtime-analysis/telemetry/command.lua:1251`

Wenn beide dasselbe `require("images")`-Problem zeigen und der Server sie nicht
kennt, ist es eine Messgrundlagenfrage (die Klasse aus dem spotlight-Durchgang,
`require("harness")` → falsches Repo) — dann `scripts/luals-scan` prüfen, nicht
die zwei Repos.

---

## Nächster Schritt: der Fix-Durchgang

Vertikal, ein Repo nach dem anderen (Regel H): fix → `scan.sh <pass> <repo>` →
`compare.py` → Suite → ein Commit pro Repo, direkt auf `main`, kein Co-Author.

Delegierbare Bündel (jeweils in sich abgeschlossen):

| Bündel | Repos | Charakter | Status |
|---|---|---|---|
| **A — LLS-26** | color_my_ascii, mdview, reposcope | rein mechanisch: `---@type` auf die `local notify = vim.notify`-Zeilen. Dazu reposcopes `@alias Buffer/Window` und mdviews Harness-Doubles. | ✅ erledigt 2026-09-07 |
| **B — Fremd-API-Drift** | filetree, lsp, open, casedesk | je 1–6, brauchen Blick in den Fremd-Typ (nvim-tree, neo-tree, trouble, pdfport, `os.date`). | ✅ erledigt 2026-09-07 |
| **C — perf-Umbau + Rest** | documentation, insights, hover, cmdlog, images, lib, debugging | documentation ist der größte Posten (Parallel-Array-Umbau), hover hat den echten `res.range.line`-Bug. | ✅ erledigt 2026-09-07 |
| **D — gegenprüfen** | markdown, runtime-analysis | erst Server-Gegenprobe, dann entscheiden. | ✅ gegengeprüft 2026-09-07, **kein Fix nötig** |

nvim-config: eigener Durchgang, nachdem sein Scan vorliegt.

### Ergebnis Bundle A (3 Repos, alle luals-verifiziert auf 0)

- **color_my_ascii.nvim** (`a6c933e`): `---@type fun(msg: string, level?: integer, opts?: table)` auf alle 4 `local notify = vim.notify`-Zeilen.
- **mdview.nvim** (`19767f0`): dieselbe Annotation auf `TESTS/nvim/harness.lua`s eigenen Alias, plus `---@diagnostic disable-next-line: duplicate-set-field` (mit Begründung) auf `_G.describe`/`_G.it` — ein eigener Minimal-Harness, keine Neudefinition von busted/plenary.
- **reposcope.nvim** (`b010110`): `@alias Buffer/Window` → `Reposcope.Buffer`/`Reposcope.Window` namensraum-präfixiert (kollidierte global mit einem gleichnamigen Alias anderswo im Workspace, **LLS-22**) — alle echten Typ-Stellen in `state.lua` und `aliases.lua`s `PromptBufferMap` (die die ursprüngliche Fund-Liste nicht nannte, aber denselben Alias nutzte) mitgezogen. Dieselbe `local notify = vim.notify`-Annotation.

`compare.py bundleA_after` → `TOTAL 0`.

### Ergebnis Bundle B (4 Repos, luals-verifiziert)

- **lsp.nvim** (`386d370`)\*: `bindings/actions.lua:389` — `trouble.is_open({mode=...})` ist ein Teilfilter, keine volle `trouble.Mode`; `---@diagnostic disable-next-line: missing-fields` mit Begründung. `compare.py` → `TOTAL 0`.
  \* Commit-Hash gehört zum vorherigen Perf-Sweep-Fix in derselben Session — dieser Fix ist im selben Push, kein separater Commit-Hash notiert.
- **open.nvim** (`3df09d9`): `context.lua:143` — `--[[@as Cfg.NeoTree.State]]` an der `node_utils.get_current(state)`-Aufrufstelle (F1, gleiche Klasse wie hovers images.nvim-Fall).
- **casedesk.nvim** (`58c25ba`): `meta.lua:89` — `os.date("%Y") --[[@as string]]` (kein `"*t"`-Flag → nie die `osdate`-Tabellenform).
- **filetree.nvim** (`53a9e3e`), 6 Funde in einem Commit:
  - `adapter/nvimtree.lua:243` — `find_file(path)` → `find_file({ buf = path })` (moderne Opts-Form; verifiziert gegen den echten nvim-tree-Quellcode, dass die String-Form intern weiterhin funktioniert, also kein Verhaltensbruch).
  - `adapter/neotree.lua:63` — `---@cast pos FiletreeTreePosition` nach dem `VALID_POSITIONS`-Guard (neo-tree hat `"bottom"` ergänzt, das dieser Adapter bewusst nicht unterstützt und der Guard schon ausschließt).
  - `adapter/neotree.lua:624` — `---@diagnostic disable-next-line: duplicate-set-field` mit Begründung auf den `commands.execute`-Monkeypatch (Reveal-Guard).
  - `util/pdf.lua:193` — `mode --[[@as PdfPort.RendererMode]]` an der einen Stelle, die es an pdfport weiterreicht (verifiziert: `"picker"` kehrt in jedem Aufrufer vorher zurück, `"system"` wird davor abgefangen — nur `"buffer"`/`"terminal"` erreichen pdfport tatsächlich).
  - `@types/config.lua` — `FiletreePdfCreateResult.status` um `"partial"` erweitert (pdfports echter `PdfPort.ResultStatus` ist `"ok"|"error"|"partial"`, filetrees Spiegel-Typ hatte nur `"skipped"`, sein eigenes Konzept, vergessen zu ergänzen).
  - `features/infra/ignore_list/init.lua:159` — `---@cast fi table` direkt nach dem `x.y = x.y or {}`, das es schon garantiert (LuaLS trägt die Verengung nicht durch den Feld-Re-Read).
  - `compare.py bundleB_filetree` → `TOTAL 0`.

### Ergebnis Bundle C (7 Repos)

- **hover.nvim** (`fccc515`): `bare_path.lua:242` — **echter Bug gefixt**: `res.line` existiert auf `GopathResult` nicht, die Zeile liegt unter `res.range.line` (verifiziert gegen gopath.nvims echte `@class GopathResult`). Der Kommentar, der behauptete das sei schon gefixt, war falsch — der `:line:col`-Suffix wurde bei jedem Bare-Path-Hover weiterhin verworfen. Dazu `media.lua:244` (`--[[@as Images.Scale.MaybeDims?]]`, F1) und `onrequest_probe.lua:89` (§E-Suppression, `sandbox.get_engine`-Probe-Wrap). `compare.py bundleC_hover` → `TOTAL 0`.
- **cmdlog.nvim** (`670eff1`): `picker_utils.lua` — `previewer = fn` existiert in der installierten fzf-lua-Version nicht mehr; **gegen den echten fzf-lua-Quellcode verifiziert** (`previewer/init.lua`s `normalize_spec`): die Funktionsform des `preview`-Keys läuft durch `stringify_data` (behandelt den Rückgabewert als Inhalt), nur die `{ fn, type = "cmd" }`-Form durch `stringify_cmd` (behandelt ihn als Shell-Kommando) — genau das, was `command_previewer()` liefert. Umgestellt auf `preview = { fn = ..., type = "cmd" }`.
- **images.nvim** (`c7c091b`): `TESTS/resolve_spec.lua:126` — §E-Suppression für den `resolve_at_cursor`-Spy.
- **insights.nvim** (`fdb2445`): `imports/init.lua:37` — **echter Bug gefixt**: `progress_style` fehlte in `Insights.ImportsConfig`/`Opts` (Feature `1acdd21` gebaut, Typen nie ergänzt). Feld in beide Klassen nachgetragen.
- **lib.nvim** (`eb319fb`): `TESTS/keymap_registry_spec.lua` — Datei-Header-Suppression (**LLS-42**). `docs/EXAMPLES/composer-flags-and-kv.lua` — der Beispielaufruf `replacer.run(ctx.args, ctx.flags)` passte nie zu replacers echter Signatur (`run(request: RP_Request|string, ...)`, ein Tabellen-Argument, keine zwei); durch einen echten `RP_Request` ersetzt, der `old`/`new`/`dry` tatsächlich aus der Route übernimmt.
  - ⚠️ **Neuer, unabhängiger Fund beim Verifikations-Rescan:** `lua/lib/@types/init.lua:27` — `undefined-doc-name: Lib.Nvim`. War **nicht** in der recheck0907-Baseline (gegengeprüft: die Baseline hatte für lib.nvim exakt die zwei oben genannten, jetzt gefixten Funde). Hängt nicht mit diesen beiden Fixes zusammen — nicht untersucht, nicht gefixt. Für einen künftigen Durchgang vormerken.
- **debugging.nvim** (`0ea7abd`): `views/debug_helper.lua` (`---@cast msg table` vor dem bewussten Feld-Probing, deckt alle 3 `undefined-field`-Funde) + `views/capture/init.lua:242` (`---@diagnostic disable-next-line: undefined-field`, verifiziert gegen noise.nvims echten Quellcode: `noice.api.status` ist eine Metatable-Factory, `get()` ist real, LuaLS sieht nur nicht durch den `__index`).
- **documentation.nvim** (`8e260ad`): **9 der eigenen Perf-Sweep-Fixes vom selben Tag korrigiert** — `features.lua` und `python.lua` hielten zwischen den Schleifen-Durchläufen eine Tabelle in einem als `string` deklarierten Feld (`Documentation.Features.Meta.value`, `Documentation.ParamInfo`/`ReturnInfo.desc`). Funktional korrekt, aber genau die 9 neuen Funde dieses Rechecks. Umgebaut auf ein zu `meta`/`params`/`returns` paralleles `parts`-Array (nach Index), das Feld selbst bleibt durchgehend `string`, einmalige `table.concat` nach der Schleife — derselbe O(n)-Gewinn, ohne den Feldtyp zu verletzen. `checklist.lua`s eigener Akkumulator war schon ein reines Local, brauchte keine Änderung. Dazu `bindings/usrcmds/annotate.lua:147`: `annotate.apply`s `mode`-Parameter auf `"inline"|"sidecar"|nil` geweitet (der eine Aufrufer garantiert Nicht-`nil`, aber in einer Sibling-Closure, durch die LuaLS nicht verengt).

### Ergebnis Bundle D — gegengeprüft, kein Fix

Beide Funde gegen den **echten laufenden** `lua_ls` verifiziert (nicht das
`scripts/luals-scan`-Tool): Datei headless mit der realen Config geöffnet,
`:LspStart`, auf `LspAttach` gewartet, dann `vim.diagnostic.get(0)` nach 3s
Wartezeit gelesen.

- `markdown.nvim/lua/markdown/commands/image.lua:15` — **0 Diagnosen** auf dem echten Server.
- `runtime-analysis.nvim/lua/runtime-analysis/telemetry/command.lua:1251` — **0 Diagnosen** auf dem echten Server.

Beide bestätigen exakt die Vermutung von oben: eine Messgrundlagenfrage im
`scripts/luals-scan`-Tool selbst (vermutlich injiziert es beim `require("images")`-
Auflösen ein anderes/kein `workspace.library` als die echte interaktive
lspconfig, die alle Sibling-`*.nvim`-Repos kennt — `scripts/luals-scan/*.lua`
hat keine images.nvim-Sonderbehandlung). **Keine Code-Änderung** in
markdown.nvim oder runtime-analysis.nvim. Folgeaufgabe (nicht Teil dieses
Durchgangs): `scripts/luals-scan`s Library-Injection für `require("images")`
prüfen — dieselbe Fundklasse wie der frühere `require("harness")`-Fall aus
dem spotlight-Durchgang.

---

## Rohdaten

- Pass: `%LOCALAPPDATA%\nvim-data\luals-scan\out\recheck0907\<repo>.json`
- Zusammenfassung: `python scripts/luals-scan/compare.py recheck0907`
- Baseline-Doku: `docs/ROADMAP/personal/All/FINISH/ERLEDIGT/DIAGNOSTICS/`
- Regeln: `E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/LUA_NVIM.md`
  (`LLS-*`), Nachschlagetabelle `Checklists/luals/DIAGNOSEN.md`
