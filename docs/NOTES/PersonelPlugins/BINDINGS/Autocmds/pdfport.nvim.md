# pdfport.nvim — Autocmds Cheatsheet

Source: `lua/pdfport/bindings/autocmds.lua`
Cross-reference: `docs/BINDINGS.md` — verified accurate and current, no discrepancies.

All autocmds go through one shared helper, `M.on_filetype(pattern,
augroup_name, callback)`:

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern  = pattern,
  group    = vim.api.nvim_create_augroup(augroup_name, { clear = true }),
  callback = function(ev) callback(ev.buf) end,
})
```

Centralizes the FileType-autocmd + augroup boilerplate used by the netrw,
oil.nvim, and nvim-tree integrations, so each registration is idempotent
(re-running `setup()` clears and re-creates its own augroup instead of
accumulating duplicate autocmds/keymaps).

| Pattern | Augroup name | Integration |
| --- | --- | --- |
| `"NvimTree"` | `pdfport_tree` | `integrations/nvim_tree.lua` |
| `"oil"` | `pdfport_oil` | `integrations/oil.lua` |
| `"netrw"` | `pdfport_netrw` | `integrations/netrw.lua` |

Each callback registers that integration's 4 keymaps buffer-locally — see
[Keymaps cheatsheet](../Keymaps/pdfport.nvim.md).

Neo-tree deliberately does **not** use this mechanism — it registers
commands/mappings declaratively via `opts.commands`/
`opts.filesystem.window.mappings` instead.

## Optional: `BufReadCmd *.pdf` (2026-07, ROADMAP item)

`M.register_bufreadcmd()` — NOT wired to `M.on_filetype`; registers a standalone
`BufReadCmd` (augroup `pdfport_bufreadcmd`, pattern `*.pdf`) directly via
`autocmd.create`. Opt-in: only called from `pdfport/init.lua`'s `M.setup()` when
`cfg.auto_open_on_read == true` (default `false`). Intercepts a direct `:e file.pdf`,
marks the auto-created buffer `nofile`/`bufhidden=wipe`/not modifiable, and
`vim.schedule`s `require("pdfport.util.picker").pick_and_open(path)` instead of loading
raw PDF bytes.

