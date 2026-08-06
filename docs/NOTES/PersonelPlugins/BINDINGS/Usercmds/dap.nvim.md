# dap.nvim — `:Dap <subcommand>` Cheatsheet

One command, built via `lib.nvim.usercmd.composer` (`<Tab>` completion on every
subcommand). Replaces the old flat `:DapContinue`/`:DapStepOver`/… commands
(fully removed, no alongside period).

Source: `lua/wkddap/bindings/usercmds/init.lua`
Docs: `docs/BINDINGS.md`, `docs/commands.md`, `doc/wkddap.txt` (`:h wkddap`, `:h wkddap-commands`)

All subcommands take zero arguments, except `conditional-breakpoint`/`log-point`
which take an optional trailing string (space-joined `ctx.rest`); when omitted
both prompt via `lib.nvim.ui.kit.input` (non-blocking, since 2026-08-06 — was
blocking `vim.fn.input` before).

| Command | Effect |
| --- | --- |
| `:Dap continue` | Continue |
| `:Dap step-over` | Step Over |
| `:Dap step-into` | Step Into |
| `:Dap step-out` | Step Out |
| `:Dap terminate` | Terminate |
| `:Dap restart` | Restart |
| `:Dap toggle-breakpoint` | Toggle Breakpoint |
| `:Dap conditional-breakpoint [condition]` | Conditional Breakpoint (prompts if `condition` omitted) |
| `:Dap log-point [message]` | Log Point (prompts if `message` omitted) |
| `:Dap list-breakpoints` | List Breakpoints |
| `:Dap toggle-ui` | Toggle UI (active panel provider: nvim-dap-view / nvim-dap-ui) |
| `:Dap eval` | Evaluate Expression (normal + visual) |
| `:Dap repl` | Open REPL |

## Notes

- Keymaps (`<leader>d…`, see `bindings/keymaps/init.lua`) call `dap.continue()` etc.
  **directly as Lua functions**, not through these commands — so keymaps were
  unaffected by the migration.
- CI (`.github/workflows/ci.yml`) runs stylua + luacheck + the headless
  plenary suite (`tests/wkddap/**`) on every push/PR — the "no CI" note this
  used to carry is stale, corrected 2026-08-06.
