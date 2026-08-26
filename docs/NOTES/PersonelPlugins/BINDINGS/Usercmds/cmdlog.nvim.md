# cmdlog — User Commands Cheatsheet

One command, built via `lib.nvim.bindings.usercmd.composer` (migrated 2026-07-19).
Replaces 7 independent flat commands — breaking change, no compat aliases.
The only repo in the migration series with **zero prior lib.nvim
dependency** — added as part of this migration, per the roadmap plan.

Source: `lua/cmdlog/bindings/usrcmds.lua` (moved out of `ui/picker.lua`
since this file was written, specifically so `docs/BINDINGS.md` and the
code can't drift apart)
Docs: `docs/BINDINGS.md`, `docs/COMMANDS.md`, `README.md`, `doc/cmdlog.txt`

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
| `:Cmdlog risky test {command}` | Reports which `risky_patterns` match `{command}`. **Added 2026-08-24.** Takes the whole remainder of the line, not a positional — a command to test is a command line (`git reset --hard HEAD~1`), and declaring a positional would eat `git` and leave the rest behind. Ignores `highlight_risky`: that gates display, not evaluation, and the output notes when it is off. |
| `:Cmdlog export [path]` | Exports favorites to a JSON file (default: favorites path + `.export.json`). **Added 2026-08-09.** |
| `:Cmdlog import path` | Imports favorites from a JSON file, merged with the current list. **Added 2026-08-09.** |

Three new subcommands added 2026-07-25 (roadmap pass): `project`, `lua`,
`stats`. All three read from new persistent JSON stores
(`project_history.json`, `stats.json`) populated by a single shared
`CmdlineLeave` autocmd in `core/tracker.lua` — see
`docs/OPTIONS.md`'s `track_commands` option. `project` and `stats` only
reflect commands run since that tracker was introduced; there is no
retroactive attribution of older `:history` entries.

`export`/`import` (2026-08-09) are registered directly in
`M.register()`, not via `M.catalog` — every catalog entry is a zero-arg
picker function that `bindings.keymaps` can wire up to a normal-mode
`lhs` unmodified, but `export`/`import` take a path argument, so they
have no `keymaps` entry-point. Same pass also added `redact_patterns`
(privacy filter, checked in `core/tracker.lua` before any of
project-history/stats/errors are written) and `extra_files` (extra
read-only command files folded into the pickers).

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
- **Stale as of the 2026-08-09 checklist pass**: `cmdlog.health`
  (`:checkhealth cmdlog`) and a `.github/workflows/ci.yml` (stylua +
  luacheck + a headless smoke test) both now exist — the "no health.lua,
  no CI" note above no longer applies.
