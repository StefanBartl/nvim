# language.nvim — Autocmds Cheatsheet

Sources: `lua/language/bindings/autocmds/init.lua`, `lua/language/translate/window.lua`, `lua/language/spell/providers/cspell_server.lua`
Cross-reference: `docs/BINDINGS.md` — matches `bindings/autocmds/init.lua`'s table exactly; doesn't mention the translate-window's own augroup or the cspell-sidecar shutdown autocmd (internal plumbing).

## `bindings/autocmds/init.lua` — augroup `language_nvim` (clear=true)

| Event(s) | Condition | Action | desc |
| --- | --- | --- | --- |
| `BufDelete` | always | GC per-buffer spell-session state + detach live diagnostics | "[language] GC spell state / detach live diagnostics" |
| `BufWinEnter`, `FileType` | `spell.live == true` | Scheduled initial live spell scan of the buffer | "[language] Live spell scan on enter" |
| `TextChanged`, `InsertLeave` | `spell.live == true` | Debounced live rescan on edits | "[language] Debounced live spell scan on change" |
| `WinScrolled` | `spell.live == true` AND `spell.live_scope == "visible"` | Rescans as the viewport moves | "[language] Live spell rescan on scroll (visible scope)" |
| `BufWritePre` | `spell.guard.block_write_on_error == true` (default **off**) | Scans buffer; if issues remain, aborts the write | "[language] block write on spelling errors" — grammar is advisory and never blocks; bypass via `:noautocmd w` |

## `translate/window.lua` — augroup `language_translate_window` (clear=true, recreated each time the window opens)

| Event(s) | Action | desc |
| --- | --- | --- |
| `TextChanged`, `TextChangedI` (input buf) | Debounced re-translate | "[language] live translate on input change" |
| `WinClosed` | If the closed window is the input window, tears down both floats | "[language] close translate window" |

## `spell/providers/cspell_server.lua` — no augroup, module-level (runs once when this provider is `require`d)

| Event | Action | desc |
| --- | --- | --- |
| `VimLeavePre` | `pcall(fn.jobstop, state.jid)` — kills the cspell CLI sidecar job if running | "[language] stop cspell sidecar" |
