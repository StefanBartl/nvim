# autocmds.terminals

Terminal-focused autocommands with per-feature flags and augroups:
normalizes terminal window options on open, optionally tweaks Kitty
padding/margin on startup/exit, and can auto-enter Insert mode in terminal
buffers. `require("autocmds.terminals").enable(cfg)` is the entry point.
