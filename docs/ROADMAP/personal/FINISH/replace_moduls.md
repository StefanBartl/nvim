# Modules to Replace with `lib.nvim`

## Umsetzungsstand (2026-07-16)

Entscheidung: **harte Abhängigkeit** — direkt `require("lib.nvim...")`, Eigenimplementierung löschen
(kein Soft-Dependency-/pcall-Fallback). Dokumentierte "keine lib.nvim"-Design-Ziele werden bewusst
überschrieben; die betroffene Doku wird im selben Commit mitgezogen.

Commits liegen pro Repo auf Branch `refactor/adopt-lib-nvim` (nicht gepusht, nicht auf `main`).

| Repo | Status | Commit |
| ---- | ------ | ------ |
| `diff.nvim` | ✅ erledigt — notify delegiert; README/ROADMAP/Checklist/Arch&Coding auf neue Abhängigkeit umgeschrieben | `390ae8d` (main) |
| `fileops.nvim` | ✅ erledigt — `util/platform.lua` gelöscht → `cross.fs.mutate`; background-open → `buffer.open_background`; `is_windows` war toter Code | `0f93f85` (main) |
| `learn-cli.nvim` | ✅ erledigt — notify delegiert; `persistence.lua` I/O → `fs.json`/`cross.fs.mutate` (OperationResult-Contract unverändert; `persistence.lua` hat aktuell keine Aufrufer im Repo) | `88742b1` (main) |
| `github_stats.nvim` | ✅ erledigt — `show_float` → `ui.kit.note` (+focus-Fix), `format_number` 5x → `strings.format`, `repo_discovery`-Dedup → `unique_table`, `config.notify` behält Gating, delegiert nur den `vim.notify`-Call (leerer Prefix, da Call-Sites ihn schon inline mitgeben). `commands.lua`-Duplikat bewusst nicht angefasst (toter Code, nirgends required) | `cdc7d60` (main) |
| `gopath.nvim` | ✅ erledigt — `touch`→`create_entry`, `uniq`→`unique_table.unique_by`, `opener`-Fallback→`system_opener`; alle drei im **Soft-Dependency-Muster** des Repos (pcall+Fallback wie `util.cross`/`util.log`, nicht hart), da gopath dieses Muster schon etabliert hatte. Nebenbefund: `system_opener` hatte 0 Aufrufer im ganzen Ökosystem (cfg Pflichtfeld, Windows opt-in) — in lib.nvim gefixt (Commit `2c37431`: cfg optional, Windows jetzt default an) | `0f2ae69` (main) |
| `language.nvim` | ✅ erledigt — `translate/history.lua` JSON-Persistenz → `fs.json` (war als "low-value" markiert, der Vollständigkeit halber trotzdem gemacht) | `59c8f41` (main) |
| `nvim-cmdlog` | ⏭️ übersprungen — Analyse fand keine REPLACE-Kandidaten (bereits durchgängig auf lib.nvim umgestellt) | — |
| `migrate.nvim` | ✅ erledigt — `common/buffer.lua`s `ensure_buffer` → `buffer.open_background` (Arch&Coding.md-Erwähnung von "ohne lib.nvim testbar" betrifft nur `opt.migrator`s Test-Design, keine Repo-weite Design-Entscheidung — kein Konflikt) | `6f655b6` (main) |
| `nvim-containers` | ✅ erledigt — alle 15 docker/podman/wsl-Adapter (roh `vim.fn.system`) → neuer Soft-Wrapper `containers/util/run_argv.lua` (Muster von `containers/notify.lua` gespiegelt, lib.nvim bleibt "optional" laut README). Nebenbefund: `run_argv.run_blocking` verwirft stdout bei Erfolg — in lib.nvim per neuer Funktion `run_blocking_captured` gefixt (Commit `6d65583`). Bonus-Fix: `vim.logd`-Tippfehler in podman start_container.lua | `9fec2bf` (main) |
| `open.nvim` | ✅ **teilweise** — nur `platform.lua`s OS-Erkennung → `cross.platform.*` ersetzt (robuster: uname+env+/proc-Fallback statt nur `/proc/version`). `handlers/{default,browser,filemanager}.lua` **bewusst NICHT** auf `system_opener` umgestellt — die sind funktional überlegen (WSL `wslpath`, Multi-Browser-Kandidaten, Filemanager-Reveal); ein Zwangsersatz wäre eine Funktionsregression, keine Bereinigung. Erst sinnvoll, wenn `system_opener` bewusst auf dieses Niveau gehoben wird | `d4ad422` (main) |
| `pdfport.nvim` | ✅ **teilweise** — `platform.os/is_wsl` → `cross.platform.*`, `util/notify.lua` → `lib.nvim.notify` (mit `debug(msg,cfg)`-Gate als dünnem Wrapper erhalten), `renderers/float.lua` → `window.make_scratch`. **Bewusst NICHT** angefasst: `open_cmd()`+`renderers/system.lua` (eigener `wsl-open`-Fallback + Exit-Code-Warnung, die `system_opener` nicht hat — Zwangsersatz wäre Regression); `backends/*.lua`/`terminal.lua`s `wait_for_file` sind NEW_MODULE-Kandidaten (jetzt in lib.nvim vorhanden: `spawn_capture`/`wait_until`), aber nicht Teil dieses Replace-Durchgangs | `c76a5f4` (main) |
| `pickers.nvim` | ⏭️ übersprungen — keine REPLACE-Kandidaten (bereits durchgängig auf lib.nvim inkl. `ui.kit` aufgebaut, `notify.lua` schon korrektes Soft-Bridge-Muster) | — |
| `project-insight.nvim` | ✅ erledigt — `platform.run_shell`/`copy_to_clipboard` → `cross.run`/`cross.copy_to_clipboard`; `fileinfo.open_hover` → `window.make_scratch` (Toggle-Verhalten, `row=2`-Positionierung, konfigurierbare `close_keys` erhalten) | `de1f821` (main) |
| `recommender.nvim` | ✅ erledigt — `blacklist.is_blacklisted`s Prefix-Vergleich → `strings.starts_with` (low-value, der Vollständigkeit halber). `float/rendering.lua` bewusst nicht angefasst (schwacher Fit, Modul-State eng mit Cursor-Tracking/Highlighting verwoben) | `4c207ad` (main) |
| alle übrigen | ⬜ offen — verbleibend: replacer.nvim, reposcope.nvim, buffer-ctx.nvim, cascade.nvim, color_my_ascii.nvim, debugging.nvim, emojis.nvim, filetree.nvim, markdown.nvim, mdview.nvim | — |

