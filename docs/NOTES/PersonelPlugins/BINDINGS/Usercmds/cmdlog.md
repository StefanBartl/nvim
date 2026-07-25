# cmdlog — User Commands Cheatsheet

One command, built via `lib.nvim.usercmd.composer` (migrated 2026-07-19).
Replaces 7 independent flat commands — breaking change, no compat aliases.
The only repo in the migration series with **zero prior lib.nvim
dependency** — added as part of this migration, per the roadmap plan.

Source: `lua/cmdlog/ui/picker.lua`
Docs: `docs/COMMANDS.md`, `README.md`, `doc/cmdlog.txt`

| Command | Effect |
| --- | --- |
| `:Cmdlog` | Favorites + history combined, deduplicated (bare invocation, via composer's `default`) |
| `:Cmdlog favorites` | Favorited commands only |
| `:Cmdlog full` | Favorites + full history, duplicates included |
| `:Cmdlog nvim` | Neovim `:`-history, deduplicated |
| `:Cmdlog nvim-full` | Neovim `:`-history, duplicates included |
| `:Cmdlog shell` | Shell history, deduplicated |
| `:Cmdlog shell-full` | Shell history, duplicates included |
| `:Cmdlog project` | History recorded while inside the current Git project (`.git` root) |
| `:Cmdlog lua` | Lua-mode history only (`:lua`, `:lua=`, `:=`), deduplicated |
| `:Cmdlog stats` | Commands sorted by usage frequency, annotated with count + last-used date |

Three new subcommands added 2026-07-25 (roadmap pass): `project`, `lua`,
`stats`. All three read from new persistent JSON stores
(`project_history.json`, `stats.json`) populated by a single shared
`CmdlineLeave` autocmd in `core/tracker.lua` — see
`docs/OPTIONS.md`'s `track_commands` option. `project` and `stats` only
reflect commands run since that tracker was introduced; there is no
retroactive attribution of older `:history` entries.

## Notes

- **Subcommand naming**: flat 1:1 mapping from the original command-name
  suffixes (`CmdlogNvimFull` → `nvim-full`, `CmdlogShell` → `shell`, ...)
  rather than a nested `{scope} [full]` tree — kept flat and directly
  traceable to the original names instead of inventing a cleverer grammar,
  since a 2-level tree (`:Cmdlog nvim full` vs `:Cmdlog nvim-full`) wasn't
  obviously better and added restructuring risk for no real gain.
- **Bare `:Cmdlog` preserved via composer's `default` handler**: the
  original bare `:Cmdlog` was its own distinct command
  (`all_unique_picker.show_all_unique_picker`) — mapped directly onto
  `spec.default`, so `:Cmdlog` with no subcommand keeps working unchanged.
- **`docs/COMMANDS.md` was already stale before this migration** — it
  described a completely different, never-actually-existing command
  scheme (`:CmdlogUnique`, `:CmdlogAll`, `:CmdlogAllUnique`) that didn't
  match either the old flat commands or the README's own (accurate) table.
  Rewritten from scratch to match the real command set while migrating,
  rather than mechanically renamed.
- Every picker function (`show_history_picker`, `show_all_unique_picker`,
  etc.) is unchanged — all take zero arguments and ignore whatever's passed
  to them, so using them directly as composer `run`/`default` handlers
  (which receive a `ctx` table) required no adapter code at all.
- No health.lua, no CI in this repo — pre-existing, not part of this
  migration's scope.
