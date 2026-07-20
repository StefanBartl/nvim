# dap.nvim — Autocmds Cheatsheet

Source: `lua/dap_nvim/bindings/autocmds/init.lua`, `M.setup(opts)`
Cross-reference: `docs/BINDINGS.md` — verified accurate and complete.

No-op unless `opts.enable` (`config.autocmds.enable`, default on). Augroup
`DapNvimAuto` (`clear=true`). Only nvim-dap-ui emits the `DapUIWindowOpen`/
`DapUIWindowClose` `User` events these rely on, so both are inert when the
default `dap-view` provider is active (`config/DEFAULTS.lua`'s `ui.provider`
default).

| Event | Pattern | Action |
| --- | --- | --- |
| `User` | `DapUIWindowOpen` | Sets `vim.wo.cursorline = true` for the current window |
| `User` | `DapUIWindowClose` | Sets `vim.wo.cursorline = false` |

No other autocmd registrations exist anywhere else in the repo.
