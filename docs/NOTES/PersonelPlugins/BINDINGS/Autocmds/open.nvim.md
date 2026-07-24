# open.nvim — Autocmds Cheatsheet

**None.** No `nvim_create_autocmd`/`nvim_create_augroup`/autocmd-string
matches anywhere in `lua/open/` or `plugin/open.lua`. `plugin/open.lua`
only sets a `vim.g.loaded_open` load-guard variable (not an autocmd) — the
guard was `vim.g.loaded_open_nvim` before the module root dropped its
`_nvim` suffix (repo commit `b6b3a88`); still not an autocmd either way.

Corroborated by the repo's own `docs/ROADMAP/Zentral-Prinzipien.md`: *"open.nvim
creates no autocommands at all (confirmed via repo-wide grep — the only
`vim.g.loaded_open` guard in `plugin/open.lua` isn't an autocmd)."*

Cross-reference: `docs/BINDINGS.md`'s `## Autocmds` section says simply
"None" — matches source, safe to use as-is. None of the roadmap features
implemented later (custom_handlers, terminal handler, keymaps, brave/opera,
git scope, picker, filemanager.reveal, debug mode, context cache, telescope
integration — see `Usercmds/open.nvim.md`) added an autocmd either.
