# dap.nvim — Keymaps Cheatsheet

Source: `lua/dap_nvim/bindings/keymaps/init.lua`, `M.setup(opts)`
Cross-reference: `docs/BINDINGS.md` in this repo — verified accurate and complete.

No-op unless `opts.enable` (`config.keymaps.enable`, default on). Uses bare
`vim.keymap.set`, prefix `opts.prefix` (default `<leader>d`). Every mapping:
`desc = "[DAP] " .. d, silent = true`. Wired from `bindings/init.lua` inside a
`pcall`, since `keymaps.setup()` `require("dap")`s eagerly to bind functions
directly — a missing nvim-dap degrades gracefully instead of aborting the
rest of `setup()` (which-key/autocmds still get wired).

| lhs (after prefix) | mode | action | desc |
| --- | --- | --- | --- |
| `c` | n | `dap.continue` | "[DAP] Continue" |
| `s` | n | `dap.step_over` | "[DAP] Step Over" |
| `i` | n | `dap.step_into` | "[DAP] Step Into" |
| `o` | n | `dap.step_out` | "[DAP] Step Out" |
| `t` | n | `dap.terminate` | "[DAP] Terminate" |
| `r` | n | `dap.restart` | "[DAP] Restart" |
| `b` | n | `dap.toggle_breakpoint` | "[DAP] Toggle Breakpoint" |
| `B` | n | Prompt for a condition string, set a conditional breakpoint | "[DAP] Conditional Breakpoint" |
| `L` | n | Prompt for a log message, set a log point | "[DAP] Log Point" |
| `l` | n | `dap.list_breakpoints` | "[DAP] List Breakpoints" |
| `u` | n | Toggle the active panel UI (dap-view or dap-ui) | "[DAP] Toggle UI" |
| `e` | n | Evaluate expression under cursor | "[DAP] Evaluate Expression" |
| `e` | v | Evaluate selection | "[DAP] Evaluate Selection" |
| `R` | n | `dap.repl.open` | "[DAP] Open REPL" |

## which-key

`<leader>d` → "DAP" group label, only if which-key is installed and
`cfg.which_key.enable` (default on).

## Notes

- No other keymap registrations exist anywhere else in the repo (`ui/`, `adapters/`, `configurations/`, `core/` register none).
