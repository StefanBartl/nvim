# pickers.nvim — Autocmds Cheatsheet

Sources: `lua/pickers/bindings/autocmds.lua`, `plugin/pickers.lua`, `selected_index/init.lua`
Cross-reference: `docs/BINDINGS.md` documents the `VimEnter` fallback accurately, but is missing the `selected_index` overlay's three autocmds entirely.

## `VimEnter` fallback

Called from `plugin/pickers.lua` at plugin load time:

```lua
vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = callback })
```

`once = true`. Checks `vim.g.pickers_nvim_setup_called`; if the user never
called `require("pickers").setup()`, registers default keymaps/usercmds
using default config — covers the case where the user's config has no
`config = function() ... end` block, or the plugin loaded after `VimEnter`.
When `lib.nvim.autocmd` is available, the augroup is named `"pickers.nvim"`;
the raw-API fallback path doesn't set an explicit group.

## `selected_index` overlay — Telescope-only, per-picker-instance

Only created when `cfg.selected_index.enabled == true` or
`cfg.selected_index.toggle_key` is set (same gate as its keymaps — see
[Keymaps cheatsheet](../Keymaps/pickers.nvim.md)); only for the Telescope
engine. Augroup `"PickersSelectedIndexAUG_" .. results_bufnr` (unique per
picker instance, `clear = true`).

| Event(s) | Buffer (pattern) | Action |
| --- | --- | --- |
| `CursorMoved` | results buffer | Debounced (30ms) recompute + redraw of the selected-index overlay |
| `TextChangedI`, `TextChanged` | prompt buffer | Same debounced recompute — needed because typing in the prompt re-sorts results (changing the selected entry's rank) without firing `CursorMoved`; the debounce lets Telescope's async sort settle first |
| `BufDelete` (once, no explicit group) | results buffer | Cleans up the extmark namespace and cancels the debounce timer |
