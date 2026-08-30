# nvim-config — Usercmds Cheatsheet

Source: `lua/bindings/usrcmds/init.lua`, `lua/bindings/mappings/window_orientation.lua`,
`lua/bindings/usrcmds/autocmd_docs/init.lua`,
`lua/bindings/usrcmds/telemetry_nvim_config/init.lua`,
`lua/startup/init.lua`, `lua/wkdoptions/commands/register.lua`

**Not a plugin.** The commands this configuration registers in its own Lua,
which belong to no plugin. The folder already held a few of these under their
own command name (`MyPlugins.md`, `MyReposUpdate.md`, `WhoLocks.md`,
`bindings_explorer.md`, `Case.md`, `DocMapAll.md`); this file collects the
rest, which had no sheet at all and therefore showed up as
`usercmd-undocumented-source` in `:Bindings check`.

The keymaps half lives in [`Keymaps/nvim-config.md`](../Keymaps/nvim-config.md).

All of these go through `lib.nvim.bindings.usercmd`'s `create`.

## Editor and window layout

| Command | Range | Effect |
| --- | --- | --- |
| `:WinVertical` | — | `:wincmd H` — move the current window into a vertical split, left side. Same action as `<leader>wl` |
| `:WinHorizontal` | — | `:wincmd K` — move it into a horizontal split, top. Same action as `<leader>wh` |

Only two of the five `window_orientation` moves have a command; the right,
bottom and rotate variants are keymap-only.

## Paths and the clipboard

| Command | Range | Effect |
| --- | --- | --- |
| `:CopyLocation` | — | Copy `<absolute path>:<line>:<column>` of the cursor to the `+` register. Warns instead of copying when the buffer has no file on disk. Column is reported 1-based |
| `:BindingsPath` | — | Copy `<stdpath('config')>/docs/NOTES/BINDINGS` to the `+` register. Also on `<leader>BI`. Marked `TEMP` in the source |
| `:CwdHere` | — | `:lcd` to the directory of the current buffer's file. Window-local, not global. Known gap: an open `neo-tree`/`nvim-tree`/`netrw` does not pick the new cwd up until it is reloaded |
| `:PowershellProfile` | — | Resolve `$PROFILE` through `powershell -NoProfile` and `:edit` it. Errors out when `powershell` is not executable |

`:BindingsPath` points at `docs/NOTES/BINDINGS`, which is not where this
corpus lives — the two trees are `docs/NOTES/PersonelPlugins/BINDINGS` and
`docs/NOTES/ExternPlugins/Bindings`. Recorded as observed, not corrected
here.

## Startup instrumentation

| Command | Range | Effect |
| --- | --- | --- |
| `:StartupReport` | — | Open the startup phase timeline in a themed float (`startup.report.open`) |
| `:StartupCheck` | — | The same data reduced to policy violations only (`startup.report.check`) |

## Options

| Command | Range | Effect |
| --- | --- | --- |
| `:WKDDiffProfile {profile}` | — | **Not registered — see below.** Would switch the diff profile via `wkdoptions.set_diff_profile.selector`; takes exactly one argument and completes the profile names, and called bare would list them instead of erroring |

**`:WKDDiffProfile` does not exist in a running session**, and this is a
finding rather than a caveat. `wkdoptions/commands/register.lua` defines it,
but only from `M.register_all()`, and nothing calls `register_all()` — the
three entry points that do run are `register_highlight_commands` and
`register_highlight_debug_command` (from `wkdoptions/hl_config/init.lua`) and
`register_options_commands` (from `wkdoptions/options_config/init.lua`).

`M.register_debug()` sits in the same `register_all()` body but is *not*
affected: `hl_config/init.lua` reaches it separately through the facade's
`register_highlight_debug_command`, so `:WKDHighlightDebugCtx` does exist.
`register_diff_profile` is the only one of the four with no caller at all.

Found by `:Bindings check` reporting it on both axes at once: present in the
source map, absent from `nvim_get_commands`. Documented as it stands rather
than quietly wired up, since registering a new command is a change to the
editor's behaviour, not a documentation fix.

## Aliases for plugin commands

Registered here, not by the plugin — each one is a fixed argument list this
config types often enough to name.

| Command | Range | Effect |
| --- | --- | --- |
| `:LibAutocmdDocsAll [dir] [--dry-run]` | — | Run lib.nvim's autocmd-docs generator across every repository under `dir` (default `$REPOS_DIR`). The per-repo `:LibAutocmdDocs` / `:LibUsercmdDocs` pair comes from lib.nvim itself; only the `…All` sweep is config-local |
| `:RATelemetryNvimConfig` | — | `:RATelemetry setup nvim-config` |
| `:RATelemetryNvimConfigFull` | — | `:RATelemetry full nvim-config` |

`:LibUsercmdDocsAll` deliberately does not exist: lib.nvim has no `write_all`
for user commands. The autocmd sweep derives its repository set from records
carrying a source path, which the usercmd records now do too, so this is a
small addition if it is ever wanted — not a missing capability.

## Notes

- **Where the rest are.** Commands this config registers that already had a
  sheet keep it: `:MyPlugins` / `:MyPluginsDashboard`
  ([MyPlugins.md](./MyPlugins.md)), `:MyReposUpdate`
  ([MyReposUpdate.md](./MyReposUpdate.md)), `:WhoLocks`
  ([WhoLocks.md](./WhoLocks.md)), `:Bindings`
  ([bindings_explorer.md](./bindings_explorer.md)), `:Cases`
  ([Case.md](./Case.md)), `:DocMapAll` ([DocMapAll.md](./DocMapAll.md)).
  Nothing here duplicates those.
- **`:CwdHere` and `:PowershellProfile` were reachable before**, but only as
  a "Flat equivalent" cell inside a `lib.nvim.md` table whose column names
  the drift scraper cannot read as commands. They are documented properly
  here; the `lib.nvim.md` mention stays as the cross-reference it is.

## Changelog

- 2026-08-30: created. Closes the `usercmd-undocumented-source` findings of
  `:Bindings check` for this config's own Lua. Writing it turned up one
  defect: `:WKDDiffProfile` is defined but never registered, because
  `wkdoptions.commands.register`'s `register_diff_profile()` has no caller —
  the other three registrars in that module are each reached directly.
