# Missing flag/option ideas (grouped by plugin)

> **Backlog, keine Regel.** Gesammelte Flag-/Options-Ideen aus dem Code-Audit vom
> 2026-08-08, nach Plugin gruppiert. Abarbeiten und streichen.
> Belege: `Checklists/belege/` (siehe `Checklists/README.md`).
> Regeln zu Konfigurierbarkeit: `Checklists/regeln/LUA_NVIM.md` § Konfigurierbarkeit.


Collected "Fehlende Flags/Optionen" ideas from each per-plugin report's
Keybindings-Audit section. These are things the report's author noticed while
reading the code, not confirmed feature requests.

## nvim-config

- `:MyPlugins clone/reclone --dry-run` — a preview of what would be
  cloned/removed; the groundwork already exists in `finish_check`/
  `finish_reclone`, just not exposed as an isolated dry-run path.
- `:MyReposUpdate --only=<name>` — analogous to `:MyPlugins fetch/pull/update
  --only=<name>`; currently always all repos in the directory.
- `:WhoLocks --json` — for a future pickers.nvim integration (currently plain
  text notify + `print`).
- `:Trouble` mappings (`[w`/`]w`): add a `<leader>x`-prefixed variant taking an
  explicit `count` argument, once Trouble's API supports it.
— from [nvim-config](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/nvim-config.md)

## buffer-ctx.nvim

- `:Mark toggle` could get a range mode (visual selection → mark all covered
  lines).
- `mark.sign` only allows one global sign/highlight; multiple "categories" of
  marks (red/green/yellow) are a natural extension, entirely absent.
- No `:Mark clear` to empty all marks in a buffer without toggling individually.
— from [buffer-ctx.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/buffer-ctx.nvim.md)

## cascade.nvim

- No count support on Cycle (`<C-y>`/`<C-x>`), Move (`<A-Up>`/`<A-Down>`), or
  quick-toggle in Normal mode — inconsistent with the otherwise deliberate
  count design on indent/dedent.
- `cycle.groups`/`per_filetype` are purely static from config; no live
  add/edit command (e.g. `:Cascade cycle add {a},{b}`) despite the plugin
  otherwise exposing a lot through `:Cascade`.
— from [cascade.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/cascade.nvim.md)

## debugging.nvim

- `<lt>c` (capture messages) can't choose file-only or clipboard-only from the
  keymap itself — only via `:Debug messages capture` with a Lua API call.
— from [debugging.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/debugging.nvim.md)

## documentation.nvim

- `:DocMap churn [range]` / `:DocMap diff [ref]` have no completion for
  git refs/ranges (unlike module names); `git branch`/`git tag`-based
  suggestions would be possible.
- No `<Plug>`-style mappings for individual `DocBrowse` actions (e.g.
  `goto_source`) usable outside an open browser instance — only reachable via
  `opts.keys`.
— from [documentation.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/documentation.nvim.md)

## recommender.nvim

- No way to set the analyzer threshold directly as a flag (`--threshold=N`)
  instead of an unnamed second positional argument — currently a fallback
  chain (`tonumber(pos_args[2]) or tonumber(pos_args[1])`), ambiguous for
  command-line users who only want to change the threshold.
— from [recommender.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/recommender.nvim.md)

## sandbox.nvim

- No keymap/command to switch between the three engines directly from the
  list-view (only `:Sandbox engine set`).
- `container exec`/`exec-once` have no flag to set a working directory inside
  the container (`docker exec -w`).
- No `--dry-run`/preview for destructive bulk actions before confirming (only
  "Remove 5 containers?", not which ones).
- List-views have no search/filter keymap (`/` only searches within the
  buffer, no structured filter by status/name).
— from [sandbox.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/sandbox.nvim.md)

## emojis.nvim

- `:Emojis next` has no count support (`nav.lua:72-79` always advances by 1).
- Overlay grid has no type-to-filter mode (only the `list` mode has that via
  the kit-chooser).
- `checkbox.toggle` with `dir = -1` (backward) exists in `core/checkbox.lua`
  and `actions.checkbox`, but is reachable only via the Lua API — no
  `:Emojis toggle` argument or preset keymap for backward toggle.
- `search.no_ignore`/extra globs are only reachable via `:Emojis <action> cwd
  <glob>...`; a `!`-bang suffix (`:Emojis! clear cwd`) for "this time with
  no_ignore" would follow common Vim idiom but is absent.
— from [emojis.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/emojis.nvim.md)

## fileops.nvim

- No keymap for `bulk rename`, `lockinfo`, `info`, `path`, `cd` — only via
  `:File …`; an optional `lhs`-config field for the frequently used ones
  (`path`, `cd`) is suggested.
- `attach_delete` has no "force delete" keymap variant for modified buffers —
  only the Ex-command with `!` covers it.
- Cycle keymaps have no pattern-filter equivalent (`next *.lua` only exists as
  an Ex-command, not as a keymap with a prompt).
— from [fileops.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/fileops.nvim.md)

## cmdlog.nvim

- No multi-select/batch-delete for history entries (only single-entry
  deletion via `<C-x>`).
