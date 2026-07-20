# open.nvim — Keymaps Cheatsheet

**None registered by the plugin itself.** `setup()` only loads handler
modules and registers the `:Open` user command; no keymap calls exist
anywhere in `lua/open_nvim/`.

The only `vim.keymap.set(` occurrence in the whole repo is inside
`docs/BINDINGS.md` as a documentation example showing users how they could
map `:Open` themselves:

```lua
vim.keymap.set("n", "<leader>oo", "<Cmd>Open<CR>")
```

Cross-reference: `docs/BINDINGS.md` is accurate and current — explicitly
states "None. open.nvim ships with no default keymaps and no `keymaps`
config option," with the example above; also notes built-in keymap config
is only a "near-term idea" tracked in the roadmap (not yet implemented).
