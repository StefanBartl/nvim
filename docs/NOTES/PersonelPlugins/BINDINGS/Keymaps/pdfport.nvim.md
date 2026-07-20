# pdfport.nvim — Keymaps Cheatsheet

Source: `lua/pdfport_nvim/bindings/keymaps.lua`, `integrations/{nvim_tree,oil,netrw,neotree}.lua`
Cross-reference: `docs/BINDINGS.md` — verified accurate and current, no discrepancies.

Default actions (`bindings/keymaps.lua`), **not applied automatically** —
each file-tree integration must be explicitly set up, and each resolves its
own keymaps against `M.DEFAULTS` (any action disable-able via `false`):

| Action | Default lhs | desc |
| --- | --- | --- |
| `open` | `<leader>po` | "pdfport: mode picker" |
| `open_text` | `<leader>pt` | "pdfport: extract to buffer" |
| `open_system` | `<leader>ps` | "pdfport: open with system application" |
| `open_terminal` | `<leader>pi` | "pdfport: terminal image preview" |

## Per-integration, buffer-local, mode `n` (registered inside a `FileType` autocmd — see [Autocmds cheatsheet](../Autocmds/pdfport.nvim.md))

- **nvim-tree** (`integrations/nvim_tree.lua`) — the 4 actions above, each checking the node under cursor is a `.pdf` and dispatching to `picker.pick_and_open`/`pdfport_nvim.open` with a different `mode`. Only registered if `require("nvim-tree.api")` succeeds and the key isn't set to `false`.
- **oil.nvim** (`integrations/oil.lua`) — same 4 actions, resolving the oil.nvim cursor entry's path.
- **netrw** (`integrations/netrw.lua`) — same 4 actions; paths derived from `vim.b.netrw_curdir` + `<cfile>` since netrw has no Lua API.
- **neo-tree** (`integrations/neotree.lua`) — **does not call `vim.keymap.set` at all.** `M.keymaps()` instead returns a plain Lua table (`{ [lhs] = command_name }`) the user must merge into their own `neo-tree.setup({ filesystem = { window = { mappings = ... } } })` call.

## Which-key

`keymaps.register_which_key()`, called from every integration's `setup()` —
no-op unless which-key.nvim is installed; adds descriptive labels under a
`<leader>p` group via `wk.add`.

## Notes

- The floating text-preview window (`renderers/float.lua`) delegates to the external `lib.nvim.window.make_scratch` helper with `nice_quit = true`, which provides "q/`<Esc>`-to-close" — but that keymap lives in `lib.nvim`, not pdfport.nvim's own source. See [lib.nvim's cheatsheet](lib.nvim.md).