- `risky_patterns` is a plain Lua-pattern list with no preview of which
  pattern actually matched — a `:Cmdlog risky test <cmd>` would help tune it.
- Shell-history parsers for zsh/fish/bash are hardcoded; no escape hatch for
  exotic history formats (e.g. custom `HISTTIMEFORMAT`).
— from [cmdlog.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/cmdlog.nvim.md)

## pickers.nvim

- No `vim.v.count` hook for `dir_pick`, even though the underlying concept
  ("N levels up") already exists via `:Pickers dir <number>`.
- `keymaps.explorer` (`<leader>.`) is documented in a code comment but not
  explicitly listed as its own `keymaps.explorer` field in the config
  reference — possible doc gap, not fully verified.
- No way to selectively combine the "find all" escalation flags
  (`hidden+no_ignore+follow`) — it's all-or-nothing.
— from [pickers.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/pickers.nvim.md)

## markdown.nvim

- `:Markdown toc [level]` has no count equivalent (`3<leader>toc` for
  `max_level=3` would be a plausible addition).
- `<C-Right>`/`<C-Left>` (heading level inc/dec) likely have no count support
  (`3<C-Right>` = raise 3 levels).
— from [markdown.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/markdown.nvim.md)

## mdview.nvim

- `:MDView zoom <factor>` has no visible validation/clamping of the value.
- No `:MDView start --port <n>` to force a fixed port (e.g. for firewall
  rules) — only implicit via `config.browser`/`server_args`.
— from [mdview.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/mdview.nvim.md)

## filetree.nvim

- No dry-run keymap-toggle for `copy_move`/`rename_batch` (only `trash` has
  `:Filetree trash dry-run`, and only as an Ex-command).
- No keymap to jump directly to a specific mark, or to diff two marked files
  against each other (only `diff marked` vs. the current buffer).
- No Visual-mode keymaps at all — everything is single-node normal-mode or
  marks-based.
— from [filetree.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/filetree.nvim.md)

## color_my_ascii.nvim

- `:ColorMyAscii toggle` could accept a `!`-bang or range to toggle multiple
  buffers at once — currently current-buffer only.
- `fence_export` (`:Fence export [path] [--open] [--replace]`) has no keymap
  counterpart in the ACTIONS table, unlike the other `Fence` subcommands.
— from [color_my_ascii.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/color_my_ascii.nvim.md)

## migrate.nvim

- No dry-run/"preview only, no apply" flag for the single-line case.
- No count-based "migrate the next N lines" support, despite the underlying
  commands being range-capable.
— from [migrate.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/migrate.nvim.md)

## lib.nvim

- No idea gaps flagged directly against lib.nvim's own (nonexistent) keymaps —
  see instead lib.nvim's "Ideen für andere Plugins" for generalized modules it
  could expose.
— from [lib.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/lib.nvim.md)

## sessions.nvim

- No keymap for `:Session current` or the picker (`:SessionLoad`) in the
  default bindings — natural addition for frequent picker users.
- `:Session delete`/`rename` have no keymap option — presumably intentional
  given they're destructive/rare.
— from [sessions.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/sessions.nvim.md)

## pdfport.nvim

- `:PdfPort float`/`terminal` prompt interactively for page-range; a `pages=`
  kv-flag alternative would support scripting/automation of those paths.
- Batch-open (`<leader>pb`) may lack a progress/summary readout (X of Y
  opened, Z errors) — unverified whether `batch.lua` already provides it.
— from [pdfport.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/pdfport.nvim.md)

## github_stats.nvim

- `cycle_sort`/`cycle_time_range` could accept count as "advance N steps"
  (`3s`), not currently supported.
— from [github_stats.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/github_stats.nvim.md)

## language.nvim

- The translate operator-pending mapping has no way to pick a target language
  from the mapping itself (always the default) — a per-language mapping or a
  prompt is suggested.
- The thesaurus keymap has no count-based direct selection of the Nth
  suggested synonym.
— from [language.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/language.nvim.md)

## learn-cli.nvim

- `next_exercise`/`prev_exercise` have no count support ("skip N exercises").
— from [learn-cli.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/learn-cli.nvim.md)

## spotlight.nvim

- `:Spotlight list` supports `jump`/`remove` mode-args but no filter-arg
  (e.g. by color or origin) — useful once many spotlights are active.
- `next`/`prev` could use a `!`-bang or flag to force a session-wide search
  regardless of the configured `nav.scope`.
— from [spotlight.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/spotlight.nvim.md)

## replacer.nvim

- No additional gaps beyond the completion-coverage question tracked in
  [autocompletion.md](autocompletion.md) (full flag/kv-completion for the
  very flag-rich `:Replace` command wasn't fully verified).
— from [replacer.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/replacer.nvim.md)

## reposcope.nvim

- Clone target-directory prompt likely lacks path completion (unverified —
  the relevant file wasn't read).
— from [reposcope.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/reposcope.nvim.md)

## images.nvim

- `paste`/`screenshot` keymaps don't accept a name argument (only the
  `:Image paste {name}` Ex-command does) — noted as desirable for power users
  but impractical as a bare-lhs keymap (no text input path).
— from [images.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/images.nvim.md)
