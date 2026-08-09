# Ideas for other plugins (cross-report synthesis)

Collected "Ideen für andere Plugins" from every per-plugin report, grouped by
theme and lightly deduplicated. Each idea links back to the report(s) it came
from.

## Candidate `lib.nvim` building blocks

Recurring pattern: a plugin builds something generically useful and the report
suggests hoisting it into `lib.nvim` so future plugins don't reinvent it.

- **Soft-dependency-bridge helper** (`pcall(require, modname)` → shape-check →
  adapter → fallback), e.g. `lib.nvim.softdep.resolve(modname, shape_check,
  adapter)` — from [diff.nvim](../plugins/diff.nvim.md) (`pickers_bridge.lua`,
  `image_compare.lua`).
- **Byte-level word-diff utility** (`vim.diff` on exploded strings) as
  `lib.nvim.diff.word_ranges(a, b, algorithm)` — from [diff.nvim](../plugins/diff.nvim.md).
- **URL-as-content-source fetch helper** (curl via `vim.system` + libuv timer
  fallback) as `lib.nvim.net.fetch_text(url, opts, callback)` — from
  [diff.nvim](../plugins/diff.nvim.md); overlaps with the "safe external
  download" idea below.
- **N-way native diffmode orchestrator** (`lib.nvim.diffmode.open_n_way({bufs},
  view)`) generalizing `diff.nvim`'s `three_way()`/`side_by_side()` layout code
  — from [diff.nvim](../plugins/diff.nvim.md).
- **Statusline-component convention** (`plugin.status()` → short string, empty
  when inactive) generalized across all *.nvim plugins with "active state" —
  from [diff.nvim](../plugins/diff.nvim.md).
- **Static-vs-runtime audit framework** generalizing `debugging.nvim`'s
  tree-sitter-scan-of-registration-call-sites + live-API-diff pattern (used
  there for autocmds) to other registration-style APIs (`nvim_create_user_command`,
  `vim.keymap.set`, `vim.diagnostic` handlers) — from
  [debugging.nvim](../plugins/debugging.nvim.md).
- **Reusable "Tagged-Scratch-Window" module** generalizing `debugging.nvim`'s
  window-var-based (not registry-based) window tracking, focus-and-scroll with
  bounded retries, defensive handle validation — for any auto-refreshing log
  window (LSP log viewer, test-runner output) — from
  [debugging.nvim](../plugins/debugging.nvim.md).
- **Configurable command-registry composer** as a documented lib.nvim pattern
  — the split between a logic/dispatch module and a thin composer-route
  registration module — from [debugging.nvim](../plugins/debugging.nvim.md).
- **Generic `Registry` building block** ("who is responsible for X",
  self-registration, deterministic order, `reset()` for tests) extracted from
  `documentation.nvim`'s `lang_registry.lua` — from
  [documentation.nvim](../plugins/documentation.nvim.md).
- **Generic keymap-override-resolver** (`defaults + overrides + notify` →
  validated resolved list) generalizing `documentation.nvim`'s
  `bindings/keymaps.resolve()` — from [documentation.nvim](../plugins/documentation.nvim.md).
- **Local loopback server with `VimLeavePre` lifecycle + shape-validated
  routes** as a reusable building block, generalizing `documentation.nvim`'s
  `editor/serve.lua` (127.0.0.1-only, port 0, strict validators) — from
  [documentation.nvim](../plugins/documentation.nvim.md).
- **Undo/history stack with sentinel-clear pattern** as a `lib.nvim.ui.kit`
  utility, generalizing `documentation.nvim`'s `browse/init.lua` `go`/`CLEAR`/
  `history_step` navigation model — from [documentation.nvim](../plugins/documentation.nvim.md).
- **Common-prefix-collapse module** (longest common prefix over a list of
  strings → single alias suggestion), generalizing `recommender.nvim`'s
  Tree-sitter analyzer, usable e.g. for JS/TS import consolidation — from
  [recommender.nvim](../plugins/recommender.nvim.md).
