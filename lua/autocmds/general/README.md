# autocmds.general

Centralized, toggleable autocmd suite with safe defaults and idempotent
setup: Kitty padding/margin on `VimEnter`/`VimLeavePre`, cursorline
show/hide on focus and insert/leave, and "jump back to last cursor
position" on `BufReadPost` (filetype-excludable). Every feature is
independently enabled via `enable(cfg)`'s per-feature `enable` flag.
