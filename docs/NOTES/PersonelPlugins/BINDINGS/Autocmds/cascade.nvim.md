# cascade.nvim — Autocmds Cheatsheet

Source: `lua/cascade/bindings/autocmds.lua`, `M.setup(cfg)`
Cross-reference: `docs/BINDINGS.md` in this repo — verified current and accurate.

Both augroups are always created with `clear = true` (idempotent re-setup).

| Event(s) | Augroup | Pattern | Condition | Action |
| --- | --- | --- | --- | --- |
| `FileType` | `cascade_list_keymaps` | `cfg.lists.filetypes` | `cfg.keymaps.preset` AND `cfg.lists.enable` AND filetypes non-empty | Binds all buffer-local list keymaps for that buffer |
| `FileType` | `cascade_list_format` | `cfg.lists.filetypes` | `cfg.lists.enable` AND filetypes non-empty (independent of `keymaps.preset`) | Sets buffer-local `formatlistpat`/`formatoptions` (from `lists.continue.hanging_indent`) so `gq`/auto-wrap hang-indents a wrapped list item |
| `BufWritePre` | `cascade_renumber_save` | `*` | `lists.enable` and `"save"` is a configured `lists.renumber.on` trigger | Renumbers ordered lists before write (only if buffer is writable and its filetype is in `lists.filetypes`) |

## Details

- **`FileType`/`cascade_list_keymaps`**: also immediately calls `bind_list_buffer()` once at setup time if the *currently open* buffer's filetype already matches — covers buffers already open when `setup()` runs, not just ones opened afterward.
- **`FileType`/`cascade_list_format`**: same "cover already-open buffers" behavior as `cascade_list_keymaps`, but registered unconditionally (not gated by `keymaps.preset`) since it's a `lists` behavior, not a keymap one.
- **`BufWritePre`/`cascade_renumber_save`**: re-checks its own enable condition live inside the callback (not just at registration time), and wraps the renumber call in `pcall` so a renumbering bug can't block a save.
