# mdview.nvim — Keymaps Cheatsheet

**None.** Confirmed by a repo-wide search — no `vim.keymap.set`/
`nvim_set_keymap`/`nvim_buf_set_keymap` call anywhere under `lua/mdview/`.

`docs/BINDINGS.md` states this explicitly and suggests mapping
`:MDView start`/`:MDView stop` yourself, e.g.:

```lua
vim.keymap.set("n", "<leader>mv", "<Cmd>MDView start<CR>")
```

Cross-reference: `docs/BINDINGS.md` is the best-maintained doc among all
audited repos — correctly states "no keymaps" with this exact suggestion, no
corrections needed.
