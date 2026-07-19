# mdview.nvim — `:MDView <subcommand>` Cheatsheet

One command, built via `lib.nvim.usercmd.composer` (`<Tab>` completion).
Replaces the old 10 flat `:MDViewX` commands (fully removed, no alongside
period). This was the **first** composer migration — the pilot for the whole
`lib.nvim.usercmd.composer` module.

Source: `lua/mdview/bindings/usrcmds/init.lua` + one action module per
subcommand (`start/`, `stop.lua`, `open.lua`, `toggle.lua`, `show_weblogs.lua`,
`preview_tab.lua`, `diagnose.lua`, `theme.lua`, `log.lua`, `file_log.lua`)
Docs: `docs/BINDINGS.md`, `docs/commands.md`, `README.md`, `doc/mdview.txt`

| Command | Effect |
| --- | --- |
| `:MDView start [file] [cwd=...]` | Start the relay + open the preview |
| `:MDView stop` | Stop the relay, detach autocommands |
| `:MDView toggle [file] [cwd=...]` | Start if stopped, stop if running |
| `:MDView open` | Re-open a browser tab against the running session |
| `:MDView theme [name]` | Switch preview theme (tab-completed) |
| `:MDView weblogs` | Show the relay's captured stdout |
| `:MDView log [level]` | Show internal log ring, optional level filter |
| `:MDView log export [path]` | Export the internal log ring to a file |
| `:MDView file-log` | Toggle persistent file logging, report state |
| `:MDView file-log on [path]` | Enable persistent file logging |
| `:MDView file-log off` | Disable persistent file logging |
| `:MDView file-log status` | Report file logging state |
| `:MDView file-log path [value]` | Set/report the file log path |
| `:MDView diagnose [path]` | Write a full diagnostics report and open it |

## Notes

- `start [file] [cwd=...]` and `toggle` use `ctx.rest` (composer's "leftover
  tokens" escape hatch) rather than a fixed positional schema, since `cwd=`
  can appear before or after the file arg — this is the pattern for any route
  whose grammar doesn't fit strict positional args (later formalized as
  Phase 6 flag support, motivated partly by this case and by `replacer.nvim`).
- `toggle` now calls `start`/`stop`'s functions **directly** (no more
  `vim.cmd("MDViewStart ...")` string round-trip).
- Found + fixed a pre-existing bug during verification: `:MDView log`
  (`show_in_scratch`) crashed with E95 on a second invocation in the same
  session (hardcoded scratch buffer name, no reuse/wipe guard). Flagged as a
  background task, fixed with a regression spec
  (`tests/nvim/log_scratch_spec.lua`) shortly after.