- **"Insert into best target window" helper** (source_win → alternate →
  first normal window), generalizing `recommender.nvim`'s
  `find_target_window()` — likely useful for pickers.nvim/reposcope.nvim too
  — from [recommender.nvim](../plugins/recommender.nvim.md).
- **Frecency-as-a-service module** (log-damped count + bucketed recency, JSON
  persistence under `stdpath("data")/<plugin>/frecency.json`) — three
  independent implementations already exist
  ([emojis.nvim](../plugins/emojis.nvim.md) exponential-decay variant,
  [pickers.nvim](../plugins/pickers.nvim.md) log-damped variant) and both
  reports explicitly suggest consolidating into `lib.nvim`.
- **Route-Tree command composer** as a documented, promoted lib.nvim pattern
  (one data structure driving dispatch + completion + docs) — flagged
  independently by [pickers.nvim](../plugins/pickers.nvim.md),
  [filetree.nvim](../plugins/filetree.nvim.md), and
  [mdview.nvim](../plugins/mdview.nvim.md) as something that should be
  consistently used/promoted across all plugins, not just documented once.
- **Buffer-local-autocmd-with-full-options fix**: a real, repeatedly-hit
  `lib.nvim.autocmd.create` gap (it doesn't pass through a `buffer` field) —
  independently documented as a workaround in at least four plugins:
  [pickers.nvim](../plugins/pickers.nvim.md) (`selected_index/init.lua:184-193`),
  [github_stats.nvim](../plugins/github_stats.nvim.md),
  [color_my_ascii.nvim](../plugins/color_my_ascii.nvim.md),
  [markdown.nvim](../plugins/markdown.nvim.md) — strong candidate for a
  one-time upstream fix rather than four workarounds.
- **Windows file-lock diagnosis command** (`:LibWhoLocks <path>`) directly
  exposing `lib.nvim.cross.fs.lock.report` — from [lib.nvim](../plugins/lib.nvim.md).
- **UI-Kit example/playground plugin** demoing every `lib.nvim.ui.kit`
  primitive interactively — from [lib.nvim](../plugins/lib.nvim.md).
- **Generic count-chained-async-action helper** (`lib.nvim.chained_action`)
  capturing `dap.nvim`'s `counted_step()` event-chaining pattern (protocol-safe
  count repetition with cap + cleanup listeners) — from
  [dap.nvim](../plugins/dap.nvim.md); suggested reuse:
  [github_stats.nvim](../plugins/github_stats.nvim.md)'s N-fetch background
  fetching.
- **Generic backend-provider-dispatch module** formalizing preference →
  install-check → fallback-with-warning → dispatch-by-name, from
  `dap.nvim`'s `ui/provider.lua` — from [dap.nvim](../plugins/dap.nvim.md).
- **`with_cache` editor-state memoization helper**, generalizing
  `open.nvim`'s per-invocation cursor/selection/cfile cache — from
  [open.nvim](../plugins/open.nvim.md).
- **Disambiguating-positional-argument helper** for
  `lib.nvim.usercmd.composer` (match a free-text arg against known enum
  values, warn on uncertainty instead of guessing) — from
  [open.nvim](../plugins/open.nvim.md), noting
  [replacer.nvim](../plugins/replacer.nvim.md) has a similar ad hoc pattern.
- **Adaptive Background Poller module** encapsulating poll-vs-due-interval
  decoupling, startup defer, interval cap, idempotent start/stop — from
  [github_stats.nvim](../plugins/github_stats.nvim.md).
- **Paginated-external-API-with-best-effort-partial-results helper** — from
  [github_stats.nvim](../plugins/github_stats.nvim.md).
- **TUI Dashboard Kit** (cursor-blocking, virtual selection state, auto-scroll,
  count-capable `gg`/`G`/`<C-d>`/`<C-u>`/`<C-f>`/`<C-b>` replication) — from
  [github_stats.nvim](../plugins/github_stats.nvim.md), suggested as
  potentially useful for gopath.nvim's own dashboard-like UI.
