# autocmds.text

Text-focused autocommands with feature flags: safe trailing-whitespace and
blank-line trimming (cursor position preserved) and a "restore last cursor
position on reopen" autocmd. Each feature has its own augroup and toggles
independently via `require("autocmds.text").enable(cfg)`.
