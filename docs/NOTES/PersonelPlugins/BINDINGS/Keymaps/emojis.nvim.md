# emojis.nvim — Keymaps Cheatsheet

Source: `lua/emojis/bindings/keymaps.lua`, `M.bind_preset()`
Bridge: `lua/emojis/util/lib.lua`'s `lib.map()` — prefers `lib.nvim.map`, falls back to `vim.keymap.set`.
Cross-reference: `docs/BINDINGS.md`, `docs/keymaps.md` — both current and accurate.

Gated by `cfg.keymaps.preset == true` (checked in `bindings/init.lua`).

| lhs | mode | action | desc |
| --- | --- | --- | --- |
| `<C-e>` | n, i | Opens the emoji insert picker at cursor (telescope/fzf-lua if available, else `vim.ui.select`) | "emojis: insert picker" |
| `<leader>ee` | n | Opens the quick-insert overlay (frecency-ordered grid) | "emojis: quick-insert overlay" |
| `<leader>et` | n, x | Cycles the emoji checkbox on the cursor line, or every line in the visual range. In normal mode, a count extends the target to the next N lines from the cursor (`3<leader>et`, since 2026-07-31, clamped at EOF) — `vim.v.count1 == 1` (no prefix) is byte-identical to the prior single-line behavior. Visual-mode range is untouched (already covers this via the selection itself) | "emojis: toggle checkbox" |
| `<leader>ec` | n | Counts emojis in the buffer | "emojis: count buffer" |
| `<leader>el` | n | Lists emojis in buffer to quickfix | "emojis: list buffer" |

## which-key

`<leader>e` group label, registered when `keymaps.preset` is on and
which-key is installed (soft dependency, supports v2/v3 API). No individual
key labels needed — each mapping already carries its own `desc`.

## Notes

- These are opt-in preset keymaps binding directly onto the public API, no `<Plug>` indirection.

## Overlay grid: `/` filters (2026-08-24)

Buffer-local in both grid modes, alongside `h/j/k/l`, `<CR>`, `<Esc>`, `q`
and (in `grid_keys`) the per-cell hotkeys. `/` prompts for a filter and
re-renders with only the matching emojis; an empty query widens back. It
matches the shortcode and the glyph itself.

A prompt rather than a live input line, because the grid is a fixed-layout
hotkey surface — in `grid_keys` every printable key is already an insert
action, so an input line would make it a different widget. `/` is not a
hotkey.

Filtering re-opens the float instead of patching the buffer: the cell
byte-spans and the hotkey bindings are both derived from the item list.

The `<leader>et` count row above was already accurate here — the gap the
count audit flagged was in the plugin's own `docs/BINDINGS.md`, now fixed.
