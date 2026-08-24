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

## lib.nvim

- No idea gaps flagged directly against lib.nvim's own (nonexistent) keymaps —
  see instead lib.nvim's "Ideen für andere Plugins" for generalized modules it
  could expose.
— from [lib.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/lib.nvim.md)

## learn-cli.nvim

- `next_exercise`/`prev_exercise` have no count support ("skip N exercises").
— from [learn-cli.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/learn-cli.nvim.md)

## replacer.nvim

- No additional gaps beyond the completion-coverage question tracked in
  [autocompletion.md](autocompletion.md) (full flag/kv-completion for the
  very flag-rich `:Replace` command wasn't fully verified).
— from [replacer.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/replacer.nvim.md)

## reposcope.nvim

- Clone target-directory prompt likely lacks path completion (unverified —
  the relevant file wasn't read).
— from [reposcope.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/reposcope.nvim.md)

