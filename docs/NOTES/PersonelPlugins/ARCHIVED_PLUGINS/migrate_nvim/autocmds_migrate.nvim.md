# migrate.nvim — Autocmds Cheatsheet

**None.** Confirmed by a repo-wide search for `nvim_create_autocmd`/
`nvim_create_augroup`/legacy `autocmd`/`augroup` vimscript — zero matches in
any `.lua` source file. migrate.nvim acts only on explicit
`:MigrateOpt`/`:MigrateNotify` invocations.

Cross-reference: `docs/BINDINGS.md` correctly states zero autocmds.
