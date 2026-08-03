# runtime-analysis.nvim — Keymaps Cheatsheet

**None.** Confirmed by a repo-wide search — no `vim.keymap.set`/
`nvim_set_keymap`/`nvim_buf_set_keymap` call anywhere under
`lua/runtime-analysis/`. Every entry point is one of the three commands
(`:RARequest`, `:RASend`, `:RATelemetry`) — see the
[Usercmds sheet](../Usercmds/runtime-analysis.nvim.md).

The repo's own `docs/BINDINGS.md` states this explicitly and gives the same
reasoning documentation.nvim's `:DocBrowse` keymap sheet gives for its own
*global* keymaps being zero: a request buffer's own edits are what drive
this plugin, not a keybinding. Unlike documentation.nvim, this plugin has no
buffer-local keymaps either (no scratch-buffer navigation UI to bind) — the
response split is `nomodifiable` and uses native Vim navigation only.

Worth binding yourself, e.g.:

```lua
vim.keymap.set("n", "<leader>rr", "<Cmd>RARequest<CR>")
vim.keymap.set("n", "<leader>rs", "<Cmd>RASend<CR>")
```
