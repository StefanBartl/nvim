# pdfport.nvim — Autocmds Cheatsheet

Source: `lua/pdfport_nvim/bindings/autocmds.lua`
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
| `"NvimTree"` | `pdfport_nvim_tree` | `integrations/nvim_tree.lua` |
| `"oil"` | `pdfport_oil` | `integrations/oil.lua` |
| `"netrw"` | `pdfport_netrw` | `integrations/netrw.lua` |

Each callback registers that integration's 4 keymaps buffer-locally — see
[Keymaps cheatsheet](../Keymaps/pdfport.nvim.md).

Neo-tree deliberately does **not** use this mechanism — it registers
commands/mappings declaratively via `opts.commands`/
`opts.filesystem.window.mappings` instead.