**Wiederkehrendes Muster bei "system_opener"-Kandidaten:** mehrfach festgestellt, dass die jeweilige Eigenimplementierung (open.nvim, pdfport.nvim) **funktional überlegen** ist (WSL-Pfadkonvertierung, Exit-Code-Reporting, Multi-Browser). `lib.nvim.fs.open.url.system_opener` bleibt bewusst schlank; ein Zwangsersatz wäre in beiden Fällen eine Regression gewesen und wurde unterlassen. Für die restlichen Kandidaten (filetree.nvim, gopath.nvim ✅ bereits erledigt, markdown.nvim, reposcope.nvim) diese Möglichkeit vorher genauso prüfen.

**Nebenbefund in lib.nvim:** `cross.platform.is_windows/is_macos/is_linux/is_wsl` hatten einen kaputten "Cache" (`local cached` stand *innerhalb* der zurückgegebenen Funktion, wurde bei jedem Aufruf auf `nil` zurückgesetzt — der Docstring behauptete Caching, das nie stattfand). Gefixt beim Verdrahten von open.nvim, das diese Funktionen bei jedem `:Open` aufruft (Commit `0e4e360`).

**Wichtig für die restlichen Repos:** vor dem Ersetzen prüfen, ob das Zielrepo schon ein **eigenes** Soft-Dependency-Muster für lib.nvim etabliert hat (pcall-Wrapper wie `util/cross.lua`). Falls ja: diesem Muster folgen (Konsistenz im Repo), nicht hart requiren — das war bei gopath.nvim der Fall und widerspricht nicht der "harte Abhängigkeit"-Entscheidung, die sich auf Repos OHNE jede lib.nvim-Anbindung bezog.

