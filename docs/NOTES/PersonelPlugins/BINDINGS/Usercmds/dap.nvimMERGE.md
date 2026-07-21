# dap.nvim — `:Dap <subcommand>` Cheatsheet

One command, built via `lib.nvim.usercmd.composer` (`<Tab>` completion on every
subcommand). Replaces the old flat `:DapContinue`/`:DapStepOver`/… commands
(fully removed, no alongside period).

Source: `lua/wkddap/bindings/usercmds/init.lua`
Docs: `docs/BINDINGS.md`, `docs/commands.md`, `doc/wkddap.txt`

Every default keymap has a 1:1 `:Dap` equivalent. Most subcommands are
zero-argument; `conditional-breakpoint` and `log-point` take an optional
trailing argument (prompt via `vim.fn.input()` when omitted).

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
| `:Dap repl` | Open REPL (`dap.repl.open()`, matches upstream nvim-dap's suggested mapping) |

## Notes

- Keymaps (`<leader>d…`, see `bindings/keymaps/init.lua`) call `dap.continue()` etc.
  **directly as Lua functions**, not through these commands — so keymaps were
  unaffected by the migration.
- CI (`.github/workflows/ci.yml`) runs luacheck, `stylua --check`, and a
  plenary test suite (`tests/`) covering registry bookkeeping, `:Dap` route
  registration/completion, `configurations` replace/append semantics, and
  helptags generation.
- Adapter + launch-config definitions for each language live together in
  `lua/wkddap/languages/<lang>.lua` (`setup()` + `load()`) — merged from the
  former separate `adapters/<lang>.lua` / `configurations/<lang>.lua` pair
  since the two were always in lockstep.
- `auto_install = true` now actually drives `:MasonInstall` for missing
  required adapters (previously a documented no-op); `configurations`
  overrides support `replace = true` for full replace instead of append-only.
