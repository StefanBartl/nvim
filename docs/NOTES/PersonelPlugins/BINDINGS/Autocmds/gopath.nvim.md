# gopath.nvim — Autocmds Cheatsheet

Source: `lua/gopath/bindings/autocmds.lua`
Cross-reference: `docs/BINDINGS.md` — verified current and precise, no gaps found.

| Event | Augroup (clear) | Pattern | Condition | Action |
| --- | --- | --- | --- | --- |
| `BufWritePost` | `GopathPathCacheInvalidate` | — | always on | Drop `gopath.util.path`'s directory-listing caches (a write is the common way a new file appears mid-session) |
| `BufWritePost` | `GopathCacheAutoRebuild` | `config.truncated.watch_patterns` (default `{"*.lua","*.vim"}`) | `config.truncated.enable == true` AND `config.truncated.auto_rebuild_on_save == true` (latter defaults to **off**) | 1000ms-deferred, then debounced (at most once per 5 minutes) rebuild of the truncated-path filesystem cache |

Two autocmds total (both `BufWritePost`, both registered via
`lib.nvim.autocmd`) — this is the **only** autocmd or keymap registration
anywhere in gopath.nvim outside `bindings/keymaps.lua`/`bindings/autocmds.lua`
— confirmed by repo-wide grep. Kept as its own module (rather than inline in
`gopath.truncated.cache`'s setup) specifically so `docs/BINDINGS.md` has one
stable file to point at for every autocommand gopath registers.
