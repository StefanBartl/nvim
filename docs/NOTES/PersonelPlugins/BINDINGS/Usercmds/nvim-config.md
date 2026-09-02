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
| `:WKDDiffProfile {profile}` | — | Set `diffopt` from a named profile — `minimal`, `context`, `review` or `strict` (`wkdoptions/set_diff_profile/profiles.lua`). `nargs = 1` with completion over the four names |
| `:MyOptSet[!] {keypath} [value]` | — | Set one options-config key. `<Tab>` completes the key paths. With `!` and no value it toggles the key instead |
| `:MyOptShow [keypath]` | — | Print one key's value; without an argument, the whole options table |
| `:MyOptList` | — | List every options-config key path |
| `:WKDOptionsHLSet[!] {keypath} [value]` | — | The same three, for the highlight config. `!` without a value toggles |
| `:WKDOptionsHLShow [keypath]` | — | One highlight key, or the whole table |
| `:WKDOptionsHLList` | — | Every highlight-config key path |
| `:WKDOptionsHLDebugCtx` | — | Dump what the breadcrumb context resolver currently produces: LSP function, treesitter symbol, language extra, word fallback, and the separator it would use |

**Two subsystems, one registrar, and that is why the names look unrelated.**
`wkdoptions/commands/register.lua` defines all seven generically, with default
names `WKDOptSet`/`WKDHighlightSet`/… — and both callers override them:
`options_config/init.lua` asks for `MyOpt*`, `hl_config/init.lua` for
`WKDOptionsHL*`. Neither default name exists in a running session, so grepping
the registrar for the live names finds nothing.

Nachgetragen 2026-09-02. Der Driftreport hatte diese sieben als
"Commands dieser Config selbst — kein Plugin, also auch kein
Cheatsheet-Eigentuemer" gefuehrt und daraus eine Luecke im Aufbau des Korpus
gefolgert. Das war ein Trugschluss: dieses Blatt ist genau der Ort dafuer,
es nennt `wkdoptions/commands/register.lua` seit jeher als Quelle — die Zeilen
fehlten einfach.

**Registered since 2026-08-30, and it was not before.**
`wkdoptions/commands/register.lua` had always defined the command, but only
from `M.register_all()` — and nothing called `register_all()`. The other
three registrars in that module are each reached directly
(`register_highlight_commands` and `register_highlight_debug_command` from
`hl_config/init.lua`, `register_options_commands` from
`options_config/init.lua`), so `register_diff_profile` was the one with no
caller at all and the command existed in no running session.

`wkdoptions/init.lua`'s `setup()` now calls it, alongside the other
standalone features (`qflist`, `indent_per_ft`) rather than from one of the
two subsystems, because a diff profile is neither a highlight nor an option.

Found by `:Bindings check` reporting it on both axes at once: present in the
source map, absent from `nvim_get_commands`. Neither axis could have found it
alone.

Verified after wiring: all four profiles rewrite `diffopt` as their table
says, `<Tab>` completion offers `context`/`minimal`/`review`/`strict`, and an
unknown name leaves `diffopt` untouched and reports through `notify.error`.

Two things that look like defects and are not. This config's default
`diffopt` is byte-for-byte the `review` profile, so `:WKDDiffProfile review`
on a fresh session changes nothing visible — that is the profile already
being active, not a no-op command. And an unknown name surfaces as a Vim
error when the command is driven from `vim.cmd`, because that is how
`nvim_exec2` reports an error-level message; typed interactively it is just
the notification.

One rough edge left as it is: the handler has a branch that lists the
profiles when called with no argument, but `nargs = 1` means Neovim rejects
the bare call with E471 first, so that branch is unreachable.

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
  defect: `:WKDDiffProfile` was defined but never registered, because
  `wkdoptions.commands.register`'s `register_diff_profile()` had no caller —
  the other three registrars in that module are each reached directly.
  `wkdoptions/init.lua` calls it now.
