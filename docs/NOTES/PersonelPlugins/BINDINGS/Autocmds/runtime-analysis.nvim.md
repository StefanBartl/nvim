# runtime-analysis.nvim — Autocmds Cheatsheet

**None.** Confirmed by a repo-wide search for `nvim_create_autocmd`/
`nvim_create_augroup`/legacy `autocmd`/`augroup` vimscript — zero matches
under `lua/runtime-analysis/`. Nothing here watches buffer or window
events; every action (`:RARequest`, `:RASend`, `:RATelemetry`) is triggered
directly by a command.

Cross-reference: the repo's own `docs/BINDINGS.md` correctly states zero
autocmds.
