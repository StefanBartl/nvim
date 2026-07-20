# User commands — overview & collision check

You weren't sure this analysis makes sense for usercmds the way it does for
keymaps — short answer: **the risk is structurally much lower**, but a
master overview is still useful, and there are a couple of small, genuine
findings below. Reasoning first, then the table.

## Why usercmds can't silently collide the way keymaps do

Two different mechanisms protect user commands that don't exist for
keymaps:

1. **Neovim refuses to define the same command name twice** (unless
   `force = true` is passed) — `vim.api.nvim_create_user_command` errors
   loudly at registration time. A real name collision would surface
   immediately as a startup error, not a silent runtime ambiguity. None of
   the 26 plugins here share a top-level command name (verified below), so
   this has never actually happened.
2. **Exact match always wins over prefix-abbreviation** in Vim's command
   resolution. If you type `:File`, Neovim checks for a command literally
   named `File` first (fileops.nvim's own command) — it does **not** get
   confused by `:Filetree`/`:Ft` (filetree.nvim) also starting with those
   letters, because `:File` is itself a real, fully-registered command.
   Ambiguity (`E464: Ambiguous use of user-defined command`) only happens
   if you type a *truncated* string that matches **multiple** commands and
   **isn't itself** one of them.

Since every plugin here registers one (or a few) fully-spelled, real
top-level command(s) — not a family of partial fragments — cross-plugin
ambiguity effectively can't happen by accident. The only place the
abbreviation-ambiguity mechanism can bite is *within* a single plugin that
has several same-prefixed subcommand-style flat commands but no exact
match at the shorter prefix — found three such cases, all minor (below).

## Master list (global, top-level commands)

| Command | Plugin | Purpose |
| --- | --- | --- |
| `:Cascade` | cascade.nvim | List rotate/sort/reverse/strip/indent/dedent/renumber |
| `:ColorMyAscii` | color_my_ascii.nvim | ASCII-art highlighting, schemes, fences |
| `:Cmdlog` | nvim-cmdlog | Command/shell history pickers |
| `:Container` | nvim-containers | Container ops (list/logs/exec/start/stop/…) |
| `:Copy` | buffer-ctx.nvim | Copy context text to clipboard (subcommand tree) |
| `:Dap` | dap.nvim | Debug adapter control |
| `:Debug` | debugging.nvim | ~15-category debug view/dump toolkit |
| `:Diff` | diff.nvim | Run a diff |
| `:DiffBuffers` | diff.nvim | Diff current buffer vs. another open buffer |
| `:DiffClear` | diff.nvim | Close all `:Diff` windows |
| `:DiffExit` | diff.nvim | Leave diff mode from anywhere |
| `:DiffOrig` | diff.nvim | Diff buffer vs. on-disk version |
| `:Emojis` (configurable name) | emojis.nvim | Emoji insert/count/list/replace |
| `:File` | fileops.nvim | File ops: new/rename/duplicate/delete/next/prev/cd/… |
| `:Filetree` / `:Ft` | filetree.nvim | Full tree feature command surface (~64 sub-paths) |
| `:Format` | buffer-ctx.nvim | Buffer/selection formatting (subcommand tree) |
| `:GithubStats` | github_stats.nvim | Fetch/show/summary/chart/export/dashboard |
| `:Gopath` | gopath.nvim | Resolve/open/copy/debug/check/probe/cache |
| `:GopathResolve`/`Open`/`Copy`/`Debug`/`Check`/`Probe`/`CacheBuild`/`CacheInfo`/`CacheAddRoot` | gopath.nvim | Legacy compat aliases (kept alongside, individually toggleable) |
| `:Image` | nvim-containers | Image ops (list/pull/remove/prune) |
| `:Insert` | buffer-ctx.nvim | Insert context text at cursor (subcommand tree) |
| `:LastSession` | sessions.nvim | Load the "last" session (CLI-friendly, plain command) |
| `:Lib` | lib.nvim | `cwd-here`/`ps-profile`/`helptags` (alongside pre-existing flat `:CwdHere`/`:PowershellProfile`) |
| `:Mark` | buffer-ctx.nvim | Toggle/yank per-line marks |
| `:MarkLineToggle` / `:MarkLinesYank` | buffer-ctx.nvim | Compat aliases for `:Mark toggle`/`:Mark yank` |
| `:Markdown` | markdown.nvim | links/toc/refs/table/render/preview/mdview/create/scope/headline_spacing |
| `:MDView` | mdview.nvim | Preview relay start/stop/toggle/theme/log/diagnose |
| `:MigrateNotify` | migrate.nvim | Migrate `notify()`-style calls |
| `:MigrateOpt` | migrate.nvim | Migrate `vim.opt`-style calls |
| `:Open` | open.nvim | Open target with a handler (default/browser/filemanager/…); `:Open viewer [kind]` lists links in a scope |
| `:UrlView` / `:MDLinksView` | open.nvim | Wrappers for `:Open viewer urls` / `:Open viewer mdlinks` — list/open/export links. **`:UrlView` was formerly owned by axieax/urlview.nvim** (now removed from the config); names are configurable via `viewer.commands` |
| `:PdfPort` | pdfport.nvim | Open/extract/render a PDF |
| `:Pickers` | pickers.nvim | Scope+action fuzzy pickers |
| `:DirPicker` + 10 more | pickers.nvim | Compat aliases (unchanged) — see that repo's `docs/COMMANDS.md` |
| `:ProjectInsight` | project-insight.nvim | symbols/metrics/tree/cache/compress/imports/conflicts/… |
| `:Recommender` | recommender.nvim | Suggestion float (regex/treesitter analyzers) |
| `:Replace` / `:Replacer` | replacer.nvim | Search-and-replace |
| `:ReplaceDebug` | replacer.nvim | Debug helper (untouched, not composer-based) |
| `:Reposcope` | reposcope.nvim | start/close/sort/filter/update/status/stats/… |
| `:Session` | sessions.nvim | save/load/delete/rename/list/current/toggle-track |
| `:Spellcheck` | language.nvim | Spell/grammar review |
| `:Surround` / `:Wrap` | replacer.nvim | Wrap matches with a delimiter |
| `:Translate` / `:TranslateReplace` | language.nvim | Translate (popup/window) / translate-and-replace |
| `:Wsl` | nvim-containers | WSL distro ops (only if `wsl.exe` reachable) |

## Buffer-local commands (only exist on a specific filetype's buffer)

| Command | Plugin | Scope |
| --- | --- | --- |
| `:OpenWithSystemApplication` | markdown.nvim | markdown/mdx/md buffers |
| `:TableViewToggle`/`Markdown`/`Box`/`Select`/`Close`/`OpenBrowser`/`OpenBrowserNice` | markdown.nvim | markdown/mdx/md buffers |
| `:Fence ...` family | color_my_ascii.nvim | markdown buffers (buffer-local, pre-dates composer, left untouched) |

## Findings

**No exact duplicate command names anywhere** — verified across all 26
plugins' full command lists (global + buffer-local). Given point 1 above,
this also means no plugin has ever hit a hard registration-time error from
another plugin in this set.

**Three small, same-plugin, abbreviation-ambiguity clusters** (only
relevant if you hand-type a truncated command instead of tab-completing —
low real-world risk, noted for completeness since you asked specifically
about the `<leader>c`/`<leader>cc` shape of problem, and this is its
usercmd equivalent):

- **`:GopathCache*`** (gopath.nvim) — `GopathCacheBuild`/`GopathCacheInfo`/`GopathCacheAddRoot` exist, but there's no bare `:GopathCache`. Typing exactly `:GopathCache` (not tab-completed) hits `E464: Ambiguous use of user-defined command`.
- **`:TableView*`** (markdown.nvim) — 7 variants (`Toggle`/`Markdown`/`Box`/`Select`/`Close`/`OpenBrowser`/`OpenBrowserNice`), no bare `:TableView`. Same ambiguity if typed exactly truncated.
- **`:Rep*`** across plugins — `Replace`/`Replacer`/`ReplaceDebug` (replacer.nvim) and `Reposcope` (reposcope.nvim) all start with `Rep`. This is the one place a truncated abbreviation spans *different* plugins — but since none of these commands is itself named `Rep`, and you'd need to type exactly that 3-letter fragment (not `:Replace` or `:Repo`, which are unambiguous the moment they diverge), this is essentially theoretical in normal usage.

None of these are bugs — they only manifest if you deliberately type a
shortened command name instead of using `<Tab>` completion, which this
config's whole `composer`-based design otherwise strongly encourages.