Seit 2026-07-16 wird direkt auf `main` gearbeitet (kein Branch pro Repo mehr) — lib.nvims neue Module
sind inzwischen selbst auf `main` gemerged und gepusht (Commit `d864a8c`, inkl. eines zweiten,
parallel laufenden Prozesses, der `buffer.context`/`window.context`/`lib.nvim.cache` beigesteuert hat).

**Voraussetzung:** Die neuen lib.nvim-Module liegen auf Branch `feat/lib-new-modules` (Commit `078af00`),
noch nicht auf `main`. Solange der Branch nicht gemergt ist, laufen die Plugin-Branches nur gegen den
lokalen Checkout `E:\repos\lib.nvim`.

### Fallstricke, die beim Umbau auftraten (für die restlichen Repos relevant)

1. **Test-Runner brauchen lib.nvim auf dem rtp.** Sobald ein Plugin hart requiret, schlägt seine
   Suite fehl. `fileops.nvim/docs/TESTS/run.lua` enthält jetzt eine Auflösungs-Routine
   (`$LIB_NVIM_PATH` → Sibling-Checkout → `stdpath("data")/lazy`) — als Vorlage kopierbar.
2. **Der Bootstrap-Klon unter `stdpath("data")/lazy/lib.nvim` ist veraltet** und kennt neue Module
   nicht. Der Sibling-Checkout muss Vorrang haben, sonst gibt es irreführende Fehler.
3. **rtp allein reicht nicht** für nach dem Start angehängte Einträge — `package.path` muss zusätzlich
   gesetzt werden (so schreibt es lib.nvims README selbst vor).
4. **Vor dem Ersetzen prüfen, ob die Fundstelle überhaupt Aufrufer hat** — `fileops`' `is_windows`
   war toter Code; löschen statt umbiegen.
5. `migrate.nvim` nimmt lib.nvim-abhängige Module bewusst aus dem Test-Scope — dort ggf. Präzedenz folgen.

---

Generated by a parallel multi-agent scan of all personal plugins in `E:\repos` (2026-07-14).
Every entry below is code in another plugin that reimplements something `lib.nvim` **already
provides**. Grouped by the `lib.nvim`/`lib.lua` module that should be used instead, so a whole
category can be swept in one pass.

`filetreepicker.nvim` and `mygrep.nvim` were **not analyzed** — both are commented out in
`lua/plugins/personal/init.lua` and are not checked out under `E:\repos`.

