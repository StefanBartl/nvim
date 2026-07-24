# sessions.nvim — `:Session <subcommand>` Cheatsheet

One command, built via `lib.nvim.usercmd.composer` (`<Tab>` completion,
session-name args complete **dynamically** via a custom `SESSION` type
registered with `composer.register_type` — the first real external use of
that extension point). Replaces the old 8 flat `:SessionX` commands (fully
removed, no alongside period). Plus a standalone `:LastSession`.

Source: `lua/sessions/bindings/usercmds/init.lua`
Docs: `docs/BINDINGS.md`, `docs/commands.md`, `README.md`, `doc/sessions.txt`

| Command | Effect |
| --- | --- |
| `:Session save [name]` | Save session (auto-named if omitted) |
| `:Session save-timestamp` | Save with a `sess-YYYYMMDD-HHMMSS` suffix |
| `:Session load [name]` | Load session (tab-completes saved names) |
| `:Session delete <name>` | Delete session + companion metadata |
| `:Session rename <old> <new>` | Rename session + companion metadata |
| `:Session list` | List sessions with timestamp and branch |
| `:Session current` | Print the active session name |
| `:Session toggle-track [name]` | Toggle `git skip-worktree` on a session file |
| `:LastSession` | Load the "last" session — plain command, CLI-friendly |

## ⚠️ `nvim +cmd` CLI workflow changed

This plugin's whole README/quickstart is built around `nvim +SessionLoad
[name]` as the primary restore workflow. That **breaks** under the
composer migration for anything except the fixed "last" case, because
`+cmd` is a single shell word — the shell splits unquoted spaces before
Neovim ever sees them:

```bash
# OLD (single word, worked unquoted):
nvim +SessionLoad
nvim +SessionLoad myproject

# NEW:
nvim +LastSession              # unquoted — dedicated command, exactly for this
nvim '+Session load'           # quoted — auto-resolved (project+branch)
nvim '+Session load myproject' # quoted — explicit name
```

**Decision made**: only the "last" case got its own command (`:LastSession`,
as explicitly requested). Everything else (auto-resolved bare load, named
loads) requires quoting going forward — documented, not silently broken.

## Notes

- `:LastSession` calls `core.load("last")` explicitly (not the bare-load
  fallback), so it stays correct even if `default_name`/`autosave_name` are
  reconfigured to something other than `"last"`.
- **lib.nvim policy flip**: same as cascade.nvim/color_my_ascii.nvim — was
  "optional", is now **required** (`:Session`/`:LastSession` need
  `lib.nvim.usercmd.composer`). `lib.nvim.notify`/`lib.nvim.map`/`lib.nvim.git`
  stay soft-guarded.
- No CI exists for this repo, so no CI checkout fix was needed.
- Keymaps (`bindings/keymaps/init.lua`) referenced commands as `<cmd>...<cr>`
  strings — updated in place. The `save_ts` keymap's duplicate
  timestamp-generation logic (it independently reimplemented what
  `:SessionSaveTimestamp` already did) was simplified to just invoke
  `:Session save-timestamp` directly.
