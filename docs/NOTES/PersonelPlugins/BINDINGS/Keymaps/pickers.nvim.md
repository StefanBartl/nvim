# pickers.nvim — Keymaps Cheatsheet

Sources: `lua/pickers/bindings/keymaps.lua`, `bindings/collections.lua`, `selected_index/actions.lua`, `keys/**`, `entry_actions/**`, `engines/fzf.lua`

**⚠️ pickers.nvim's own `docs/BINDINGS.md`/`CHEATSHEET.md` still only list the
5 base keymaps and share the same gaps** — `docs/KEYMAPS.md` was updated
2026-07-22 and is now reasonably current (base table incl. the disabled
opt-ins, plus a full in-picker-keys section), but `BINDINGS.md`/
`CHEATSHEET.md` were not touched. None of the three mention the
`selected_index` overlay keys. Treat this file (and source) as authoritative
regardless.

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
| *(disabled by default)* `repos_files` | Pick a repo, then find files | "[pickers] Pick a repo, then find files" |
| *(disabled by default)* `repos_grep` | Pick a repo, then live grep | "[pickers] Pick a repo, then live grep" |
| *(disabled by default)* `system_files` | Systemwide fd search (prompts) | "[pickers] Systemwide fd search (prompts for query)" |
| *(disabled by default)* `cwd_smart` | Smart grep+find in CWD | "[pickers] Smart (grep + find) in CWD" |
| *(disabled by default)* `config_smart` | Smart grep+find in nvim config | "[pickers] Smart (grep + find) in nvim config" |
| *(disabled by default)* `folder_smart` | Smart grep+find in picked folder | "[pickers] Smart (grep + find) in interactively picked folder" |

`repos_files`/`repos_grep`/`system_files` added 2026-07-22 (closed the last
open ROADMAP.md keymaps item — previously command-only via `:RepoFiles`/
`:RepoGrep`/`:FindOnSystem`).

`cwd_smart`/`config_smart`/`folder_smart` added 2026-07-24 with the **smart
action** (combined grep + find files, merged and ranked — a third action
alongside `files`/`grep`). **This repo's own config now enables** `cwd_smart`
= `<leader>ss` and `config_smart` = `<leader>sc` (see
`lua/plugins/personal/init.lua`). See the pickers.nvim docs
(`docs/COMMANDS.md#the-smart-action`, `docs/CONFIGURATION.md#smart-combined-grep--find`,
`:help pickers-smart`) for the scorer/weights.

## 2. Collection keymaps

`bindings/collections.lua` — only for user-configured `collections` entries
with a `keys.files`/`keys.grep`/`keys.smart` field (no default collections
ship). `keys.smart` added 2026-07-24 with the smart action. This repo's config
sets it on the `notes` (`<leader>mns`) and `wkdbooks` (`<leader>wks`)
collections.

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

## 4. Unified `keys` namespace (`lua/pickers/keys/`) — as of 2026-07-22

**Config surface changed since the last pass through this file**:
`entry_actions.enable`/`entry_actions.keys.*` no longer exist —
`create_file`/`open_background` were absorbed into this same `keys` table
(breaking change), sharing one master `keys.enable` switch with everything
below. If you have old config using `entry_actions = {...}`, it silently
no-ops now; migrate to `keys = {...}`.

Two delivery models, split by whether the action is a built-in engine
function or pickers.nvim-specific logic:

**Patched globally** (every picker that engine opens, pickers.nvim's own
*and* native `:Pickers builtin` ones) — `preview_scroll_*`, `history_*`,
`preview_toggle`:

| Action | Default | telescope | fzf-lua | snacks |
| --- | --- | --- | --- | --- |
| `preview_scroll_down` | `<PageDown>` | patched | patched | export only¹ |
| `preview_scroll_up` | `<PageUp>` | patched | patched | export only¹ |
| `preview_scroll_left` | `<C-Left>` | patched | — (fzf gap) | export only¹ |
| `preview_scroll_right` | `<C-Right>` | patched | — (fzf gap) | export only¹ |
| `history_back` | `<C-p>` | patched | — (fzf-native, fixed) | export only¹ |
| `history_forward` | `<C-n>` | patched | — (fzf-native, fixed) | export only¹ |
| `preview_toggle` | *(off, opt-in)* | patched | native `<F4>`, not ours | native `<A-p>`, not ours |

¹ snacks: pickers.nvim doesn't own `Snacks.setup()`, so nothing is
auto-registered there — the user must merge
`require("pickers.keys").snacks_win()` into their own
`snacks.setup({ picker = { win = ... } })`. Telescope/fzf-lua are patched
automatically from `bindings.setup()` (fires on `setup()` *or* the
`VimEnter` fallback) via `pickers.keys.patch(cfg)`, deferred with
`vim.schedule()` for both engines (avoids forcing an eager
`require("telescope")`/`fzf-lua` load on every startup).

`preview_toggle` is opt-in (off by default) and telescope-only by design —
fzf-lua/snacks already ship it natively, so it's deliberately excluded from
their lookup tables (would otherwise try to bind a nonexistent action name
on snacks, since its native name is `toggle_preview`, reversed word order).

**NOT patched globally, merge-it-yourself** — `create_file`,
`open_background` (this is genuinely pickers.nvim logic — `pickers.entry_actions.*`,
not a built-in engine action):

| Action | Default key |
| --- | --- |
| `create_file` | `<C-a>` |
| `open_background` | `<S-CR>`, `<C-o>` |

`entry_actions/adapters/{telescope,fzf,snacks}.lua` each *build* a mapping
table (`get_mappings()`/`get_actions()`/`get_keys()`) by calling
`require("pickers.keys").resolve()` — pickers.nvim does **not** register it
itself, same as before the config moved. fzf-lua's adapter hardcodes its
`ctrl-a`/`ctrl-o`/`shift-enter` bindings rather than translating the
configured key strings — fzf's own action-table key syntax can't be safely
translated from Neovim keymap syntax; only `keys.enable` (not per-action) is
honoured there.

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

- `lua/pickers/entry_actions/README.md` and `lua/pickers/keys/`'s own module
  `@brief` are themselves accurate and up to date — good source to fold in,
  but not cross-linked from `docs/BINDINGS.md`.
- `:Pickers builtin <name>` (51-entry registry of native picker-engine
  functions — git/LSP/help/vim-intrinsics/diagnostics/…) is a *command*, not
  a keymap — see the [Usercmds cheatsheet](../Usercmds/pickers.nvim.md).
  None of its entries ship a default keymap; bind your own via
  `builtin("name")`-style wrappers if you want one (see the user config's
  `config/snacks/mappings/standard.lua` for the pattern this repo's own
  config uses).
