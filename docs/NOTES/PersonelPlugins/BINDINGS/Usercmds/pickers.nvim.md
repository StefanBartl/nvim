# pickers.nvim — User Commands Cheatsheet

One command tree, built via `lib.nvim.usercmd.composer` (migrated
2026-07-19). Kept the compat aliases **alongside** `:Pickers` rather than
replacing them — this repo already had an explicit, documented compat-layer
convention (unlike other repos' default of removing flat commands post-port).

Source: `lua/pickers/command/composer.lua` (registration), `lua/pickers/command/init.lua` (dispatch, unchanged), `lua/pickers/bindings/usrcmds.lua` (compat aliases, unchanged)
Docs: `docs/COMMANDS.md`, `docs/BINDINGS.md`, `doc/pickers.txt`

| Command | Args | Effect |
| --- | --- | --- |
| `:Pickers` | — | Interactive scope picker → action picker |
| `:Pickers {scope}` | `[action]` | `scope` ∈ `cwd`\|`config`\|`folder`\|`repos`\|`wkdbooks`\|`system`\|`drives`\|any collection name |
| `:Pickers dir` | `[nav] [action]` | Depth / alias / explicit-path navigation, then files/grep |
| `:DirPicker` etc. | — | 11 compat aliases, unchanged — see `docs/COMMANDS.md` |

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
  is called once immediately (built-in scopes only, so `:Pickers cwd` etc.
  keep working with zero config, an explicit pre-existing guarantee) and
  again from `pickers.bindings.setup(cfg)` — which fires from either the
  user's `setup()` call or the `VimEnter` fallback — so collection names
  always end up in `:Pickers <Tab>` and as real subcommand routes by
  `VimEnter` at the latest. A collision between a collection name and a
  built-in scope (or a duplicate collection name) is silently skipped
  first-match-wins, matching the old `find_collection` lookup order — a
  literal-path collision would otherwise be a hard `composer: duplicate
  route` error.
- **Custom type for `dir`'s nav slot**: `PICKERS_DIR_NAV` — the nav arg
  accepts aliases, `1`-`9` depth, `path=...`, or (when nav is omitted) an
  action word, none of which map onto a built-in composer type. Registered
  once at module load, per the roadmap's "don't downgrade completion UX"
  guidance.
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
- **No pre-existing bugs found** while verifying (registration, `<Tab>`
  completion, and dispatch down to `pickers.engines.load()`'s expected "no
  picker engine installed" error in this sandbox — confirmed via headless
  `nvim -l`/`nvim --headless` checks, not just the unit suite).
