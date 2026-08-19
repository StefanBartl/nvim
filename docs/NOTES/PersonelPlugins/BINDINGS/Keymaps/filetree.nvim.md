# filetree.nvim — Keymaps Cheatsheet

Sources: ~40 files under `lua/filetree/features/<category>/<name>/init.lua`, each independently `setup(config, adapter)`-gated by its own `enabled` flag. Every feature registers its keymaps via `filetree.util.tree_attach.on_attach(fn)` — one central `FileType` autocmd (pattern `{"neo-tree","NvimTree"}` or the adapter's declared filetypes) dispatches to every feature's callback, deferred one tick so it runs after the adapter's own buffer-local keymaps. (As of 2026-07-26; previously each feature owned its own `FileType` autocmd and `compare/diff` was the sole `tree_attach` user — that inconsistency is now resolved.)

**⚠️ Doc gaps found**: `docs/BINDINGS/KEYMAPS.md` and the source catalog `lua/filetree/bindings/keymaps.lua` are both missing `pdf_open`'s keymaps entirely. The markdown doc also omits `reveal_alt` (`B`) and `markdown_links` (`ML`/`MR`/`MM`), which *are* present in the source catalog. Treat this file (and source) as authoritative over the doc.

Model: opt-out — every feature in `FEATURES` runs by default **except**
`cwd_sync`, `current_hl`, `safety`, `auto_resize` (opt-in).

## nav

| lhs | action | notes |
| --- | --- | --- |
| `-` | Set tree root to parent dir | `3-` climbs 3 levels (`vim.v.count1`, since 2026-07-31) |
| `+` | Set tree root to node under cursor | Both call adapter `set_root`, optionally sync cwd if `sync_cwd=true` |
| `B` | Reveal alternate buffer (`#`) in tree | default **on** |
| `<C-n>` | Next buffer in the adjacent editor window (`:bnext`, run via `nvim_win_call` so the tree keeps focus) | new `nav/buffer_cycle` feature, 2026-08-09 |
| `<C-p>` | Previous buffer in the adjacent editor window (`:bprevious`, same mechanism) | same feature |

## ui

| lhs | action | condition |
| --- | --- | --- |
| `<Tab>` | Toggle/open image/PDF viewer, else text/dir preview | |
| `<CR>` | Reads adapter's original `<CR>` first, wraps it: image/PDF → dispatch, else falls through | |
| `<C-b>`/`<C-f>`/`<PageUp>`/`<PageDown>` | Scroll float preview | `mode="float"` only; `vim.v.count1` multiplies the scroll amount (`5<C-f>` = 5 lines / 5×10 lines) since 2026-07-31 |
| `<PageUp>`/`<PageDown>` | Page buffer-mode preview (falls to native scroll if no preview active) | `mode="buffer"` (default); count is prefixed onto the native `:normal! N<C-f>` it delegates to (Neovim's own `<C-f>`/`<C-b>` already honor a leading count) rather than looped |
| `I` | Node info float (path/type/size/permissions/mtime/line-count, recursive dir scan capped at 100000 entries) | |
| `q`/`<Esc>` | Close node-info popup | always, once popup open |
| `w` | Cycle tree window width (`sizes={30,50,15}`) | With no count, single-step cycle (unchanged); with an explicit count N (`3w`), jumps directly to preset index N instead — a reachable-in-one-press shortcut a step-cycle alone can't express (since 2026-07-31) |
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
| `A` | Create-from-template: prompts for the filename FIRST, then opens a picker filtered to templates whose own extension matches it (falls back to the full list if none match or the name has no extension); substitutes `${filename}/${ext}/${date}/${author}/${module}/…` against the now-known destination | **was `t` before 2026-08-01** — reassigned as the `smart_create`/`a` counterpart. 11 built-in templates now ship with the plugin (lua ×2, typescript, javascript, go, rust, python, c, c++, csharp, wasm) alongside `stdpath("data")/filetree/templates/`; a same-named user template shadows a built-in |
| `<M-j>`/`<M-k>` | Move the highlighted template down/up in the picker (persisted to `.order.json` in the template dir) | Only while the picker's filter query is empty — no-op mid-filter (reordering isn't well-defined against a filtered subset) |
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
| `<leader>fm` | Open node's directory in OS file manager | `vim.ui.open` preferred, manual per-OS spawn fallback. `features.open_in_fm.debug=true` logs branch/argv/exit-code when a launch silently opens nothing; `reuse_existing=true` (Windows) navigates an already-open Explorer window instead of spawning another (added 2026-08-04) |
| `<leader>sm` (+ per-app `app.keymap`) | Open with OS default handler, or a configured custom app | |
| `<CR>`/`q`/`<Esc>` | Inside "open with" app picker | |
| `gp` (+ `keymap_text`/`keymap_system`/`keymap_terminal`, all off by default) | Dispatch PDF under cursor to pdfport.nvim (soft dep) — text view / OS viewer / terminal | **missing from `docs/BINDINGS/KEYMAPS.md` and the source catalog** |
| `gP` | Create PDF(s) from current node/marked nodes/folder via pdfport.nvim (soft dep); always confirms first via `filetree.util.confirm` | New 2026-08-09 (`pdf_create` feature) — write-direction counterpart to `gp`. One PDF per input file (not a merge); a folder expands to its direct child files only (non-recursive); files pdfport has no producer for are silently skipped and reported in the summary. Present in `docs/BINDINGS/KEYMAPS.md` and the source catalog (unlike `gp` above). |
| `i` | Prompt for a shell command, run it in a terminal split with `cwd` = node's directory | Known conflict with neo-tree's built-in `i` (toggle node info) — recommend noop via `adapter_keymaps` |

## compare

| lhs | action | notes |
| --- | --- | --- |
| `D` | Stage/diff current file: first press stages the node, second press opens a `vsplit` diff | Registered via `tree_attach.on_attach`, same as every other feature above |

## Adapter-level / plugin-wide

| lhs | action | condition |
| --- | --- | --- |
| any key in `cfg.adapter_keymaps` set to `false` | `<Nop>` (disable an adapter-native key) | `cfg.adapter_keymaps` is a table |
| any key in `cfg.adapter_keymaps` set to a string | Remap that key | same |
| `/` (neo-tree's `?` help popup) | Removed (`vim.keymap.del`) so native Vim search works there | `adapter.name == "neotree"` |
| `y`/`Y`/`<CR>` and `n`/`N`/`q`/`<Esc>` | Confirm/cancel a generic yes-no popup (used by e.g. trash confirm) | whenever `filetree.util.confirm(opts)` is invoked |

## which-key

`bindings/init.lua`'s `M.setup_which_key()` — only one group registered:
`<leader>m` → "filetree: marks" (`WK_GROUPS` table, currently a single
entry). Every other tree-buffer key already carries its own `desc`, so no
further groups are needed. Soft-guarded, no-op if which-key is absent.
Handles v3 (`wk.add`) and v2 (`wk.register`).

## ui (context_menu, new 2026-08-01, architecture settled same day)

| lhs | action | notes |
| --- | --- | --- |
| `<RightMouse>` | Opens a context menu via nvzone/menu, populated from `filetree.integrations.menu.items()` | **Sole right-click implementation for the tree**, left on filetree's default. Buffer-local, so it shadows `config/menu/mappings.lua`'s global `<RightMouse>` while inside the tree window |

**`config/menu/neotree/` deleted 2026-08-01** (`entries.lua` + `init.lua`) —
was dated 2026-02-02, referenced `config.neotree.keymaps.filesystem.*`
modules already removed by the filetree.nvim migration; was only ever reached
as a fallback in `neotree_menu_source()` when `filetree.integrations.menu`
was absent/empty, which it never was — dead code, deliberately removed
outright rather than fixed. `config/menu/mappings.lua`'s `neotree_menu_source()`
helper and the `ft == "neo-tree"` branch in its `<RightMouse>` handler were
removed too, for the same reason: filetree.nvim's own buffer-local binding
(above) always wins inside the tree now, so that branch's body could never
run. The global handler still covers markdown buffers, NvimTree, and
everything else non-tree — unaffected.

**Longer-term goal (stated, not yet built)**: move non-tree right-click
(markdown + general buffers) out of personal config into either a not-yet-
built custom UI plugin, or `buffer-ctx.nvim` — undecided as of 2026-08-01.

## Notes

- **2026-08-19**: New `fileops/link_create` feature (`:Filetree link` —
  see the Usercmds cheatsheet) has **no default keymap**, deliberately —
  `features.link_create.keymap` exists but is nil/off out of the box, same
  as `path_copy`'s format-picker key. Not a gap in this table.
- **2026-08-09**: New `nav/buffer_cycle` feature — `<C-n>`/`<C-p>` cycle the
  adjacent editor window's buffer (next/previous) while the tree keeps focus,
  mirroring what switching buffers would do if you were actually in that
  editor window. Reuses `filetree.util.buffer.find_editor_win()` (the same
  adjacent-window lookup `buffer_save`'s `<C-s>` uses) and runs
  `bnext`/`bprevious` via `nvim_win_call` — no focus change, no dependency on
  the adapter. Went through two default-key revisions same-day:
  `<S-Tab>`/`<M-Tab>` (original, unreliable in a terminal) →
  `<C-f>`/`<C-p>` (still bad — `<C-f>` turned out to collide with **neo-tree's
  own native default** `scroll_preview`, not just filetree's own
  float-mode preview scroll; confirmed live via
  `vim.api.nvim_buf_get_keymap(neotree_buf, "n")` against a real tree
  buffer, which listed `<C-F>`/`<C-B>` as neo-tree-bound even with no
  override in `config.neotree.keymaps*`) → `<C-n>`/`<C-p>`, verified absent
  from that same live dump (109 keys total in the real buffer). Lesson: for
  neo-tree specifically, a grep of filetree's own source isn't enough to
  clear a key — check `neo-tree.nvim/lua/neo-tree/defaults.lua`'s own
  `mappings` table too, or better, dump the live buffer's keymap.
- **Count support added 2026-07-31** for `-`/`+` (nav), `<C-b>`/`<C-f>`/`<PageUp>`/`<PageDown>` (preview scroll, both float and buffer mode), and `w` (window-size cycler, direct-index jump rather than a step multiplier — see the `ui` table above). None of these read a count before this date.
- **2026-08-09**: New `system/pdf_create` feature (default keymap `gP`) —
  turns the current node/marked nodes/a folder's direct child files into
  PDF(s) via pdfport.nvim's new `create()` API (soft dep, no-op with a
  warning if pdfport.nvim is absent or lacks `create()`). Always confirms
  via `filetree.util.confirm` (`lib.nvim.ui.kit.confirm`) before writing
  anything — single file gets a Yes/No, multiple files get a preview of the
  first few names. See `filetree.util.pdf.create()`/`guess_kind()`/
  `can_create()` and `docs/ROADMAP/PDFPORT_INTEGRATION.md`'s 2026-08-09
  addendum.
- **2026-08-01**: `create_from_template`'s default keymap changed `t` → `A`; the picker now prompts for the filename before the template (previously the other way round) so ${module} resolves against the real destination, and templates can be reordered in-picker with `<M-j>`/`<M-k>`. `${module}` itself now defers to `lib.nvim.lua_ls.get_module_path` (the same canonical resolver `lua_require_copy`/`rq` conceptually reimplements by hand — not migrated to it in this pass, flagged separately) rather than a locally-reinvented version.
- `bindings/keymaps.lua` itself has no live registration calls — it's a static catalog table consumed by `bindings/init.lua`'s `catalog()`, the cheatsheet feature, and the generated docs. It's missing a `pdf_open` entry (see above). **Caught drifting again 2026-08-01**: its `create_from_template` row still said `lhs = "t"` after the feature's own default moved to `"A"` — this catalog is hand-maintained, not derived from each feature's actual `_cfg.keymap`, so a code-level default change never propagates here automatically. Fixed upstream; worth remembering next time a default keymap changes.
