# github_stats.nvim — Autocmds Cheatsheet

Source: `lua/github_stats/bindings/autocmds.lua`, `lua/github_stats/dashboard/init.lua`
Cross-reference: `docs/BINDINGS.md` — verified current and precise.

| Event | Augroup (clear) | Action |
| --- | --- | --- |
| `VimEnter` | `GithubStatsAutoFetch` | Starts the silent background fetch/discovery cycle (no-op if `background.enabled==false`); after a 1000ms defer, auto-opens the dashboard if `cfg.dashboard.enabled and cfg.dashboard.auto_open` |
| `BufWipeout` (buffer-scoped, once) | none | Runs `cleanup_dashboard()` — stops render timer, clears dashboard state/auto-refresh timer, closes window/deletes buffer |

## Known dead code (not a real registration — noted for accuracy)

`lua/github_stats/dashboard/layout.lua`'s `M.setup_resize_handler(state)`
defines a `VimResized` autocmd that would re-render the dashboard on resize —
but a repo-wide grep shows `setup_resize_handler`/`layout.create`/
`layout.destroy` are never called from anywhere else in the codebase. The
live dashboard flow (`dashboard/init.lua`) doesn't use `layout.lua` at all.
This autocmd never actually fires; `docs/BINDINGS.md` correctly omits it.
