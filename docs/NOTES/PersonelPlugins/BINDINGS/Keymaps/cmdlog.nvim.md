# cmdlog — Keymaps Cheatsheet

No global/normal-mode keymaps **by default**. Since 2026-07-25, `setup()`
accepts an optional `keymaps` table (`{ [subcommand] = lhs }`, `""` for bare
`:Cmdlog`) that registers real normal-mode `vim.keymap.set` bindings for
`:Cmdlog <subcommand>` — see `docs/OPTIONS.md`. Not configured in this
config as of this writing (no `keymaps` passed to `setup()`), so the point
below still holds in practice: all *active* keymaps remain
prompt-buffer-local, inside picker `attach_mappings` — different per
backend (`config.options.picker`: `"telescope"` or `"fzf"`).

Cross-reference: `docs/BINDINGS.md` in the repo is now the source of truth
(added after this file was last written) and matches the tables below;
`README.md`'s "Shortcuts (inside pickers)" section is accurate for the
Telescope backend. `docs/ADD_PICKER.md` documents the extension pattern
for plugin authors, not end-user keys.

## which-key

Only relevant once the optional `keymaps` table above is actually
configured (not the case in this config currently) — those global bindings
get picked up by which-key.nvim's `add()` when installed, see
`lua/cmdlog/integrations/which_key.lua`. No-op if which-key is absent. The
prompt-buffer-local picker keys (Telescope/fzf-lua sections below) are not
which-key's domain — they live inside `attach_mappings`, not the global
keymap namespace.

## Telescope backend — shared module `lua/cmdlog/ui/mappings.lua`

Used by every picker except `favorites_picker`.

| lhs | mode | action |
| --- | --- | --- |
| `<CR>` | i | Closes picker, feeds the selected entry back into the command-line for editing (does **not** execute it) |
| `<Tab>` | i | Toggles favorite for the selected entry, closes + refreshes the picker |
| `<C-r>` | i | Closes + manually refreshes the picker |
| `<C-x>` | i | Deletes the selected entry — or, when entries are marked, every marked one — from its underlying history (Neovim `:` history via `histdel()`, or the shell history file with a confirmation prompt). Only bound where the caller passes a `delete_fn` — not in `favorites_picker` (`<Tab>` already removes a favorite there) |
| `<C-Space>` | i | Marks/unmarks the entry for a batch delete and moves down (`actions.toggle_selection` + `move_selection_worse`). Telescope's own multi-select key is `<Tab>`, which is `toggle_favorite` here, hence a separate key |
| `<C-s>` | i | Rotates to the next picker (nvim → shell → favorites → project → …), keeping the current prompt text. Implemented in `lua/cmdlog/ui/cycle.lua`, bound in `nvim`/`shell`/`favorites`/`project` pickers only. Telescope only. **Added 2026-08-09.** |
| `<C-z>` | i | Undoes the most recent favorite toggle (single-level, session-local). Bound wherever `<Tab>` is (any picker with `toggle_favorite`). **Added 2026-08-09.** |
| `<C-Up>` | i | Moves the selected favorite up one slot in the persisted order. Favorites picker only (`opts.reorder = true`). **Added 2026-08-09.** |
| `<C-Down>` | i | Moves the selected favorite down one slot in the persisted order. Favorites picker only. **Added 2026-08-09.** |

All eight are configurable/disableable via `setup({ mappings = { ... } })`
**Batch delete (since 2026-08-24):** a batch asks once ("Delete N selected
entries...") and then suppresses the per-command shell confirmation — five
marked entries would otherwise raise five separate prompts. With nothing
marked, `<C-x>` behaves exactly as before, single confirmation included.

The mappings call `delete_fn(cmd, on_done, opts)`. Neither history source has
that shape natively, and passing them through raw was a real bug fixed at the
same time: `history.delete_entry` is synchronous and returns a boolean, so the
callback never fired and the picker stayed open on a stale list;
`shell.delete_entry` is `(cmd, opts, on_done)`, so the callback landed in the
`opts` slot and `<C-x>` in the shell picker raised
`attempt to call local 'on_done' (a nil value)`. Each picker now wraps its
source in an adapter.

(`select`/`toggle_favorite`/`refresh`/`delete`/`cycle_source`/
`undo_favorite`/`move_favorite_up`/`move_favorite_down`, each
`string|false`), see `docs/OPTIONS.md`. A legend of the active ones is
generated from `config.options.mappings` and shown in the Telescope
prompt title (`ui/picker_utils.lua`'s `build_legend()`).

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
