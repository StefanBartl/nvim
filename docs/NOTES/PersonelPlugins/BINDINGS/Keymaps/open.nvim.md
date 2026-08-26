# open.nvim — Keymaps Cheatsheet

**None registered by default**, but `setup()` now accepts an optional
`keymaps` table (added later — see below): `lua/open/bindings/keymaps.lua`
registers a fixed-target keymap for each key present in it.

```lua
require("open").setup({
  keymaps = {
    open_default  = "<leader>oo",  -- :Open
    open_browser  = "<leader>ob",  -- :Open browser
    open_manager  = "<leader>of",  -- :Open filemanager
    open_split    = "<leader>os",  -- :Open split
    open_terminal = "<leader>ot",  -- :Open terminal
  },
})
```

Since 2026-08-24 the accepted keys are derived from the **live handler
registry**, not from a hardcoded list: `open_<handler key>` works for every
registered handler (`split`, `vsplit`, `tab`, `terminal`, `image`,
`notepad`, `filemanager`, `browser`, the named browsers `open_firefox` /
`open_chrome` / ..., and anything added via `custom_handlers`).
`open_manager` remains a historical alias of `open_filemanager`, and
`open_default` still means the bare `:Open` despite the registry having its
own `default` handler.

**desc:** the command the mapping runs, e.g. `"open.nvim: :Open split"`,
`"open.nvim: :Open"` for the bare one. Previously it was the config key name
(`"open.nvim: open_browser"`) — anything matching on the old form needs
updating. Registration goes through `lib.nvim.map` now, not
`vim.keymap.set`.

An unrecognized `keymaps.*` key warns, names the accepted keys, and registers
nothing; a handler switched off via `opts.handlers` is rejected the same way
rather than mapped to a command that would fail when pressed. Leaving
`keymaps` unset (the default) registers zero keymaps, same as before this
option existed.

The `vim.keymap.set(` example in `docs/BINDINGS.md` still works too — these
are *fixed* invocations, so a keymap for `:Open split zshrc` specifically
still needs:

```lua
vim.keymap.set("n", "<leader>oo", "<Cmd>Open<CR>")
```

Cross-reference: `docs/BINDINGS.md`'s Keymaps section now documents the
`keymaps` option (previously it only listed the manual `vim.keymap.set`
example and noted built-in keymap config as an unimplemented roadmap idea —
that idea has since shipped).

## Notes

- No which-key integration — confirmed against source: no `which_key`/
  `which-key` reference anywhere in `lua/open/`. `<leader>o` is a shared
  prefix across the configured keys, so there'd be something real to
  group-label if this plugin grows a which-key module later — more so now
  that the number of mappable targets went from three to the whole handler
  registry.
