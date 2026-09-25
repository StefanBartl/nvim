# bindings.autocmds.text

Text-focused autocommands with feature flags: safe trailing-whitespace and
blank-line trimming (cursor position preserved), a "restore last cursor
position on reopen" autocmd, and re-closing folds a save's own edits reopened.
Each feature has its own augroup and toggles independently via
`require("bindings.autocmds.text").enable(cfg)`.

- `trim_trailing` / `trim_blank` (`BufWritePre`): both run a buffer-wide
  `:substitute`, which — like any `:s` — leaves the cursor on the last line it
  changed. Both now restore the cursor's pre-write position afterwards
  (`preserve_cursor`, default on), clamped to the trimmed line's new length.
- `preserve_folds` (`BufWritePre`/`BufWritePost`): with `foldmethod=expr`
  (markdown.nvim's heading folds, Treesitter's, ...), the fold engine can
  recompute levels from scratch once anything in the buffer changes, dropping
  a manually-closed fold (e.g. a folded TOC heading) back open. This snapshots
  which ranges were closed right before the write and re-closes them after,
  per window showing the buffer — regardless of which BufWritePre hook (ours
  or a formatter's) caused the reopen.
