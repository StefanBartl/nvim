# color_my_ascii.nvim — Autocmds Cheatsheet

Sources: `lua/color_my_ascii/bindings/autocmds.lua`, `init.lua`,
`api/fences.lua`, `commands/fence/open.lua`, `commands/schemes.lua`,
`debounce_manager.lua`.

**⚠️ `docs/BINDINGS.md`'s Autocommands section is stale** — it lists only 2 of
the 7 actual autocmd registrations below. This file reflects source, not that doc.

| Event(s) | Augroup | Pattern/Buffer | Action | In `docs/BINDINGS.md`? |
| --- | --- | --- | --- | --- |
| `FileType` | `ColorMyAscii` | `markdown` | Sets up per-buffer highlighting + registers the buffer-local `:Fence` command family | Yes |
| `ColorScheme` | `ColorMyAsciiFenceLineHl` | `*` | Re-resolves `fence_line_highlight`/`fence_content_highlight` groups after a colorscheme change | **No** |
| `TextChanged`, `TextChangedI` | `ColorMyAsciiBuffer_<bufnr>` | buffer-local | Re-highlights via adaptive debounce | Yes |
| `BufDelete` | `ColorMyAsciiBuffer_<bufnr>` | buffer-local | Clears highlighter state, fence_hl, cache; cancels debounce timer | Yes |
| `BufDelete`, `BufWipeout` | `ColorMyAsciiFenceApiCache` | `*` | Invalidates the fences-API range-cache entry for the deleted buffer (consumed by other plugins, e.g. markdown.nvim) | **No** |
| `BufWritePost` | `ColorMyAsciiFenceOpen_<tbuf>` | buffer-local (temp scratch buf) | Syncs edited fence content back into the source buffer | **No** |
| `{BufWipeout,BufDelete,BufUnload}` (once) | `ColorMyAsciiFenceOpen_<tbuf>` | buffer-local | Cleans up temp file/extmarks/session state for `:Fence open` | **No** |
| `CursorMoved` | none (unusual — no augroup passed) | buffer-local to Telescope prompt | Live-applies the scheme under cursor to all managed buffers during `:ColorMyAscii schemes pick` | **No** |
| `BufDelete` | `ColorMyAsciiDebounce` | `*` | Cancels any pending debounce timer for the deleted buffer | **No** |

All augroups (except the `CursorMoved` scheme-preview one) use `clear = true`.

## Details

- **`FileType`/`ColorMyAscii`** is independent of the highlight enable state, so `:Fence` actions work even when highlighting is toggled off.
- **`ColorScheme`/`ColorMyAsciiFenceLineHl`** exists because colorschemes reset the highlight groups this plugin's fence-line/content colors depend on.
- **The `:Fence open` sync pair** implements ":w syncs back" — editing the extracted fence content in a scratch buffer and saving writes it back into the original fenced block in the source buffer.
- **The Telescope preview `CursorMoved` autocmd** has no explicit cleanup — it relies on Telescope wiping the prompt buffer itself when the picker closes (buffer-scoped, no `once`, no augroup — a style outlier vs. the rest of this codebase).
- Not an autocmd, but related: `cache_manager.lua`'s `setup_auto_cleanup(interval)` uses a libuv timer, not an autocmd.
