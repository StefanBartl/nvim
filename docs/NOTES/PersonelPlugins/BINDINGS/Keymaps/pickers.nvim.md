# pickers.nvim — Keymaps Cheatsheet

Sources: `lua/pickers/bindings/keymaps.lua`, `bindings/collections.lua`, `selected_index/actions.lua`, `entry_actions/**`, `engines/fzf.lua`

**⚠️ `docs/BINDINGS.md`/`KEYMAPS.md`/`CHEATSHEET.md` all repeat only the 5
base keymaps below and share the same gaps** — none mention the
`selected_index` overlay keys, the `entry_actions` create-file/open-background
keys, or the fzf-lua terminal double-escape. Treat this file (and source) as
authoritative; the existing docs are a reliable base layer only for the
"Base default keymaps" table.

## 1. Base default keymaps

Registered via `bindings/util.lua`'s `map()` (prefers `lib.nvim.map`, else
`vim.keymap.set`). Condition: `cfg.keymaps.enable == true` (default on).
Registered from `setup()`, or — if the user never calls `setup()` — from a
`VimEnter` fallback (see [Autocmds cheatsheet](../Autocmds/pickers.nvim.md)).

| lhs (default) | action | desc |
| --- | --- | --- |
| `<leader>dp` | Dir-nav picker | "[pickers] Dir: navigate (alias / depth / path)" |
| `<leader>fb` | Find files in interactively picked folder | "[pickers] Find files in interactively picked folder" |
| `<leader>fc` | Find files in nvim config | "[pickers] Find files in nvim config" |
| `<leader>gc` | Grep in nvim config | "[pickers] Grep in nvim config" |
| `<leader>li` | Live grep in CWD | "[pickers] Live grep in CWD" |
| *(disabled by default)* `cwd_files` | Find files in CWD | "[pickers] Find files in CWD" |

## 2. Collection keymaps

`bindings/collections.lua` — only for user-configured `collections` entries
with a `keys.files`/`keys.grep` field (no default collections ship).

## 3. `selected_index` overlay — Telescope engine only

Attached only if `cfg.selected_index.enabled == true` **or**
`cfg.selected_index.toggle_key` is set (both inert by default). When active,
wraps every Telescope engine call (fzf-lua/snacks never get this feature).

| lhs | mode | action |
| --- | --- | --- |
| `<Down>` / `<C-n>` | i | Move selection next + refresh index overlay |
| `<Up>` / `<C-p>` | i | Move selection previous + refresh overlay |
| `j` / `<Down>` | n | Move selection next + refresh overlay |
| `k` / `<Up>` | n | Move selection previous + refresh overlay |
| `cfg.selected_index.toggle_key` (default unset) | i, n | Toggle overlay visibility + redraw |

## 4. `entry_actions` (create_file / open_background) — NOT auto-registered

`entry_actions/adapters/{telescope,fzf,snacks}.lua` each *build* a mapping
table (`get_mappings()`/`get_actions()`/`get_keys()`) but pickers.nvim does
**not** register it itself — the user must merge it into their own
`telescope.setup()`/`fzf-lua.setup()`/`snacks.setup()` call. Gated by
`cfg.entry_actions.enable` (default on).

| Action | Default key |
| --- | --- |
| `create_file` | `<C-a>` |
| `open_background` | `<S-CR>`, `<C-o>` |

fzf-lua's adapter hardcodes its `ctrl-a`/`ctrl-o`/`shift-enter` bindings
rather than translating the configured key strings — fzf's own action-table
key syntax can't be safely translated from Neovim keymap syntax.

## 5. fzf-lua terminal double-escape — auto-registered, buffer-local

`engines/fzf.lua`'s `setup_double_esc()`, wired into every fzf-lua call the
engine makes — automatic, no config flag.

| lhs | mode | action |
| --- | --- | --- |
| `<Esc>` | t | `<C-\><C-n>` — leave terminal-insert mode without killing fzf |
| `<Esc>` | n | Close the window (kills the fzf process via stdin close) |

fzf runs in a terminal buffer, so a naive single `<Esc>` would normally abort
fzf's input read — this two-step scheme is the workaround.

## Notes

- `lua/pickers/entry_actions/README.md` is itself accurate and up to date for the `entry_actions` subsystem specifically — good source to fold in, but not cross-linked from `docs/BINDINGS.md`.
