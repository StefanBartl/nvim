# diff.nvim — Autocmds Cheatsheet

Source: `lua/diff/bindings/autocmds.lua`, `lua/diff/features/native_diffthis.lua`
Cross-reference: `docs/BINDINGS.md` — verified accurate and current.

| Event | Augroup (clear) | Pattern | Condition | Action |
| --- | --- | --- | --- | --- |
| `VimLeavePre` | `diff_cleanup` | none | unconditional | Wipes diff.nvim's own tracked scratch buffers on Neovim exit |
| `OptionSet` | `diff_native_diffthis` | `diff` | `cfg.exit.scope == "buffer"` AND `cfg.exit.native_diffthis == true` (default **off**) | On any `'diff'` window-option change, attaches/removes the buffer-local exit keymap depending on whether the window is now in diffmode |

## Details

- **`VimLeavePre`/`diff_cleanup`**: native diffmode teardown on exit is Neovim's own responsibility, not this plugin's — this autocmd only cleans up diff.nvim's own scratch buffers.
- **`OptionSet`/`diff_native_diffthis`**: mirrors the buffer-local exit key onto buffers a **native** `:diffthis`/`:diffoff!` puts into diffmode, not just diff.nvim's own diffs. Opt-in because it changes buffer-local keymaps outside diff.nvim's own workflow, which could surprise users invoking `:diffthis` directly for unrelated reasons.
