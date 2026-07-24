# mdview.nvim — Keymaps Cheatsheet

**None.** Confirmed by a repo-wide search — no `vim.keymap.set`/
`nvim_set_keymap`/`nvim_buf_set_keymap` call anywhere under `lua/mdview/`.

`docs/BINDINGS.md` states this explicitly and suggests mapping
`:MDView start`/`:MDView stop` yourself, e.g.:

```lua
vim.keymap.set("n", "<leader>mv", "<Cmd>MDView start<CR>")
```

### Worth binding: `:MDView sync toggle` (freeze scroll sync)

Quick freeze/unfreeze of the nvim→browser scroll sync — the fast way to look
something up in Neovim during a screen share **without the viewer seeing the
preview jump** (the preview stops receiving scroll pings while paused, and now
shows a small "⏸ scroll sync paused" pill in the tab):

```lua
vim.keymap.set("n", "<leader>ms", "<Cmd>MDView sync toggle<CR>",
  { desc = "mdview: freeze/unfreeze scroll sync" })
```

Cross-reference: `docs/BINDINGS.md` is the best-maintained doc among all
audited repos — correctly states "no keymaps" with this exact suggestion, no
corrections needed.
