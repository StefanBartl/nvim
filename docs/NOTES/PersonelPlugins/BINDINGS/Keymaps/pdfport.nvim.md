# pdfport.nvim — Keymaps Cheatsheet

Source: `lua/pdfport/bindings/keymaps.lua`, `integrations/{nvim_tree,oil,netrw,neotree}.lua`
Cross-reference: `docs/BINDINGS.md` — verified accurate and current, no discrepancies.

Default actions (`bindings/keymaps.lua`), **not applied automatically** —
each file-tree integration must be explicitly set up, and each resolves its
own keymaps against `M.DEFAULTS` (any action disable-able via `false`):

| Action | Default lhs | Mode | desc |
| --- | --- | --- | --- |
| `open` | `<leader>po` | n | "pdfport: mode picker" |
| `open_text` | `<leader>pt` | n | "pdfport: extract to buffer" |
| `open_system` | `<leader>ps` | n | "pdfport: open with system application" |
| `open_terminal` | `<leader>pi` | n | "pdfport: terminal image preview" |
| `open_batch` | `<leader>pb` | v | "pdfport: batch-open selected PDFs" |

`M.VISUAL_ACTIONS = { open_batch = true }` marks which actions are Visual-mode; everything
else is assumed Normal-mode by `M.register_which_key()` (2026-07 addition, for the
ROADMAP's "batch-opening multiple selected files" item).

## Per-integration, buffer-local (registered inside a `FileType` autocmd — see [Autocmds cheatsheet](../Autocmds/pdfport.nvim.md))

- **nvim-tree** (`integrations/nvim_tree.lua`) — the 4 normal-mode actions, each checking the node under cursor is a `.pdf` and dispatching to `picker.pick_and_open`/`pdfport.open` with a different `mode`, plus `open_batch` bound in mode `"v"` via the same `map()` wrapper (`mappings` table now carries a `mode` field per entry). Only registered if `require("nvim-tree.api")` succeeds and the key isn't set to `false`.
- **oil.nvim** (`integrations/oil.lua`) — same normal-mode actions, resolving the oil.nvim cursor entry's path, plus `open_batch` bound in mode `"v"`.
- **netrw** (`integrations/netrw.lua`) — same normal-mode actions; paths derived from `vim.b.netrw_curdir` + `<cfile>` since netrw has no Lua API; `open_batch` bound in mode `"v"`.
- **neo-tree** (`integrations/neotree.lua`) — **does not call `vim.keymap.set` at all.** `M.keymaps()` returns a plain Lua table (`{ [lhs] = command_name }`) for normal-mode entries, plus a nested `["v"] = { [lhs] = "pdfport_batch" }` sub-table for `open_batch` — neo-tree's documented per-mode `window.mappings` shape. The user must merge the returned table into `neo-tree.setup({ filesystem = { window = { mappings = ... } } })`.

## Batch-open (`open_batch`, visual mode only)

`lua/pdfport/util/batch.lua`'s `M.open_selected(resolve_path)`: walks the `'<`/`'>` visual
line range, moves the window cursor to each line, and calls the integration's *existing*
cursor-based `resolve_path` function unchanged (no new per-adapter "node at line N" API) —
collects every `.pdf` path found, then opens each (`mode = "buffer"`, `focus = false`, one
after another).

## Which-key

`keymaps.register_which_key()`, called from every integration's `setup()` —
no-op unless which-key.nvim is installed; adds descriptive labels under a
`<leader>p` group via `wk.add`, with `mode = "v"` for `open_batch` and `mode = "n"` for
everything else.

## Notes

- The floating text-preview window (`renderers/float.lua`) delegates to the external `lib.nvim.window.make_scratch` helper with `nice_quit = true`, which provides "q/`<Esc>`-to-close" — but that keymap lives in `lib.nvim`, not pdfport.nvim's own source. See [lib.nvim's cheatsheet](./lib.nvim.md).
