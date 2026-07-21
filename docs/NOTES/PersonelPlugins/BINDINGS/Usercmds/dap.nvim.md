# dap.nvim — `:Dap <subcommand>` Cheatsheet

One command, built via `lib.nvim.usercmd.composer` (`<Tab>` completion on every
subcommand). Replaces the old flat `:DapContinue`/`:DapStepOver`/… commands
(fully removed, no alongside period).

Source: `lua/wkddap/bindings/usercmds/init.lua`
Docs: `docs/BINDINGS.md`, `docs/commands.md`, `doc/dap.txt`

All subcommands are zero-argument.

| Command | Effect |
| --- | --- |
| `:Dap continue` | Continue |
| `:Dap step-over` | Step Over |
| `:Dap step-into` | Step Into |
| `:Dap step-out` | Step Out |
| `:Dap terminate` | Terminate |
| `:Dap restart` | Restart |
| `:Dap toggle-breakpoint` | Toggle Breakpoint |
| `:Dap list-breakpoints` | List Breakpoints |
| `:Dap toggle-ui` | Toggle UI (active panel provider: nvim-dap-view / nvim-dap-ui) |
| `:Dap eval` | Evaluate Expression (normal + visual) |

## Notes

- Keymaps (`<leader>d…`, see `bindings/keymaps.lua`) call `dap.continue()` etc.
  **directly as Lua functions**, not through these commands — so keymaps were
  unaffected by the migration.
- No CI test suite existed for this repo, so no CI wiring was needed.
