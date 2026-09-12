# autocmds.general

Centralized, toggleable autocmd suite with safe defaults and idempotent
setup: cursorline show/hide on focus and insert/leave, and the spurious
[No Name] buffer guard. Every feature is independently enabled via
`enable(cfg)`'s per-feature `enable` flag.

Kitty padding/margin and "jump back to last cursor position" used to live
here too — removed 2026-09-12, each was an exact duplicate of a feature
`autocmds.terminals` (kitty) and `autocmds.text` (last_loc) already owned.
See those modules instead.