Some plugins (`pickers.nvim`, `language.nvim`, `nvim-cmdlog`, `recommender.nvim`'s `util/lib.lua`,
`gopath.nvim`'s `util/cross.lua`/`util/log.lua`) already soft-depend on `lib.nvim` correctly in most
places — only their remaining gaps are listed.

---

## → `lib.nvim.cross.platform` (`is_windows`/`is_macos`/`is_linux`/`is_wsl`)

- `E:\repos\filetree.nvim\lua\filetree\util\platform.lua:1-52` — `M.is_windows/is_wsl/is_mac/is_linux/get_cwd`. Unlike sibling files in the same `util/` dir, this one has no lib.nvim-optional fallback at all.
- `E:\repos\open.nvim\lua\open_nvim\platform.lua:1-47` — `M.get()`. open.nvim already requires `lib.nvim.notify` directly elsewhere, so there's no standalone-mode reason to keep a separate detector.
- `E:\repos\fileops.nvim\lua\fileops_nvim\util\platform.lua:5-8` — `M.is_windows` (`vim.fn.has("win32") == 1`). lib.nvim's version additionally handles WSL correctly via `uv.os_uname`/env fallback.
- `E:\repos\pdfport.nvim\lua\pdfport_nvim\platform\init.lua:18-27` (`M.os`), `:30-37` (`M.is_wsl`) — via `uv.os_uname()` and `/proc/version` sniffing.
- `E:\repos\markdown.nvim\lua\markdown_nvim\util\platform.lua:15-23` — `M.os`.
- `E:\repos\reposcope.nvim\lua\reposcope\utils\os.lua:20-23` — `M.is_windows`.
- `E:\repos\project-insight.nvim` already uses `lib.nvim.cross.platform.is_windows` correctly — no finding there.

## → `lib.nvim.fs.open.url.system_opener`

Six independent plugins reimplement "open a path/URL with the OS default handler"
(`cmd /c start` / `open` / `xdg-open` / `wslview`):

- `E:\repos\filetree.nvim\lua\filetree\util\pdf.lua:33-50`, `features\system\open_in_fm\init.lua:45-58`, `features\system\open_with\init.lua:44-49` — **three separate copies inside this one plugin**.
- `E:\repos\open.nvim\lua\open_nvim\handlers\default.lua:38-77` (`run`), `handlers\browser.lua:36-47` (`default_browser_cmd`), `handlers\filemanager.lua:46-93` — this plugin's entire core mechanism, duplicated three times over rather than centralized. Would need `system_opener` extended with WSL/`wslpath` + "reveal in file manager" to fully absorb these.
  - Also: `E:\repos\open.nvim\lua\open_nvim\context.lua:35-39` and `handlers\default.lua:23-27` — `looks_like_url`, duplicated verbatim in two files, overlaps `system_opener.is_ike`.
- `E:\repos\pdfport.nvim\lua\pdfport_nvim\platform\init.lua:87-93` (`M.open_cmd`) + consumer `renderers\system.lua:17-33`.
- `E:\repos\gopath.nvim\lua\gopath\external\helpers\opener.lua:32-110` — `detect_os`/`build_opener_command`/`fallback_open_with_system`; `is_url` at line 57 duplicates `system_opener.is_ike`.
- `E:\repos\markdown.nvim\lua\markdown_nvim\util\platform.lua:29-69` — `M.open` (jobstart/argv dispatch).
- `E:\repos\reposcope.nvim\lua\reposcope\utils\os.lua:28-45` — `M.open_url`.

## → `lib.nvim.cross.copy_to_clipboard`

- `E:\repos\buffer-ctx.nvim\lua\buffer_ctx\util\clip.lua:7-16` — `M.copy`, hand-rolled register-set + preview/notify.
- `E:\repos\markdown.nvim\lua\markdown_nvim\util\clipboard.lua:1-10` — `M.copy`, bare `vim.fn.setreg` (no macOS/Linux/Windows/WSL fallbacks that lib.nvim already has).
- `E:\repos\project-insight.nvim\lua\project_insight\util\platform.lua:27-31` — `M.copy_to_clipboard`.
- `E:\repos\debugging.nvim\lua\debugging\views\capture\clipboard\init.lua:14-79` — pbcopy/clip.exe/wl-copy/xclip/xsel dance built on top of `lib.nvim.cross` platform booleans instead of calling `copy_to_clipboard` directly. Note: this version's Wayland/X11 + xsel fallback is arguably *better* than lib.nvim's current implementation — worth upstreaming the improvement into `lib.nvim.cross.copy_to_clipboard` first, then replacing this call site.

## → `lib.nvim.notify` (`.create(prefix)`)

- `E:\repos\diff.nvim\lua\diff_nvim\util\notify.lua:9-27` — `M.info`/`warn`/`error`, plain `"[diff] " .. vim.notify(...)` with no lib.nvim bridge at all.
- `E:\repos\learn-cli.nvim\lua\learn_cli\utils\notify.lua:1-23` — `M.info/success/warn/error`, static-title `vim.notify` wrapper.
- `E:\repos\pdfport.nvim\lua\pdfport_nvim\util\notify.lua:8-21` — `M.create`. Compare to `nvim-containers`' `notify.lua`, which already does the same thing correctly with a pcall'd fallback — pdfport should adopt that bridge pattern.
- `E:\repos\github_stats.nvim\lua\github_stats\config\init.lua:259-286` — `M.notify`; keep only the plugin-specific `notification_level` (silent/errors/all) gating layered on top of `lib.nvim.notify.create("[github-stats]")`.
- `E:\repos\replacer.nvim` — **systemic**: every module calls raw `vim.notify("[replacer] ...", level)` directly instead of a `lib.nvim.notify.create("[replacer]")` factory — e.g. `lua\replacer\apply.lua:152,177,183`, `init.lua:93,101,138,151,200,204,212`, plus `command.lua`, `debug.lua`, `surround.lua`, `pickers\common.lua`, `rg.lua`.
- Good reference patterns already in the codebase (no change needed): `emojis.nvim/lua/emojis/util/notify.lua`, `fileops.nvim`'s `util/notify.lua`, `gopath.nvim`'s `util/log.lua`, `recommender.nvim`'s `util/notify.lua`, `project-insight.nvim`'s `util/notify.lua`, `pickers.nvim` — all correctly soft-bridge to `lib.nvim.notify` with a pcall'd fallback.

## → `lib.nvim.cross.run` / `run_argv` (process spawning)

- `E:\repos\emojis.nvim\lua\emojis\search.lua:210-255` — `M.run`, reimplements the `vim.system`-with-`jobstart`-fallback dance (needs slight adaptation for line-buffered streaming output).
- `E:\repos\nvim-containers` — **systemic, 19+ files** use raw `vim.fn.system({...})` + `vim.v.shell_error`: all of `lua\containers\adapters\docker\containers\{list_containers,start,stop,kill,remove,prune,inspect_container,get_logs}.lua`, `adapters\docker\images\{list_images,pull_image,remove_image,prune_images}.lua`, the parallel `adapters\podman\...` tree, and `adapters\wsl\{list_distros,start_distro,stop_distro}.lua`.
- `E:\repos\project-insight.nvim\lua\project_insight\util\platform.lua:14-24` — `M.run_shell`, `vim.system`-based with Windows/POSIX branching.
- `E:\repos\reposcope.nvim\lua\reposcope\utils\protection.lua:230-236` — `M.safe_execute_shell` (`vim.fn.system` + `vim.v.shell_error`).

## → `lib.nvim.window.make_scratch`

- `E:\repos\github_stats.nvim\lua\github_stats\bindings\usrcmds\utils.lua:23-91` — `show_float`; use `lib.nvim.ui.kit.note.open` instead (title + message float, auto-sized, `nice_quit` wired).
- `E:\repos\pdfport.nvim\lua\pdfport_nvim\renderers\float.lua:11-53` — manual centered scratch buffer with q/Esc-to-close keymaps — exactly what `make_scratch{ nice_quit=true, ... }` already provides.
- `E:\repos\project-insight.nvim\lua\project_insight\fileinfo\init.lua:47-86` — `open_hover`, near feature-for-feature duplicate.
- `E:\repos\recommender.nvim\lua\recommender_nvim\float\rendering.lua:108-126` — buffer/window setup boilerplate (nofile/wipe, centering math, rounded border) overlaps `make_scratch`; this view also needs custom cursor-tracking/highlighting layered on top, so only the setup portion should delegate.

## → `lib.nvim.fs.write.to_file` / `create_entry`

- `E:\repos\color_my_ascii.nvim\lua\color_my_ascii\commands\fence\export.lua:70-101` — `write_and_finish`, hand-rolled `mkdir -p` + `writefile`.
- `E:\repos\learn-cli.nvim\lua\learn_cli\data\persistence.lua:1-329` — `M.save`/`load`/`export`/`import`, hand-rolled JSON-file read/write via `io.open`/`vim.json.encode`/`decode` — duplicates both `fs.write.to_file` **and** `lib.lua.json`.
- `E:\repos\migrate.nvim\lua\migrate\common\buffer.lua:101-113` — `M.ensure_buffer` (`bufnr`/`bufadd`/`bufload`) — see `lib.nvim.buffer.open_background` entry below instead; listed here too since it overlaps directory/file creation semantics in adjacent code.
- `E:\repos\fileops.nvim\lua\fileops_nvim\ops\file.lua:42-51` — `M.ensure_parent`, mkdir-p-if-missing (minor, lower priority).
- `E:\repos\replacer.nvim\lua\replacer\export.lua:187-196` — `M.write_export` (`io.open`/`write`/`close`), identical contract to `fs.write.to_file` including parent-dir creation.
- `E:\repos\gopath.nvim\lua\gopath\create.lua:32-47` — `touch` (mkdir -p parents + create empty file) — largely duplicates `lib.nvim.fs.create_entry`.

## → `lib.nvim.buffer.open_background`

- `E:\repos\fileops.nvim\lua\fileops_nvim\ops\cycle.lua:172-177` — `open_path`, `"background"` branch (`fn.bufadd`+`fn.bufload`+`buflisted=true`) — exact reimplementation.
- `E:\repos\migrate.nvim\lua\migrate\common\buffer.lua:101-113` — `M.ensure_buffer`, same `bufadd`/`bufload` sequence, worse error handling.

## → `lib.nvim.lua_ls.get_module_path`

- `E:\repos\buffer-ctx.nvim\lua\buffer_ctx\util\path.lua:9-16` — `M.get_module_path`, byte-for-byte identical algorithm (find `/lua/`, strip `.lua`/`/init`, dot-join).
- `E:\repos\debugging.nvim\lua\debugging\actions\module_reload.lua:14-39` — the fallback branch (lines 26-36) re-derives the same algorithm; the primary runtime-path-walk (17-24) adds real value and can stay.
- `E:\repos\filetree.nvim\lua\filetree\features\paths\lua_require_copy\init.lua:18-48` — `find_lua_root`+`path_to_module`, identical `/lua/`-split logic; keep only the directory-gather (`gather_lua_files`) as plugin-local.

## → `lib.nvim.fs.relpath` / `find_root`

- `E:\repos\filetree.nvim\lua\filetree\util\path.lua:106-118` — `M.relative`, nearly identical normalize-then-strip-prefix logic; should delegate with local fallback (matches the pattern already used elsewhere in the same file).
- `E:\repos\filetree.nvim\lua\filetree\features\infra\project_root\init.lua:1-157` — whole module reimplements `find_root`'s marker-based upward walk + LRU cache. `filetree.util.path_copy` already consumes `lib.nvim.fs.find_root` directly elsewhere in the same codebase, so this is the odd one out. Keep any glob-marker support (e.g. `*.rockspec`) as a local layer if `find_upward_dir` doesn't support globs.
- `E:\repos\markdown.nvim\lua\markdown_nvim\util\path.lua:239-255` — `M.relative_to`; this version additionally emits `..` climbing for non-descendant paths, a real gap in lib.nvim's current version — upstream that improvement into `lib.nvim.fs.relpath` rather than a pure swap.

## → `lib.lua.tables` (`unique_table` / `core.dedup_list`)

- `E:\repos\github_stats.nvim\lua\github_stats\repo_discovery.lua:28-40` — hand-rolled `seen`-table dedup loop → `lib.lua.tables.unique_table.unique_by`.
- `E:\repos\gopath.nvim\lua\gopath\resolvers\common\extractor\helpers.lua:10-19` — `M.uniq` (dedupe by `.raw` key) → `unique_table.unique_by(list, function(c) return c.raw end)`.
- `E:\repos\reposcope.nvim\lua\reposcope\utils\core.lua:71-83` — `M.dedupe_list`, exact duplicate of `lib.lua.tables.core.dedup_list`.

## → `lib.lua.strings` (`trim`/`pad_*`/`starts_with`/`strip_ansi`)

- `E:\repos\markdown.nvim\lua\markdown_nvim\core\table_fmt.lua:30-58` — local `trim`/`pad_cell`, duplicates `trim`/`pad_start`/`pad_end`/`pad_center`; only the `strdisplaywidth`-aware width calc is genuinely extra.
- `E:\repos\markdown.nvim\lua\markdown_nvim\core\link_scan.lua:16-18` — local `trim` one-liner (minor).
- `E:\repos\mdview.nvim\lua\mdview\adapter\log.lua:174` — ANSI-stripping gsub chain, duplicates `lib.lua.strings.strip_ansi` exactly.
- `E:\repos\recommender.nvim\lua\recommender_nvim\blacklist.lua:13-23` — `M.is_blacklisted`'s inner prefix-match loop (`chain:sub(1,#prefix)==prefix`) → `lib.lua.strings.starts_with` (weak, low value — surrounding prefix-list logic is bespoke).

## → `lib.lua.tables` (`clone`)

- `E:\repos\mdview.nvim\lua\mdview\helper\copy_lines.lua:6-10` — manual array-copy loop → `lib.lua.tables.array.clone`.
- `E:\repos\mdview.nvim\lua\mdview\core\state.lua:41-50` — local `shallow_copy` → `lib.lua.tables.dict.clone`.

## → `lib.nvim.fs.ignore.list`

- `E:\repos\markdown.nvim\lua\markdown_nvim\util\ignore.lua:1-24` — `M.as_set`/`DEFAULT_IGNORE`; lib.nvim's version is more complete (`.claude`, `.direnv`, `zig-cache`, lockfile patterns) and offers `as_telescope_patterns`/`as_luals_patterns`/`as_neotree_names` conversions this plugin lacks.

## → `lib.nvim.ui.kit` (`confirm`)

- `E:\repos\replacer.nvim\lua\replacer\pickers\telescope.lua:157` — `vim.fn.confirm(msg, "&Yes\n&No", 2)` → `lib.nvim.ui.kit.confirm`.

## → `lib.nvim.logger` (whole subsystem)

- `E:\repos\mdview.nvim\lua\mdview\adapter\log.lua:1-259` — **strong**: this entire module hand-rolls a ring-buffer logger with file persistence and buffer display, duplicating what `mdview\log.lua` (already correctly built on `lib.nvim.logger`) provides in the very same plugin. Also duplicates `lib.nvim.fs.create_entry`/`is_dir` at lines 69-148 (`path_dirname`/`ensure_dir`, hand-rolled recursive mkdir). Should be merged into/replaced by the `mdview\log.lua` logger instance.

## Weaker / optional

- `E:\repos\pdfport.nvim\lua\pdfport_nvim\platform\init.lua:41-54` and `E:\repos\reposcope.nvim\lua\reposcope\utils\checks.lua:15-19` — both are thin `vim.fn.executable` wrappers; fold into whatever new executable-detection module gets added (see `lib_NEW_MODULES.md`) rather than replacing standalone.
- `E:\repos\buffer-ctx.nvim\lua\buffer_ctx\format\misc.lua:28-54` — `sort_lines`/`unique_lines`; `lib.lua.tables.array` already has `sorted(xs, cmp)`/`unique(xs)` for the non-case-insensitive path — delegate and only add the case-folding key wrapper on top.