- **Fail-open tree-sitter-region-filter module** generalizing
  `language.nvim`'s `regions.lua` (capture-name → byte-ranges → fail-open on
  missing query) for `@spell`, `@nospell`, `@comment`, `@string`, etc. — from
  [language.nvim](../plugins/language.nvim.md).
- **Thesaurus-picker with count-driven direct selection** (`3<leader>th` = 3rd
  synonym, no menu), generalizable to any "replace word under cursor with
  alternative N" feature (spellcheck, thesaurus, translation) — from
  [language.nvim](../plugins/language.nvim.md).
- **`lib.nvim.lua.scoring` module** (additive score + named bonus/malus list +
  clamp, with a `details` breakdown) generalizing `learn-cli.nvim`'s
  `scoring.lua` for any gamification feature — from
  [learn-cli.nvim](../plugins/learn-cli.nvim.md).
- **Spaced-repetition-queue module**, decoupled from CLI-exercise specifics,
  reusable e.g. for `language.nvim`'s translation-history vocabulary review —
  from [learn-cli.nvim](../plugins/learn-cli.nvim.md).
- **Window-local match-ledger module** (`window -> {id -> match id}`
  bookkeeping) generalizing `spotlight.nvim`'s `matchadd()`/`matchdelete()`
  session-persistence trick — from [spotlight.nvim](../plugins/spotlight.nvim.md).
- **Literal-pattern-builder utility** (`\V` + escaping + `\C`/`\c` + optional
  word-boundaries by token kind) for any plugin matching user text safely
  against Vim regex (search/replace tools, bookmark highlighters) — from
  [spotlight.nvim](../plugins/spotlight.nvim.md).
