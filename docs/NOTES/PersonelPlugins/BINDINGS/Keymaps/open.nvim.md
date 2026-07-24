# open.nvim — Keymaps Cheatsheet

**None registered by default**, but `setup()` now accepts an optional
`keymaps` table (added later — see below): `lua/open/bindings/keymaps.lua`
registers a fixed-target keymap for each key present in it.

```lua
require("open").setup({
  keymaps = {
    open_default = "<leader>oo",  -- :Open
    open_browser = "<leader>ob",  -- :Open browser
    open_manager = "<leader>of",  -- :Open filemanager
  },
})
```

An unrecognized `keymaps.*` key warns and registers nothing. Leaving
`keymaps` unset (the default) registers zero keymaps, same as before this
option existed.

The `vim.keymap.set(` example in `docs/BINDINGS.md` still works too — for
anything not covered by the three fixed targets above, map `:Open ...`
yourself:

```lua
vim.keymap.set("n", "<leader>oo", "<Cmd>Open<CR>")
```

Cross-reference: `docs/BINDINGS.md`'s Keymaps section now documents the
`keymaps` option (previously it only listed the manual `vim.keymap.set`
example and noted built-in keymap config as an unimplemented roadmap idea —
that idea has since shipped).
