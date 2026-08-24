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

## documentation.nvim

- `:DocMap churn [range]` / `:DocMap diff [ref]` have no completion for
  git refs/ranges (unlike module names); `git branch`/`git tag`-based
  suggestions would be possible.
- No `<Plug>`-style mappings for individual `DocBrowse` actions (e.g.
  `goto_source`) usable outside an open browser instance — only reachable via
  `opts.keys`.
— from [documentation.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/documentation.nvim.md)

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

## lib.nvim

- No idea gaps flagged directly against lib.nvim's own (nonexistent) keymaps —
  see instead lib.nvim's "Ideen für andere Plugins" for generalized modules it
  could expose.
— from [lib.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/lib.nvim.md)

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
