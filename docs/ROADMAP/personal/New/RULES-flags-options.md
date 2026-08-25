# Missing flag/option ideas (grouped by plugin)

> **Backlog, keine Regel.** Gesammelte Flag-/Options-Ideen aus dem Code-Audit vom
> 2026-08-08, nach Plugin gruppiert. Abarbeiten und streichen.
> Belege: `Checklists/belege/` (siehe `Checklists/README.md`).
> Regeln zu Konfigurierbarkeit: `Checklists/regeln/LUA_NVIM.md` § Konfigurierbarkeit.


Collected "Fehlende Flags/Optionen" ideas from each per-plugin report's
Keybindings-Audit section. These are things the report's author noticed while
reading the code, not confirmed feature requests.

## nvim-config — erledigt 2026-08-24

- [x] `:MyPlugins clone/reclone --dry-run` — the groundwork really was
  already there: the safe/unsafe/missing split `finish_check`/`finish_reclone`
  compute is exactly the preview, it just always went on to confirm and act.
  `dry_run` now short-circuits both after reporting that split. `clone`'s
  dry-run doesn't even need the check phase — it reuses `ops.clone_one`'s own
  "exists" predicate (`loop.fs_stat`, no git call) directly.
- [x] `:MyReposUpdate --only=<name>` — done, but the mechanism differs from
  `:MyPlugins`'s: this command scans an arbitrary directory for *any* git repo
  rather than iterating a named list, so `--only` filters that scan's result
  by directory basename instead of validating against
  `plugins.personal.list`. Completion still works — it scans the resolved
  base dir the same way the real run would (cheap: no git subprocess) and
  offers basenames. Needed migrating `nargs` from `"?"` to `"*"` and a manual
  `--only=` token parse, since the command wasn't composer-based.
- [x] `:WhoLocks --json` — done. `lib.nvim.cross.fs.lock.report` only ever
  produces human text lines, so the json path calls `probe`/`who` directly and
  assembles a `vim.json.encode`-able table itself instead of routing through
  `report`.
- [x] `:Trouble` mappings (`[w`/`]w`) — **turned out to be no gap.**
  `lsp.nvim`'s `trouble_diag_next`/`prev` (where these keys now live, see the
  count audit) already loop `trouble.next()`/`trouble.prev()` `v:count1`
  times client-side — `5]w` already works. The premise ("once Trouble's API
  supports it") no longer applies: the workaround doesn't need a native count
  parameter from Trouble at all, so an explicit `<leader>x`-prefixed count
  variant would just duplicate what `v:count1` on the existing key already
  does.
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

