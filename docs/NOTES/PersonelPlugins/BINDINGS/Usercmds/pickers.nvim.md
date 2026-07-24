# pickers.nvim — User Commands Cheatsheet

One command tree, built via `lib.nvim.usercmd.composer` (migrated
2026-07-19). Kept the compat aliases **alongside** `:Pickers` rather than
replacing them — this repo already had an explicit, documented compat-layer
convention (unlike other repos' default of removing flat commands post-port).

Source: `lua/pickers/command/composer.lua` (`:Pickers` registration incl.
`builtin` route), `lua/pickers/command/init.lua` (dispatch + the new public
`M.dispatch` entry point), `lua/pickers/bindings/usrcmds.lua` (compat aliases
+ `:PickersRepeat`/`:PickersScopes`/`:PickersResume`, added 2026-07-22),
`lua/pickers/last.lua` (state behind `:PickersRepeat`), `lua/pickers/builtins/`
(registry behind `:Pickers builtin` and `:PickersResume`)
Docs: `docs/COMMANDS.md`, `docs/BINDINGS.md`, `doc/pickers.txt`

| Command | Args | Effect |
| --- | --- | --- |
| `:Pickers` | — | Interactive scope picker → action picker |
| `:Pickers {scope}` | `[action]` | `scope` ∈ `cwd`\|`config`\|`folder`\|`repos`\|`wkdbooks`\|`system`\|`drives`\|any collection name; `action` ∈ `files`\|`grep`\|`smart` |
| `:Pickers dir` | `[nav] [action]` | Depth / alias / explicit-path navigation, then files/grep |
| `:Pickers builtin {name}` | — | Dispatch one of 51 native picker-engine functions (git/LSP/help/vim-intrinsics/diagnostics/…) straight to the resolved engine — bypasses `pickers.command.handle` entirely. See `docs/BUILTINS.md`. Added 2026-07-21/22. |
| `:DirPicker` etc. | — | 12 compat aliases (see below), unchanged |
| `:PickersRepeat` | — | Reopen the most recently dispatched `:Pickers` action (same resolved scope/root/action) — added 2026-07-22 |
| `:PickersScopes` | — | List every resolvable scope (built-ins + collections) via `notify.info` — added 2026-07-22 |
| `:PickersResume` | — | Reopen the last picker with its last query — thin wrapper over `:Pickers builtin resume` (the engine's own native resume, fzf-lua excepted). Added 2026-07-22 |

## Compat aliases (unchanged from the composer migration)

`:DirPicker [nav]` · `:FindConfig` · `:GrepConfig` · `:FindInFolder` ·
`:LiveGrep` · `:AllDrives` · `:AllDrivesGrep` · `:FindOnSystem` ·
`:RepoFiles [repo]` · `:RepoGrep [repo]` · `:WkdBookFiles` · `:WkdBookGrep` —
see `docs/COMMANDS.md` for the full `:Pickers ...` equivalents.

## `smart` action + `:{PascalName}Smart` — added 2026-07-24

The **smart** action (combined grep + find files, merged and ranked) is a
third action alongside `files`/`grep`, so it's reachable everywhere they are:
`:Pickers {scope} smart` for any built-in scope or collection. Each collection
now also generates a `:{PascalName}Smart` compat command (e.g. `:NotesSmart`
→ `:Pickers notes smart`) next to `:{Pascal}Files`/`:{Pascal}Grep`
(`bindings/collections.lua`). Engine-agnostic core lives in
`lua/pickers/smart/` (search + score); each engine adapter got an `M.smart`.
See `:help pickers-smart` and `docs/CONFIGURATION.md#smart-combined-grep--find`.

## `:PickersRepeat` — added 2026-07-22

`pickers.command.dispatch` (a new public wrapper around the pre-existing
private `dispatch_action`) is the single choke point every scope's dispatch
already routed through via `after_source()` — recording into
`pickers.last.set(action, source)` there covers standard scopes and
collections for free. `pickers.actions.dir` used to bypass this with its own
inline files/grep branch; it now delegates to `pickers.command.dispatch`
instead, both removing duplication and bringing `dir`-scope dispatches into
`:PickersRepeat` coverage. In-memory only, current session, not
persisted — a different concern from `pickers.history`. Warns via
`notify.warn` if nothing has been dispatched yet.

## `:PickersScopes` — added 2026-07-22

Reuses `pickers.ui.scope_picker`'s existing scope-list builder (now exported
as the public `M.list()`, previously a local `build_scope_list()` used only
by the interactive picker) — same built-ins-then-collections list, just
printed via `notify.info` (with a one-line description per built-in, and each
collection's root dir) instead of opening a picker.

## `:PickersResume` — added 2026-07-22

Thin (3-line) wrapper over `pickers.builtins.run("resume")` — the registry
already had a `resume` entry (telescope + snacks; fzf-lua marked `false`, no
resume concept there), so no new registry work was needed. Distinct from
`:PickersRepeat`: this resumes the *engine's* last picker session (prompt
text included), not pickers.nvim's own last resolved scope/action (empty
prompt, `:PickersRepeat`'s behavior).

## `:Pickers builtin {name}` — added 2026-07-21, expanded 2026-07-22

Registered via a custom composer type (`PICKERS_BUILTIN_NAME`, tab-completes
against `pickers.builtins.names()`). Dispatch bypasses
`pickers.command.handle` entirely — a builtin is a flat name→function lookup,
not a scope/action shape. The registry itself
(`lua/pickers/builtins/init.lua`) went through two growth passes this
session: an initial rebuild (found to be re-implementing work from an
earlier, never-committed session — see `docs/ROADMAP.md`'s "Native builtin
pickers" entry for the full provenance story) to 31 entries with a richer
`{fn, opts}`-per-engine shape, then expanded to 51 to close a real gap
against the user config's `config/snacks/mappings/standard.lua` (which
already called `pickers.builtins.run()` for ~31 active keymaps, expecting a
module that didn't yet exist on `main`). That user-config file needed **no
changes** once the registry was complete — its existing names
(`recent`/`git_log`/`git_log_file`/`man`/`lsp_symbols`/`gh_issue_all`/
`gh_pr_all`) already matched the registry's own naming convention.
`config/snacks/usrcmds/` (~40 `:SnacksXxx` commands, the older, snacks-only
equivalent of this) was deleted as a result — verified every command it
exposed has a `:Pickers builtin <name>` equivalent first.

## Notes

- **Dispatch fully delegated, not reimplemented**: every composer route's
  `run` only reconstructs `{ fargs = {...} }` and forwards to the pre-existing
  `pickers.command.handle` — the dir nav/action ambiguity resolution
  (`:Pickers dir grep` → nav=nil, action="grep"), the soft "Unknown action ...
  Showing action picker" fallback, `find_collection`'s first-match-wins
  lookup, are all byte-for-byte unchanged. This mirrors github_stats.nvim's
  migration design more than buffer-ctx.nvim's — reconstruct-and-forward
  rather than re-deriving dispatch logic in the route tree itself.
- **Collection scopes are dynamic, registered twice**: `:Pickers <name>`
  scopes come from `cfg.collections`, which isn't known at `plugin/pickers.lua`
  load time (before `setup()` runs). `pickers.command.composer.register(cfg)`
  is called once immediately (built-in scopes + `builtin` route only, so
  `:Pickers cwd`/`:Pickers builtin` etc. keep working with zero config, an
  explicit pre-existing guarantee) and again from `pickers.bindings.setup(cfg)`
  — which fires from either the user's `setup()` call or the `VimEnter`
  fallback — so collection names always end up in `:Pickers <Tab>` and as
  real subcommand routes by `VimEnter` at the latest. A collision between a
  collection name and a built-in scope/route (or a duplicate collection name)
  is silently skipped first-match-wins, matching the old `find_collection`
  lookup order — a literal-path collision would otherwise be a hard
  `composer: duplicate route` error.
- **Custom type for `dir`'s nav slot**: `PICKERS_DIR_NAV` — the nav arg
  accepts aliases, `1`-`9` depth, `path=...`, or (when nav is omitted) an
  action word, none of which map onto a built-in composer type. Registered
  once at module load, per the roadmap's "don't downgrade completion UX"
  guidance. `PICKERS_BUILTIN_NAME` (added 2026-07-21) follows the same
  once-at-module-load pattern, since the builtins registry is static (doesn't
  depend on `cfg` the way collections do).
- **Message-text change, accepted**: `:Pickers bogus_scope` now reports
  composer's own `unknown subcommand 'bogus_scope'. Usage: :Pickers
  <subcommand> …` (listing every registered route) *before* ever reaching
  `pickers.command.handle`'s own `UnknownScopeError` branch — that branch is
  now unreachable from the CLI (composer's tree-walk rejects an unmatched
  first token itself) but stays as defense-in-depth for direct Lua callers of
  `pickers.command.handle({ fargs = {...} })`, a documented public entry
  point used by every compat alias.
- **`command.complete` deleted, not kept dead**: the old hand-rolled
  `pickers.command.complete(arglead, cmdline, cursorpos)` (and its
  `get_collection_names()`/`ACTIONS` helpers) is gone — composer now owns
  `:Pickers` completion end-to-end. `docs/TESTS/pickers_spec.lua`'s
  completion tests were rewritten to register the real command and drive it
  via `vim.fn.getcompletion("Pickers ...", "cmdline")` instead of calling the
  removed pure function directly — exercises the actual route tree, not a
  parallel reimplementation of it.
- **No CI changes needed**: `.github/workflows/ci.yml`'s `test` job already
  checked out `lib.nvim` as a sibling (needed pre-migration for
  `command.complete`'s `lib.nvim.notify` dependency), so `lib.nvim.usercmd.composer`
  was already reachable. `:Pickers` losing its raw-`nvim_create_user_command`
  fallback (lib.nvim is now hard-required for the command layer, same as
  every other migrated repo) needed no test-gating changes as a result.
