# buffer-ctx.nvim — Keymaps Cheatsheet

Source: `lua/buffer_ctx/bindings/keymaps.lua` (core), `lua/buffer_ctx/mark/init.lua` (mark)
Bridge: `lua/buffer_ctx/util/map.lua` — upgrades to `lib.nvim.bindings.keymap` when
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
| `<S-m>` | n | `toggle` | Toggle mark on current line, or N lines with a count |
| `<C-p>` | n | `yank` | Yank all marked lines to clipboard |
| *(unset)* | n | `clear` | Remove every mark in the buffer |

**Count support (since 2026-08-24):** `3<S-m>` covers the cursor line and the
two below it, clamped to the end of the buffer. Without a count it is the
single-line toggle it always was.

Over a range this is deliberately **not** a per-line toggle — a partially
marked selection would come out as a checkerboard. If any line in the range
is unmarked (or marked in another category), the whole range gets marked;
only when every line already carries that category does it unmark.

**The `desc` changed** for `toggle`: now "[buffer-ctx] Mark: toggle line (or
N with a count)".

## which-key

`<leader>cn` is labelled as a group when which-key.nvim is installed
(`which_key = true`, default). No-op otherwise — `which_key` config only
controls the label, not whether the keymaps themselves are bound.

## Notes

- None of these keymaps have a `:Format` or `:Mark`-subcommand-picker
  equivalent — `column`/`enum`/etc. have no default keymap, only commands.
  Bind your own if wanted: `:Format column <N>` needs a visual selection
  first regardless of how it's invoked.
- `keymaps.clear` was added 2026-08-24 and is **unset by default**, so
  `<S-m>` and `<C-p>` remain the only two bound out of the box. There is
  still no keymap for the `BufferCtxMarkCleanup` autocmd, see
  [Autocmds cheatsheet](../Autocmds/buffer-ctx.md).
