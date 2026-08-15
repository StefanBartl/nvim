# autocmds.git

Orchestrates all Git-related autocommands, delegating to one submodule per
feature (blame-on-hold, commit-message filetype setup, gitsigns refresh).
Each submodule implements exactly one feature and exposes its own
`enable(cfg)`; `require("autocmds.git").enable(cfg)` is the single entry
point that wires them all up.