- **Origin-based exception model** (persistence override keyed by "where
  created" rather than "where occurs") as a general pattern for other
  file-scoped state/opt-out plugins (bookmarks.nvim, todo-highlighter) — from
  [spotlight.nvim](../plugins/spotlight.nvim.md).
- **Checkpoint/Snapshot + manifest + byte-exact restore utility**
  generalizing `replacer.nvim`'s `checkpoint.lua`, for any destructive
  multi-file tool ([fileops.nvim](../plugins/fileops.nvim.md),
  [migrate.nvim](../plugins/migrate.nvim.md) cwd-scope operations) — from
  [replacer.nvim](../plugins/replacer.nvim.md).
- **Case-detection/-preservation module** extracted from `replacer.nvim`'s
  `casing.lua`, useful for [migrate.nvim](../plugins/migrate.nvim.md) and
  [fileops.nvim](../plugins/fileops.nvim.md)'s rename-assist — from
  [replacer.nvim](../plugins/replacer.nvim.md).
- **Generic hooks pattern** (`before_apply`/`after_apply`/`before_write`/
  `after_write` with veto + error isolation) as a `lib.nvim` building block
  for any plugin with an apply pipeline ([migrate.nvim](../plugins/migrate.nvim.md),
  [pdfport.nvim](../plugins/pdfport.nvim.md) extraction) — from
  [replacer.nvim](../plugins/replacer.nvim.md).
- **"Bottom-up edit + stale-match verification" as `lib.nvim.buffer.apply_edits`**
  — generic support for any plugin applying multiple positional text edits
  safely — from [replacer.nvim](../plugins/replacer.nvim.md).
- **Bounded-Concurrency Filesystem Scanner module** encapsulating
  `gopath.nvim`'s work-queue scan pattern — reusable for any plugin
  async-indexing large trees, explicitly noting
  [images.nvim](../plugins/images.nvim.md)'s scan/orphans code as a possible
  consumer — from [gopath.nvim](../plugins/gopath.nvim.md).
- **Cache-only vs. live-fallback resolve interface convention**
  (`resolve_cached`/`resolve_async`/`resolve_sync` trio + confidence-score
  convention) as a naming/shape convention for all resolver-like lib.nvim
  modules — from [gopath.nvim](../plugins/gopath.nvim.md).
- **"Create-on-missing" dialog module** (create file + parent dirs + "open in
  filetree" alternative) for any file-opening plugin, including
  [images.nvim](../plugins/images.nvim.md) when inserting paths — from
  [gopath.nvim](../plugins/gopath.nvim.md).
- **Tag-based keymap registry** (`_registry` + tag-guard) as
  `lib.nvim.keymap.scope`, for any plugin with repeatedly recreated UI buffers
  (custom pickers, floating UIs) — from [reposcope.nvim](../plugins/reposcope.nvim.md).
- **API-response-sanitizer pattern** (required fields → placeholder + warning
  instead of crash) as a lib.nvim building block for any plugin consuming
  external JSON APIs, noting [pdfport.nvim](../plugins/pdfport.nvim.md)'s
  backends as a possible consumer — from [reposcope.nvim](../plugins/reposcope.nvim.md).
- **Custom single-line prompt-buffer widget** (cursor-lock via autocommands)
  as a reusable `lib.nvim.ui` component instead of every plugin reinventing
  cursor-locking — from [reposcope.nvim](../plugins/reposcope.nvim.md).
- **Terminal-capability-detection module** (env-var heuristic + session cache
  + once-per-session warning) for any plugin sending terminal-dependent escape
  sequences — from [images.nvim](../plugins/images.nvim.md).
- **Cell-selection-on-scratch-buffer → pixel-conversion helper** for any
  plugin overlaying a visual selection on non-interactive terminal output
  (other OSC-1337-based overlays) — from [images.nvim](../plugins/images.nvim.md).
- **Safe-external-download module** (timeout + byte-limit + URL-hash cache)
  generalizing `images.nvim`'s `remote.lua:M.fetch`, explicitly noting
  [github_stats.nvim](../plugins/github_stats.nvim.md)'s `api.lua` currently
  lacks a byte limit and could benefit — from [images.nvim](../plugins/images.nvim.md).
- **Range-parser utility** (`"1-3,5,7"` → sorted deduped list) generalizing
  `pdfport.nvim`'s `page_range.lua`, reusable for page/line/commit ranges
  elsewhere — from [pdfport.nvim](../plugins/pdfport.nvim.md).
- **Progress-wrapping-callback helper** for `lib.nvim.progress`, generalizing
  `pdfport.nvim`'s one-finalization-point closure pattern — from
  [pdfport.nvim](../plugins/pdfport.nvim.md).
- **`lib.nvim.cache.disk` mtime-based cross-session cache recipe**,
  generalizing `pdfport.nvim`'s `util/cache.lua`, for other expensive
  extraction plugins (video transcription, OCR) — from
  [pdfport.nvim](../plugins/pdfport.nvim.md).
- **Portable-Path module** (placeholder substitution on write, resolve on
  read via a temp copy, never mutate the original) generalizing
  `sessions.nvim`'s `portable.lua`, reusable for any plugin syncing artifacts
  cross-machine (notes, bookmarks, project configs) — from
  [sessions.nvim](../plugins/sessions.nvim.md).
- **Git-skip-worktree-toggle helper** generalizing `sessions.nvim`'s
  `toggle_track`, for other "config repo syncs personal/transient files"
  scenarios — from [sessions.nvim](../plugins/sessions.nvim.md).
- **Fallback-chain validator** (preferred lib → `vim.system` →
  `vim.fn.system`, plus "looks like error text" validation) as a generic
  utility instead of each plugin reimplementing it — from
  [sessions.nvim](../plugins/sessions.nvim.md).
- **Secret-redaction module** matching header names against a known-sensitive
  list and masking values in any history/log automatically — generalizes
  `runtime-analysis.nvim`'s current "don't store at all" approach — from
  [runtime-analysis.nvim](../plugins/runtime-analysis.nvim.md).
- **Fast-event-context linter** detecting `nvim_*` API calls from a
  non-scheduled callback and failing early with a clear message instead of
  `E5560` — from [runtime-analysis.nvim](../plugins/runtime-analysis.nvim.md).
- **Token-based supersession library** (`lib.nvim.async.latest_wins(token)`)
  generalizing the pending-token "newest request wins" pattern — likely
  recurs in picker previews, LSP requests, search — from
  [runtime-analysis.nvim](../plugins/runtime-analysis.nvim.md).
- **Download + checksum-verify + extract bootstrap module** (Mason-like) for
  future LSP/formatter wrapper plugins — from [mdview.nvim](../plugins/mdview.nvim.md).
- **Detached-spawn watcher** diagnostic tool to list/kill orphaned detached
  processes left by previous Neovim instances — from
  [mdview.nvim](../plugins/mdview.nvim.md).
- **`lib.nvim.cross.fs.mutate` with pluggable `on_retry` hooks** as a
  standalone mini-library — every plugin with Windows fileops hits the same
  watcher-lock bug class — from [filetree.nvim](../plugins/filetree.nvim.md),
  echoed independently in [fileops.nvim](../plugins/fileops.nvim.md).
- **`FiletreeAdapter` interface** generalized into a standalone filetree
  backend-abstraction library, usable for git-status overlays or
  LSP-diagnostics-in-tree plugins — from [filetree.nvim](../plugins/filetree.nvim.md).
- **`cwd_mode`** (root-policy state machine + `dir_guard` + diff-based
  statusline update) as a standalone "project-root-policy" plugin,
  independent of any filetree — from [filetree.nvim](../plugins/filetree.nvim.md).
- **Locale-independent Windows Recycle-Bin restore** as its own small
  cross-platform trash library — from [filetree.nvim](../plugins/filetree.nvim.md).
- **Markdown-reference-aware move/delete flow** (scan → prefetch at staging →
  chooser → retarget) generalized to other link formats (reST, AsciiDoc) —
  from [filetree.nvim](../plugins/filetree.nvim.md) and echoed by
  [markdown.nvim](../plugins/markdown.nvim.md)'s **link-integrity.nvim** idea
  (same pattern, framed as a standalone plugin for arbitrary file types).
- **Adaptive-debounce module** (file/input size → delay tier) if the pattern
  recurs across plugins (color_my_ascii, possibly github_stats background
  fetching) — from [color_my_ascii.nvim](../plugins/color_my_ascii.nvim.md).
- **Cache-statistics widget** (`:CacheStats`-like command) showing hit-rate/
  size/evictions uniformly across plugins — from
  [color_my_ascii.nvim](../plugins/color_my_ascii.nvim.md).
- **Regex/pattern-migration framework** (registry + generic picker +
  long-string tracker) reusable by other *.nvim projects for their own API
  migrations — from [migrate.nvim](../plugins/migrate.nvim.md).
- **Deprecation watcher** warning on `:checkhealth`/save if unmigrated
  deprecated calls remain — deliberately not built into migrate.nvim itself —
  from [migrate.nvim](../plugins/migrate.nvim.md).
- **Robust buffer-jump fallback chain** (`vim.t.bufs` → `tabpagebuflist` →
  windows → `getbufinfo`) generalized into a shared "which buffers are
  visible in this session" helper, currently duplicated at one call site —
  from [nvim-config](../nvim-config.md).
- **Startup-phase-runner** (`lua/startup/`) as a standalone, minimal,
  config-independent plugin for measuring/reporting any Neovim config's
  startup phases — from [nvim-config](../nvim-config.md).

## Standalone plugin ideas

Ideas framed as an entirely new *.nvim project, not just a lib.nvim module.

- **Explorer-Singleton plugin** generalizing the "two competing file-browser
  UIs displace/restore each other" logic out of a config-local autocmd file —
  from [nvim-config](../nvim-config.md).
- **Word/Number-Cycler plugin** (`cycler.nvim`) extracting `ctrl_cycle.lua`'s
  case-aware cycling of configurable word pairs — from
  [nvim-config](../nvim-config.md).
- **EmmyLua-aware comment-toggler** handling `---@` annotations distinctly
  from normal comments — from [nvim-config](../nvim-config.md).
- **sticky-marks.nvim**: multi-colored, named, persistent line marks with
  yank/jump/clear surviving reloads/sessions, generalizing
  [buffer-ctx.nvim](../plugins/buffer-ctx.nvim.md)'s extmark-based mark
  pattern.
- **dependency-graph-diff tool** comparing two `insights.imports` scans
  (e.g. pre/post refactor), rendering only changed edges, building on
  `build_dot`'s pure edge list — from [insights.nvim](../plugins/insights.nvim.md).
- **datewalker.nvim**: standalone generalization of `cascade.nvim`'s
  calendar-aware ISO-date cycling (cursor position determines year/month/day
  segment, with rollover), useful outside list contexts (log files, commit
  messages) — from [cascade.nvim](../plugins/cascade.nvim.md).
- **Vendored-Code-Drift-Checker**: periodic/on-demand check of configured
  local-file-to-URL pairs for drift, building on `diff.nvim`'s URL-diff
  capability — from [diff.nvim](../plugins/diff.nvim.md).
- **dedupe.nvim**: standalone structural-duplicate finder using only
  `documentation.nvim`'s `fn.shape` tree-sitter-subtree hashing, as a
  general-purpose CPD tool for any Lua tree — from
  [documentation.nvim](../plugins/documentation.nvim.md).
- **systemctl.nvim** / **k8s.nvim**: same hexagonal ports-&-adapters +
  list-view UI as [sandbox.nvim](../plugins/sandbox.nvim.md), retargeted at
  systemd units or Kubernetes resources.
- **`.projectrc` family**: generalizing `sandbox.nvim`'s `.sandboxrc` pattern
  (key=value project-root config file, whitelisted values, session > project
  > default precedence) for other per-project overrides (formatter, linter,
  interpreter choice) — from [sandbox.nvim](../plugins/sandbox.nvim.md).
- **safeguard.nvim**: generalizing `cmdlog.nvim`'s risky-vs-known-failed
  command classification into a proactive interceptor that confirms before
  executing a risky `:`/shell command, not just retroactive picker
  highlighting — from [cmdlog.nvim](../plugins/cmdlog.nvim.md).
- **table-view.nvim**: standalone extraction of `markdown.nvim`'s TableView
  rendering engine (Markdown/box-style, browser export) for CSV/TSV or
  Ex-command output, decoupled from Markdown — from
  [markdown.nvim](../plugins/markdown.nvim.md).
- **rename-tracker** (extmark + positional-fallback) as a lib.nvim building
  block other plugins could reuse for variable names/tags/IDs, generalized
  from `markdown.nvim`'s heading-rename detection — from
  [markdown.nvim](../plugins/markdown.nvim.md).
- **merge-assist.nvim**: builds on `fileops.nvim`'s conflict-marker
  highlighting to add navigation between conflict blocks (`]x`/`[x`),
  "take ours/theirs" actions, and auto `git add` after resolution — from
  [fileops.nvim](../plugins/fileops.nvim.md).
- **line-history-preview.nvim**: standalone extraction of `fileops.nvim`'s
  `on_hold.lua` ambient git-blame line-diff preview, independent of a
  file-ops context — from [fileops.nvim](../plugins/fileops.nvim.md).
- **Bulk-File-Op plugin**: generalizing `fileops.nvim`'s
  plan/preview/confirm/execute pattern to bulk delete/move with pattern
  matching, not just rename — from [fileops.nvim](../plugins/fileops.nvim.md).
- **`:LockWho <path>` standalone command/plugin**: Windows file-lock diagnosis
  usable anywhere in the editor, not tied to fileops.nvim — from
  [fileops.nvim](../plugins/fileops.nvim.md); overlaps with
  [lib.nvim](../plugins/lib.nvim.md)'s own `:LibWhoLocks` idea above.
- **Proc-Watch plugin (Windows)**: standalone extraction of
  `debugging.nvim`'s UI-freeze diagnosis (blocking-call tracing + external
  process-tree watcher), usable without the rest of debugging.nvim — from
  [debugging.nvim](../plugins/debugging.nvim.md).
- **Keylogger-as-input-recorder**: generalizing `debugging.nvim`'s terminal
  keylogger loop into a generic timestamped input recorder (e.g. for macro
  recording beyond terminal buffers) — from [debugging.nvim](../plugins/debugging.nvim.md).
</content>
