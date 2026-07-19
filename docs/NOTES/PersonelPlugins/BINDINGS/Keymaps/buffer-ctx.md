# buffer-ctx.nvim — Keymaps Cheatsheet

Source: `lua/buffer_ctx/bindings/keymaps.lua` (core), `lua/buffer_ctx/mark/init.lua` (mark)
Bridge: `lua/buffer_ctx/util/map.lua` — upgrades to `lib.nvim.map` when
lib.nvim is installed, falls back to plain `vim.keymap.set` otherwise; both
paths register identical `lhs`/`desc`/`silent`/`noremap`.

All keymaps are individually configurable or fully disabled via
`require("buffer_ctx").setup({ keymaps = ..., mark = { keymaps = ... } })`.
Set `keymaps = false` / `mark = { keymaps = false }` to disable a whole group.

## Core

| lhs | mode | opt key | action |
| --- | --- | --- | --- |
| `<leader>cnl` | n | `location_copy` | Copy `path:line` (cwd-relative) |
| `<leader>cnm` | n | `module_copy` | Copy Lua module path |
| `<leader>cnf` | n | `filepath_copy` | Copy filepath (cwd-relative, unix) |

## Mark

| lhs | mode | opt key | action |
| --- | --- | --- | --- |
| `<S-m>` | n | `toggle` | Toggle mark on current line |
| `<C-p>` | n | `yank` | Yank all marked lines to clipboard |

## which-key

`<leader>cn` is labelled as a group when which-key.nvim is installed
(`which_key = true`, default). No-op otherwise — `which_key` config only
controls the label, not whether the keymaps themselves are bound.

## Notes

- None of these keymaps have a `:Format` or `:Mark`-subcommand-picker
  equivalent — `column`/`enum`/etc. have no default keymap, only commands.
  Bind your own if wanted: `:Format column <N>` needs a visual selection
  first regardless of how it's invoked.
- `<S-m>` and `<C-p>` are the only two mark keymaps; there is no keymap for
  clearing all marks in a buffer (only per-line `toggle`) or for the
  `BufferCtxMarkCleanup` autocmd, see [Autocmds cheatsheet](../Autocmds/buffer-ctx.md).
