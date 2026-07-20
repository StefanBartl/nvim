# nvim-cmdlog — Keymaps Cheatsheet

No global/normal-mode keymaps. All keymaps are **prompt-buffer-local, inside
picker `attach_mappings`** — different per backend (`config.options.picker`:
`"telescope"` or `"fzf"`).

Cross-reference: no `docs/BINDINGS.md`. `README.md`'s "Shortcuts (inside
pickers)" section is accurate for the Telescope backend but incomplete (see
Notes below); `docs/ADD_PICKER.md` documents the extension pattern for
plugin authors, not end-user keys.

## Telescope backend — shared module `lua/cmdlog/ui/mappings.lua`

Used by every picker except `favorites_picker`.

| lhs | mode | action |
| --- | --- | --- |
| `<CR>` | i | Closes picker, feeds the selected entry back into the command-line for editing (does **not** execute it) |
| `<Tab>` | i | Toggles favorite for the selected entry, closes + refreshes the picker |
| `<C-r>` | i | Closes + manually refreshes the picker |

`lua/cmdlog/ui/favorites_picker.lua` has its own inline `attach_mappings`
duplicating the `<CR>`/`<Tab>` behavior above rather than reusing
`mappings.lua`.

## fzf-lua backend

| lhs | picker(s) | action |
| --- | --- | --- |
| `default` (`<CR>`) | all except `favorites` | Executes the command directly (`vim.cmd(selected[1])`) — **differs from Telescope's insert-only `<CR>`** |
| `ctrl-f` | `favorites` picker only | Toggles favorite, reopens the picker |

Under fzf-lua, only the dedicated `:Cmdlog favorites` picker gets a
favorite-toggle key — the other five pickers (`all`, `all-unique`, `nvim`,
`nvim-full`, `shell`, `shell-full`) get none.

## Notes

- A comment on `ui/mappings.lua:2` (`--- Handles <CR> to execute, <C-f> to toggle favorite, <C-r> to refresh`) is **stale/inaccurate**: actual bindings are `<CR>` (insert, not execute) and `<Tab>` (not `<C-f>`) for favorites — `<C-f>` only exists in the fzf-lua backend's actions table.
- No conditional flags gate these beyond the `picker` config option — no "enable keymaps" toggle exists.
