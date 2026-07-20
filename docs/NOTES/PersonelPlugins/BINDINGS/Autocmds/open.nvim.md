# open.nvim — Autocmds Cheatsheet

**None.** No `nvim_create_autocmd`/`nvim_create_augroup`/autocmd-string
matches anywhere in `lua/open_nvim/` or `plugin/open.lua`. `plugin/open.lua`
only sets a `vim.g.loaded_open_nvim` load-guard variable (not an autocmd).

Corroborated by the repo's own `docs/ROADMAP/Zentral-Prinzipien.md`: *"open.nvim
creates no autocommands at all (confirmed via repo-wide grep — the only
`vim.g.loaded_open_nvim` guard in `plugin/open.lua` isn't an autocmd)."*

Cross-reference: `docs/BINDINGS.md`'s `## Autocmds` section says simply
"None" — matches source, safe to use as-is.
