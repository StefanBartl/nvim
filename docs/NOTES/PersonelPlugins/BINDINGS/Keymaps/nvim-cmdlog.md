# cmdlog — Keymaps Cheatsheet

No global/normal-mode keymaps **by default**. Since 2026-07-25, `setup()`
accepts an optional `keymaps` table (`{ [subcommand] = lhs }`, `""` for bare
`:Cmdlog`) that registers real normal-mode `vim.keymap.set` bindings for
`:Cmdlog <subcommand>`, picked up by which-key.nvim's `add()` when it's
installed — see `lua/cmdlog/integrations/which_key.lua` and
`docs/OPTIONS.md`. Not configured in this config as of this writing (no
`keymaps` passed to `setup()`), so the point below still holds in practice:
all *active* keymaps remain prompt-buffer-local, inside picker
`attach_mappings` — different per backend (`config.options.picker`:
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
duplicating the `<CR>`/`<Tab>` behavior above, plus one addition (since
2026-07-25): `<C-t>` prompts (`vim.ui.input`) for a tag and attaches it to
the selected favorite via `core/tags.lua`, then refreshes the picker.
Tags are stored separately from `favorites.json` and shown next to each
favorite's entry. Not present in the shared `mappings.lua`, so only the
favorites picker has it.

## fzf-lua backend

| lhs | picker(s) | action |
| --- | --- | --- |
| `default` (`<CR>`) | all except `favorites` | Executes the command directly (`vim.cmd(selected[1])`) — **differs from Telescope's insert-only `<CR>`** |
| `ctrl-f` | `favorites` picker only | Toggles favorite, reopens the picker |
| `ctrl-t` | `favorites` picker only | Prompts for a tag (`vim.ui.input`) and attaches it to the selected favorite (since 2026-07-25) |

Under fzf-lua, only the dedicated `:Cmdlog favorites` picker gets a
favorite-toggle/tag key — the other nine pickers (`all`, `all-unique`,
`nvim`, `nvim-full`, `shell`, `shell-full`, `project`, `lua`, `stats`) get
none. Known-error highlighting (`core/errors.lua`, since 2026-07-25) is
Telescope-only for the same reason `ctrl-f`/`ctrl-t` are favorites-only:
fzf-lua entries double as the value fed back into `actions`, so decorating
them risks corrupting `vim.cmd(selected[1])`.

## Notes

- A comment on `ui/mappings.lua:2` (`--- Handles <CR> to execute, <C-f> to toggle favorite, <C-r> to refresh`) is **stale/inaccurate**: actual bindings are `<CR>` (insert, not execute) and `<Tab>` (not `<C-f>`) for favorites — `<C-f>` only exists in the fzf-lua backend's actions table.
- No conditional flags gate these beyond the `picker` config option — no "enable keymaps" toggle exists.
