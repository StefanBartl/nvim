# filetree.nvim — Keymaps Cheatsheet

Sources: ~40 files under `lua/filetree/features/<category>/<name>/init.lua`, each independently `setup(config, adapter)`-gated by its own `enabled` flag. Almost every feature registers its own `FileType` autocmd (pattern `{"neo-tree","NvimTree"}` or the adapter's declared filetypes) via `filetree.util.map`/`filetree.util.autocmd`, deferred one tick so it runs after the adapter's own buffer-local keymaps. `compare/diff` is the one exception, routed through the centralized `filetree.util.tree_attach` dispatcher instead of its own autocmd.

**⚠️ Doc gaps found**: `docs/BINDINGS/KEYMAPS.md` and the source catalog `lua/filetree/bindings/keymaps.lua` are both missing `pdf_open`'s keymaps entirely. The markdown doc also omits `reveal_alt` (`B`) and `markdown_links` (`ML`/`MR`/`MM`), which *are* present in the source catalog. Treat this file (and source) as authoritative over the doc.

Model: opt-out — every feature in `FEATURES` runs by default **except**
`cwd_sync`, `current_hl`, `safety`, `auto_resize` (opt-in).

## nav

| lhs | action | notes |
| --- | --- | --- |
| `-` | Set tree root to parent dir | |
| `+` | Set tree root to node under cursor | Both call adapter `set_root`, optionally sync cwd if `sync_cwd=true` |
| `B` | Reveal alternate buffer (`#`) in tree | default **on** |

## ui

| lhs | action | condition |
| --- | --- | --- |
| `<Tab>` | Toggle/open image/PDF viewer, else text/dir preview | |
| `<CR>` | Reads adapter's original `<CR>` first, wraps it: image/PDF → dispatch, else falls through | |
| `<C-b>`/`<C-f>`/`<PageUp>`/`<PageDown>` | Scroll float preview | `mode="float"` only |
| `<PageUp>`/`<PageDown>` | Page buffer-mode preview (falls to native scroll if no preview active) | `mode="buffer"` (default) |
| `I` | Node info float (path/type/size/permissions/mtime/line-count, recursive dir scan capped at 100000 entries) | |
| `q`/`<Esc>` | Close node-info popup | always, once popup open |
| `w` | Cycle tree window width (`sizes={30,50,15}`) | |
| `<Esc>` | Reset tree UI state (preview, filter dim, live-search dim, watcher-quarantine, `:nohlsearch`) — each step pcall-guarded | |
| `?` | Floating keymap cheatsheet (filtered to enabled features) | **non-neotree adapters only** — neo-tree gets this natively via `attach.lua`'s injection into its own `?` |
| `q`/`<Esc>` | Close cheatsheet popup | |

## fileops

| lhs | action | notes |
| --- | --- | --- |
| `a` | Smart-create: prompt for name, create file/dir | optional `@module`/`@meta` header injection, clipboard-paste offer, auto `init.lua` for new dirs (all opt-in, default off) |
| `c`/`x`/`p`/`P`/`<C-c>` | Stage-copy / stage-cut / paste / show clipboard / clear clipboard | paste does real fs copy or `uv.fs_rename` move + buffer relocation + optional markdown-ref-update chooser |
| first char of a 2-char copy/cut key | `<Nop>` | Workaround: neo-tree's own single-char maps are `nowait=true`, which wins the ambiguity race against a 2-char sequence; re-binding the bare prefix as non-`nowait` `<Nop>` restores "wait for more input" |
| `<leader>rb` | Batch rename: scratch buffer listing visible nodes, `:w` diffs+executes renames | conflict detection, dry-run, safety-backup, markdown-ref-update chooser. Deliberately not `R` — left for neo-tree's native refresh |
| `r` | LSP-aware rename (`willRenameFiles`/`didRenameFiles`), falls back to project-wide textual require()/import rewrite when no LSP handled it (e.g. always for Lua — `lua_ls` never advertises this capability) | plus markdown-ref chooser |
| `d`/`U`/`<leader>th` | Trash current node (or batch chooser for marked nodes) / undo last trash / show trash history | `confirm=true` default deliberately differs from copy_move/rename_batch's `false`, since trash is easier to mis-click |
| `q`/`<Esc>` | Close trash-history popup | |
| `t` | Create-from-template picker (files under `stdpath("data")/filetree/templates/`), substitutes `${filename}/${ext}/${date}/${author}/${module}/…` | |
| `<CR>`, `q`, `<Esc>`, `1-9` | Select/close/quick-pick inside template picker | |
| `O` | Open node with `:edit` in last-focused editor window (replaces that buffer) | optionally closes tree after (`close_tree`, default true) |
| `sg`/`sv`/`st`/`gb`/`<S-CR>` | Open in vsplit/split/new tab; `gb`/`<S-CR>` add to buffer list without switching | |
| `<C-s>` | Force-save last-focused adjacent editor buffer | `write!` by default, or `update` if `force=false` |
| `<M-s>` | Force-save buffer matching node under cursor | |

## search

| lhs | action | notes |
| --- | --- | --- |
| `/` / `<C-c>` | Enter live-filter mode / clear filter | adapter-native filter API preferred, extmark-dim fallback |
| `<CR>` / `<Esc>` | Commit / cancel filter input | while input open |
| `gs` | Live search: floating input bar with real-time dim/highlight overlay | |
| `<Esc>`, `<C-c>` / `<CR>` | Cancel / commit live-search query | commit optionally hands the pattern to `filter` if `commit_to_filter=true` |
| `f` / `tf` | Find files (auto-detect telescope→fzf-lua→mini.pick→built-in fallback) / force telescope specifically | rooted at node dir/project root/cwd |
| `keymap_global` (unset by default) | Same as `f` but global, not buffer-local | only if user sets it |
| `gr` / `keymap_cword` (unset) / `tg` | Grep in node's directory / grep `<cword>` / force telescope | telescope/fzf-lua/ripgrep-or-grep→quickfix |

## paths

| lhs | action |
| --- | --- |
| `[a`/`]a`/`[R`/`]R` | Copy absolute path / parent dir / project root / path relative to project root |
| `<CR>`/`q`/`<Esc>` | Inside the format-picker popup |
| `rq` | Copy as `require('module.path')` (walks up to nearest `lua/` root; recursive for dirs) |
| `[f`/`]f`/`[F`/`]F` | Copy recursive file/dir lists (absolute/relative) |
| `ML`/`MR`/`MM` | Copy `[name](path)` markdown link — current node / recursively / from all marked nodes |

## org

| lhs | action |
| --- | --- |
| `m`/`]m`/`[m`/`<C-m>`/`<leader>ms` | Toggle mark / mark all visible / unmark all visible / clear all / show floating list of marked paths |
| `q`/`<Esc>` | Close marked-nodes popup |

`org/session` has no keymaps (autocmd + `:Filetree` subcommands only).

## system

| lhs | action | notes |
| --- | --- | --- |
| `<leader>fm` | Open node's directory in OS file manager | `vim.ui.open` preferred, manual per-OS spawn fallback |
| `<leader>sm` (+ per-app `app.keymap`) | Open with OS default handler, or a configured custom app | |
| `<CR>`/`q`/`<Esc>` | Inside "open with" app picker | |
| `gp` (+ `keymap_text`/`keymap_system`/`keymap_terminal`, all off by default) | Dispatch PDF under cursor to pdfport.nvim (soft dep) — text view / OS viewer / terminal | **missing from `docs/BINDINGS/KEYMAPS.md` and the source catalog** |
| `i` | Prompt for a shell command, run it in a terminal split with `cwd` = node's directory | Known conflict with neo-tree's built-in `i` (toggle node info) — recommend noop via `adapter_keymaps` |

## compare

| lhs | action | notes |
| --- | --- | --- |
| `D` | Stage/diff current file: first press stages the node, second press opens a `vsplit` diff | Registered via the centralized `tree_attach.on_attach` dispatcher, unlike every other feature above |

## Adapter-level / plugin-wide

| lhs | action | condition |
| --- | --- | --- |
| any key in `cfg.adapter_keymaps` set to `false` | `<Nop>` (disable an adapter-native key) | `cfg.adapter_keymaps` is a table |
| any key in `cfg.adapter_keymaps` set to a string | Remap that key | same |
| `/` (neo-tree's `?` help popup) | Removed (`vim.keymap.del`) so native Vim search works there | `adapter.name == "neotree"` |
| `y`/`Y`/`<CR>` and `n`/`N`/`q`/`<Esc>` | Confirm/cancel a generic yes-no popup (used by e.g. trash confirm) | whenever `filetree.util.confirm(opts)` is invoked |

## Notes

- `bindings/keymaps.lua` itself has no live registration calls — it's a static catalog table consumed by `bindings/init.lua`'s `catalog()`, the cheatsheet feature, and the generated docs. It's missing a `pdf_open` entry (see above).
